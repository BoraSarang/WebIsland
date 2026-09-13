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
    /// 아바타 폴백만 들어있는 호스트. 실제 아이콘 도착 시 교체 우선.
    private var fallbackHosts = Set<String>()

    private var diskDir: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WebIsland/\(Self.diskCacheVersion)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func diskURL(for host: String) -> URL {
        let safe = host.replacingOccurrences(of: "[^a-zA-Z0-9.-]", with: "_", options: .regularExpression)
        return diskDir.appendingPathComponent(safe + ".png")
    }

    func fetchFavicon(for url: URL) async -> NSImage? {
        let host = url.host ?? ""
        guard !host.isEmpty else { return nil }

        if let cached = memoryCache.object(forKey: host as NSString) {
            DebugLogger.cache(hit: true, "파비콘 메모리: \(host)")
            return cached
        }
        if let disk = loadDisk(for: host) {
            DebugLogger.cache(hit: true, "파비콘 디스크: \(host)")
            memoryCache.setObject(disk, forKey: host as NSString)
            return disk
        }
        DebugLogger.cache(hit: false, "파비콘: \(host)")

        // 2) /favicon.ico
        if let icon = await download(from: URL(string: "\(url.scheme ?? "https")://\(host)/favicon.ico")) {
            store(icon, for: host)
            return icon
        }
        // 3) Google faviconV2 직접 호출 (구 S2는 리다이렉트 폴백이라 품질 불안정)
        let v2 = "https://t0.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON"
            + "&fallback_opts=TYPE,SIZE,URL&url=https://\(host)&size=64"
        if let icon = await download(from: URL(string: v2)) {
            store(icon, for: host)
            return icon
        }
        // 4) 첫글자 아바타 폴백 (메모리만 저장, 디스크 오염 방지)
        DebugLogger.error(code: "E-MAC-NET-0001", "파비콘 없음, 아바타 폴백: \(host)")
        let fallback = AvatarGenerator.generate(for: host)
        memoryCache.setObject(fallback, forKey: host as NSString)
        fallbackHosts.insert(host)
        return fallback
    }

    /// JS 1단계: 페이지의 link[rel*=icon] href를 직접 다운로드해
    /// 페이지 호스트 키로 저장한다. 저장 후 `wiFaviconDidUpdate`를 발행해
    /// 같은 호스트를 표시 중인 다른 탭 뷰도 갱신되도록 한다.
    @discardableResult
    func fetchIconHREF(_ href: String, pageHost: String) async -> NSImage? {
        guard !pageHost.isEmpty, let iconURL = URL(string: href) else { return nil }
        let hasRealIcon = memoryCache.object(forKey: pageHost as NSString) != nil
            && !fallbackHosts.contains(pageHost)
        if let cached = memoryCache.object(forKey: pageHost as NSString), hasRealIcon {
            DebugLogger.cache(hit: true, "파비콘 메모리(JS): \(pageHost)")
            return cached
        }
        guard let icon = await download(from: iconURL) else { return nil }
        store(icon, for: pageHost)
        NotificationCenter.default.post(
            name: .wiFaviconDidUpdate,
            object: nil,
            userInfo: ["host": pageHost]
        )
        return icon
    }

    func avatar(for host: String) -> NSImage {
        AvatarGenerator.generate(for: host)
    }

    // MARK: - Private

    private func download(from url: URL?) async -> NSImage? {
        guard let url else { return nil }
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let img = Self.decodeImage(data)
        else { return nil }
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

    private func store(_ image: NSImage, for host: String) {
        memoryCache.setObject(image, forKey: host as NSString)
        fallbackHosts.remove(host)
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:])
        else { return }
        try? png.write(to: diskURL(for: host))
    }

    private func loadDisk(for host: String) -> NSImage? {
        let file = diskURL(for: host)
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: file.path),
              let mtime = attrs[.modificationDate] as? Date,
              Date().timeIntervalSince(mtime) < diskTTL,
              let img = NSImage(contentsOf: file)
        else { return nil }
        return img
    }
}
