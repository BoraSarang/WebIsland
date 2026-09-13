import Cocoa
import Foundation
import ImageIO

/// 파비콘 4단계: 1) JS link[rel*=icon] 2) /favicon.ico 3) Google S2 4) 첫글자 아바타.
/// 메모리 NSCache + 디스크 캐시 (TTL 7일).
/// 폴백 아바타는 디스크에 저장하지 않는다 (일시적 실패가 7일간 실제 아이콘을
/// 가리는 오염 방지). 디렉토리 버전(v2)으로 구 오염 캐시를 무효화한다.
actor FaviconService {
    static let shared = FaviconService()

    /// 디스크 캐시 버전. 오염된 구 캐시를 버릴 때 올린다.
    static let diskCacheVersion = "favicons-v2"

    private var memoryCache = NSCache<NSString, NSImage>()
    private let diskTTL: TimeInterval = 7 * 24 * 3600
    /// 아바타 폴백만 들어있는 캐시 키. 실제 아이콘 도착 시 교체 우선.
    private var fallbackHosts = Set<String>()

    /// 사설 IP 서버의 https 자체서명 인증서를 신뢰하는 파비콘 전용 세션.
    /// (URLSession.shared는 개발 서버 인증서를 검증 실패로 거부한다.)
    private let session = URLSession(
        configuration: .ephemeral,
        delegate: FaviconSessionDelegate(),
        delegateQueue: nil
    )

    private var diskDir: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let dir = base.appendingPathComponent("WebIsland/\(Self.diskCacheVersion)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func diskURL(for key: String) -> URL {
        let safe = key.replacingOccurrences(of: "[^a-zA-Z0-9.-]", with: "_", options: .regularExpression)
        return diskDir.appendingPathComponent(safe + ".png")
    }

    /// 포트별 파비콘 캐시 키 (기본 443/80은 호스트만). 규칙은 `HostPort` 단일 진실.
    static func cacheKey(for url: URL) -> String {
        HostPort.cacheKey(host: url.host, port: url.port, scheme: url.scheme)
    }

    func fetchFavicon(for url: URL) async -> NSImage? {
        let host = url.host ?? ""
        guard !host.isEmpty else { return nil }
        let key = Self.cacheKey(for: url)

        // 로컬(사설 IP·localhost) 서버는 파비콘이 자주 바뀌므로 캐시를 우회한다.
        // 디스크 TTL(7일) 캐시가 개발 서버의 최신 파비콘을 가리는 문제 방지.
        let isLocal = CertTrustService.isPrivateIP(host)
        if !isLocal, let cached = memoryCache.object(forKey: key as NSString) {
            DebugLogger.cache(hit: true, "파비콘 메모리: \(key)")
            return cached
        }
        if !isLocal, let disk = loadDisk(for: key) {
            DebugLogger.cache(hit: true, "파비콘 디스크: \(key)")
            memoryCache.setObject(disk, forKey: key as NSString)
            return disk
        }
        DebugLogger.cache(hit: false, "파비콘: \(key)")

        // 2) /favicon.ico — 호스트:포트 그대로 (사설 인증서는 세션에서 신뢰).
        let scheme = url.scheme ?? "https"
        let hostPort = key
        if let icon = await download(from: URL(string: "\(scheme)://\(hostPort)/favicon.ico")) {
            store(icon, for: key)
            return icon
        }
        // 3) 이미 받아둔 실제 아이콘 유지. 서버가 link[rel=icon] 방식이고
        //    favicon.ico가 없는 경우, 로컬 우회가 아바타로 다운그레이드하지
        //    않도록 실아이콘 디스크 캐시를 반환한다 (폴백 아바타는 제외).
        if !fallbackHosts.contains(key), let existing = loadDisk(for: key) {
            DebugLogger.cache(hit: true, "파비콘 기존 실제 아이콘 유지: \(key)")
            memoryCache.setObject(existing, forKey: key as NSString)
            return existing
        }
        // 4) Google faviconV2 직접 호출 (구 S2는 리다이렉트 폴백이라 품질 불안정)
        let faviconV2URL = "https://t0.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON"
            + "&fallback_opts=TYPE,SIZE,URL&url=https://\(key)&size=64"
        if let icon = await download(from: URL(string: faviconV2URL)) {
            store(icon, for: key)
            return icon
        }
        // 5) 첫글자 아바타 폴백 (메모리만 저장, 디스크 오염 방지)
        DebugLogger.error(code: "E-MAC-NET-0001", "파비콘 없음, 아바타 폴백: \(key)")
        let fallback = AvatarGenerator.generate(for: key)
        memoryCache.setObject(fallback, forKey: key as NSString)
        fallbackHosts.insert(key)
        return fallback
    }

    /// JS 1단계: 페이지의 link[rel*=icon] href를 직접 다운로드해
    /// 캐시 키(호스트:포트)로 저장한다. 저장 후 `wiFaviconDidUpdate`를 발행해
    /// 같은 탭 뷰도 갱신되도록 한다.
    @discardableResult
    func fetchIconHREF(_ href: String, pageKey: String) async -> NSImage? {
        guard !pageKey.isEmpty, let iconURL = URL(string: href) else { return nil }
        // 로컬 서버는 언제나 최신 파비콘을 반영한다 (메모리 실아이콘 캐시 우회).
        let host = iconURL.host ?? pageKey
        let isLocal = CertTrustService.isPrivateIP(host)
        let hasRealIcon = memoryCache.object(forKey: pageKey as NSString) != nil
            && !fallbackHosts.contains(pageKey)
        if !isLocal, let cached = memoryCache.object(forKey: pageKey as NSString), hasRealIcon {
            DebugLogger.cache(hit: true, "파비콘 메모리(JS): \(pageKey)")
            return cached
        }
        DebugLogger.feature(
            "FaviconService",
            "link[rel=icon] 수신: \(pageKey) ← \(iconURL.absoluteString.prefix(80))"
        )
        guard let icon = await download(from: iconURL) else {
            DebugLogger.info("link 파비콘 실패: \(pageKey)")
            return nil
        }
        DebugLogger.info("link 파비콘 적용: \(pageKey)")
        store(icon, for: pageKey)
        NotificationCenter.default.post(
            name: .wiFaviconDidUpdate,
            object: nil,
            userInfo: ["key": pageKey]
        )
        return icon
    }

    func avatar(for host: String) -> NSImage {
        AvatarGenerator.generate(for: host)
    }

    // MARK: - Private

    private func download(from url: URL?) async -> NSImage? {
        guard let url else { return nil }
        guard let (data, response) = try? await session.data(from: url) else {
            DebugLogger.info("파비콘 다운로드 실패(네트워크): \(url.absoluteString.prefix(80))")
            return nil
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard status == 200, let img = Self.decodeImage(data) else {
            DebugLogger.info("파비콘 무효 HTTP=\(status): \(url.absoluteString.prefix(80))")
            return nil
        }
        return img
    }

    /// 이미지 디코딩. `NSImage(data:)`는 ICO를 디코딩하지 못하므로
    /// 실패 시 ImageIO `CGImageSource` 최대 프레임으로 폴백한다.
    static func decodeImage(_ data: Data) -> NSImage? {
        if let img = NSImage(data: data) { return img }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        var bestFrame: CGImage?
        var bestPixels = 0
        for idx in 0 ..< count {
            guard let frame = CGImageSourceCreateImageAtIndex(source, idx, nil) else { continue }
            let pixels = frame.width * frame.height
            if pixels > bestPixels {
                bestPixels = pixels
                bestFrame = frame
            }
        }
        guard let selected = bestFrame else { return nil }
        return NSImage(
            cgImage: selected,
            size: NSSize(width: selected.width, height: selected.height)
        )
    }

    private func store(_ image: NSImage, for key: String) {
        memoryCache.setObject(image, forKey: key as NSString)
        fallbackHosts.remove(key)
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:])
        else { return }
        try? png.write(to: diskURL(for: key))
    }

    private func loadDisk(for key: String) -> NSImage? {
        let file = diskURL(for: key)
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: file.path),
              let mtime = attrs[.modificationDate] as? Date,
              Date().timeIntervalSince(mtime) < diskTTL,
              let img = NSImage(contentsOf: file)
        else { return nil }
        return img
    }
}

// MARK: - 사설 인증서 신뢰 URLSession delegate

/// 개발 서버의 https 자체서명 인증서를 신뢰해 파비콘/OG 이미지를 받아온다.
private final class FaviconSessionDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              CertTrustService.isPrivateIP(challenge.protectionSpace.host),
              let trust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
