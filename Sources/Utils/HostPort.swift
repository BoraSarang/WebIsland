import Foundation

/// 호스트:포트 표시 규칙 단일 진실 (기본 포트 443/80 생략).
/// `WebTab.portBadge`·`ToolbarView.displayHostPort`·`FaviconService.cacheKey`의
/// 복붙 분기를 여기로 통합. 순수 함수라 단위 테스트 대상.
enum HostPort {
    /// 비기본 포트만 ":포트"로, 기본·없음은 nil.
    static func badge(port: Int?, scheme: String?) -> String? {
        guard let port else { return nil }
        switch scheme?.lowercased() {
        case "https" where port == 443: return nil
        case "http" where port == 80: return nil
        default: return ":\(port)"
        }
    }

    /// 캐시 키: 호스트 + 비기본 포트. 호스트 없으면 "".
    static func cacheKey(host: String?, port: Int?, scheme: String?) -> String {
        guard let host else { return "" }
        guard let badge = badge(port: port, scheme: scheme) else { return host }
        return host + badge
    }

    /// 표시용: "호스트:포트" 또는 폴백(전체 URL 등).
    static func display(host: String?, port: Int?, scheme: String?, fallback: String) -> String {
        guard let host else { return fallback }
        guard let badge = badge(port: port, scheme: scheme) else { return host }
        return host + badge
    }
}
