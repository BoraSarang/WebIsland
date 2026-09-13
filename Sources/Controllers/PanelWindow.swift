import Cocoa

/// 오버레이용 패널. `.nonactivatingPanel`은 NSPanel 전용 styleMask라
/// NSWindow 서브클래스에서는 AppKit이 거부해 창이 표시되지 않는다.
/// 텍스트 입력(옴니박스)·단축키를 위해 키 윈도우 허용.
final class PanelWindow: NSPanel {
    override var canBecomeKey: Bool { true }

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: style,
            backing: backingStoreType,
            defer: flag
        )
        // 비활성화 시 패널이 사라지지 않도록 (오버레이 상주).
        hidesOnDeactivate = false
    }

    /// ESC 기본 경로 보조: 주소창이 아닌 곳에서 ESC를 누르면 무조건 패널 닫기.
    /// 웹뷰가 포커스면 호출되지 않으므로 주수단은 localMonitor(keyDown모니터).
    override func cancelOperation(_ sender: Any?) {
        NotificationCenter.default.post(name: .wiDismissPanel, object: nil)
    }
}
