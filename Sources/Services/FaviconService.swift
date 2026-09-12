import Cocoa
import Foundation

/// 파비콘 4단계: 1) JS link[rel*=icon] 2) /favicon.ico 3) Google S2 4) 첫글자 아바타.
/// 메모리 NSCache + 디스크 캐시 (TTL 7일).
actor FaviconService {
    static let shared = FaviconService()

    private var memoryCache = NSCache<NSString, NSImage>()
    private let diskTTL: TimeInterval = 7 * 24 * 3600

    private var diskDir: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WebIsland/favicons", isDirectory: true)
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
        // 3) Google S2
        if let s2 = URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=64"),
           let icon = await download(from: s2)
        {
            store(icon, for: host)
            return icon
        }
        // 4) 첫글자 아바타 폴백
        DebugLogger.error(code: "E-MAC-NET-0001", "파비콘 없음, 아바타 폴백: \(host)")
        return nil
    }

    /// JS 1단계: 페이지의 link[rel*=icon] href를 직접 다운로드.
    func fetchIconHREF(_ href: String) async -> NSImage? {
        guard let iconURL = URL(string: href),
              let host = iconURL.host,
              !host.isEmpty
        else { return nil }
        if let cached = memoryCache.object(forKey: host as NSString) {
            DebugLogger.cache(hit: true, "파비콘 메모리(JS): \(host)")
            return cached
        }
        if let icon = await download(from: iconURL) {
            store(icon, for: host)
            return icon
        }
        return nil
    }

    func avatar(for host: String) -> NSImage {
        AvatarGenerator.generate(for: host)
    }

    // MARK: - Private

    private func download(from url: URL?) async -> NSImage? {
        guard let url else { return nil }
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let img = NSImage(data: data)
        else { return nil }
        return img
    }

    private func store(_ image: NSImage, for host: String) {
        memoryCache.setObject(image, forKey: host as NSString)
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
