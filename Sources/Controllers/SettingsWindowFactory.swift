import Cocoa
import SwiftUI

/// 설정 창 공장. 캐싱·표시는 AppDelegate가 담당, 생성만 여기로.
/// 닫기 후 over-release 댕글링 방지로 `isReleasedWhenClosed=false`.
enum SettingsWindowFactory {
    static func make() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = NSLocalizedString("menu.settings", comment: "")
        window.isReleasedWhenClosed = false
        // 일반 창보다 위에 뜨도록 floating 레벨.
        window.level = .floating
        let hosting = NSHostingView(rootView: SettingsView())
        hosting.sizingOptions = []
        window.contentView = hosting
        window.setFrame(NSRect(x: 0, y: 0, width: 480, height: 420), display: false)
        window.center()
        return window
    }
}
