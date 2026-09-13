import Combine
import SwiftUI

/// 앱 시작 온보딩(랜딩) 창. 손쉬운 사용 권한을 안내하고 시스템 설정으로 유도.
/// 권한이 이미 허용된 경우 창 없이 즉시 종료된다.
final class OnboardingWindowController {
    var window: NSWindow?
    var onFinished: (() -> Void)?

    private var cancellables = Set<AnyCancellable>()

    /// 권한이 미허용일 때만 창을 표시하고, 허용돼 있으면 표시하지 않는다.
    /// 키 윈도우 상태를 유지하기 위해 부모 앱을 activate한다.
    func showIfNeeded() {
        guard !AccessibilityService.isTrusted else { return }
        DebugLogger.feature("Onboarding", "손쉬운 사용 권한 안내 표시")
        show()
    }

    func show() {
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 400),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = NSLocalizedString("onboarding.title", comment: "")
            window.isReleasedWhenClosed = false
            let hosting = NSHostingView(rootView: OnboardingView(onFinish: { [weak self] in
                self?.finish()
            }))
            hosting.sizingOptions = []
            hosting.frame = NSRect(x: 0, y: 0, width: 480, height: 400)
            hosting.autoresizingMask = [.width, .height]
            window.contentView = hosting
            window.center()
            self.window = window
        }
        window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        window?.orderOut(nil)
    }

    private func finish() {
        DebugLogger.feature("Onboarding", "완료")
        close()
        onFinished?()
    }
}
