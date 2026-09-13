import Foundation

/// UserDefaults 설정 키 단일 진실 (매직스트링 흩어짐 방지).
/// @AppStorage·직접 조회 모두 이 상수를 쓴다.
enum AppSettingsKeys {
    static let showInDock = "showInDock"
    static let launchAtLogin = "launchAtLogin"
    static let windowMode = "windowMode"
    static let detachedFrame = "detachedFrame"
}
