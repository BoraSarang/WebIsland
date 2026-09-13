import Cocoa
import SwiftUI

/// 노치·분리 윈도우 생성 공장 (NotchWindowController type_body 분리의 윈도우 담당).
/// Controller는 만든 윈도우 보유 + 상태 전환만 한다.
enum NotchWindowFactory {
    static let detachedFrameKey = "detachedFrame"

    /// 노치 패널 윈도우 생성 (투명 borderless + 루트뷰 배선).
    static func makeNotchWindow(
        idleRect: NSRect,
        viewModel: NotchViewModel,
        tabManager: TabManager
    ) -> (window: PanelWindow, hosting: NSHostingView<NotchRootView>) {
        let window = PanelWindow(
            contentRect: idleRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver // above menu bar
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.isMovable = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hosting = HostingViewFactory.make(
            rootView: NotchRootView(viewModel: viewModel, tabManager: tabManager),
            size: idleRect.size
        )
        window.contentView = hosting
        window.setFrame(idleRect, display: false)
        return (window, hosting)
    }

    /// 분리 플로팅 윈도우 생성 (저장 프레임 복원 + 최소 크기 강제 + 이동 저장).
    static func makeDetachedWindow(tabManager: TabManager) -> PanelWindow {
        let screen = NSScreen.main?.visibleFrame
        let saved = UserDefaults.standard.string(forKey: detachedFrameKey)
        let frame = detachedFrame(saved: saved, screen: screen)

        let window = PanelWindow(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.contentView = HostingViewFactory.make(
            rootView: DetachedBrowserView(tabManager: tabManager),
            size: frame.size
        )
        window.setFrame(frame, display: false)

        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { _ in
            UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: detachedFrameKey)
        }
        return window
    }

    /// 저장된 분리 프레임 복원 + clamp (순수 함수, 단위 테스트 대상).
    /// 옛 400×500 기준 저장값 대비 최소 크기 강제 + 화면 밖 방지.
    static func detachedFrame(saved: String?, screen: NSRect?) -> NSRect {
        var frame = saved.flatMap { NSRectFromString($0) }
            ?? NSRect(x: 500, y: 500, width: NotchMetrics.detachedWidth, height: NotchMetrics.panelHeight)
        if frame.width < NotchMetrics.detachedWidth { frame.size.width = NotchMetrics.detachedWidth }
        if frame.height < NotchMetrics.panelHeight { frame.size.height = NotchMetrics.panelHeight }
        if let screen {
            if frame.maxY > screen.maxY { frame.origin.y = screen.maxY - frame.height }
            if frame.minY < screen.minY { frame.origin.y = screen.minY }
        }
        return frame
    }
}
