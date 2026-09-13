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

    var url: URL { URL(string: urlString)! }
    var host: String { url.host ?? urlString }
    var firstLetter: String { String(host.prefix(1)).uppercased() }

    /// 탭 버튼용 포트 배지 (기본 포트 443/80 생략). 동일 호스트 탭 구분용.
    var portBadge: String? {
        guard let port = url.port else { return nil }
        let scheme = url.scheme?.lowercased()
        if (scheme == "https" && port == 443) || (scheme == "http" && port == 80) {
            return nil
        }
        return ":\(port)"
    }

    /// 새 탭 안내 페이지 (스키마 변경 없는 transient 판별).
    var isNewTabPage: Bool { urlString == "about:blank" }
}

enum WindowMode: String, Codable, CaseIterable {
    case attached
    case detached
}
