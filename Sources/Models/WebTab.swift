import AppKit
import Foundation
import SwiftData

@Model
final class WebTab: Identifiable {
    @Attribute(.unique) var id: UUID
    var urlString: String
    var customTitle: String?
    var order: Int
    var isPinned: Bool
    var faviconURLString: String?
    var createdAt: Date
    /// 표시용 파비콘 (영속 제외). 로드 완료 시 Coordinator가 세팅하면
    /// @Observable 경유로 표시 중인 뷰가 즉시 갱신된다.
    @Transient var cachedFavicon: NSImage?

    init(url: URL, order: Int) {
        self.id = UUID()
        self.urlString = url.absoluteString
        self.order = order
        self.isPinned = false
        self.createdAt = Date()
    }

    var url: URL { URL(string: urlString) ?? Self.fallbackURL }
    /// 손상된 영속값 방어용 (loadTabs에서 선제 제거, 여기는 최후 보루).
    static let fallbackURL = URL(string: "about:blank")!
    var host: String { url.host ?? urlString }
    var firstLetter: String { String(host.prefix(1)).uppercased() }

    /// 탭 버튼용 포트 배지 (기본 포트 443/80 생략). 동일 호스트 탭 구분용.
    var portBadge: String? {
        HostPort.badge(port: url.port, scheme: url.scheme)
    }

    /// 파비콘 캐시 키 (포트별 격리). 동일 호스트의 다른 포트 탭이
    /// 서로의 파비콘을 덮어쓰지 않도록 호스트:포트로 구분한다.
    var faviconKey: String {
        HostPort.cacheKey(host: host, port: url.port, scheme: url.scheme)
    }

    /// 새 탭 안내 페이지 (스키마 변경 없는 transient 판별).
    var isNewTabPage: Bool { urlString == "about:blank" }
}

enum WindowMode: String, Codable, CaseIterable {
    case attached
    case detached
}
