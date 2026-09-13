import Foundation

extension Notification.Name {
    /// 설정 화면에서 윈도우 모드 변경 시.
    static let wiWindowModeChanged = Notification.Name("WIWindowModeChanged")
    /// 파비콘이 페이지 호스트 키로 저장됐을 때. userInfo["host"].
    /// 같은 호스트를 표시 중인 다른 탭 뷰의 갱신용.
    static let wiFaviconDidUpdate = Notification.Name("WIFaviconDidUpdate")
}
