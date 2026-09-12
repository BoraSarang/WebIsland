import Cocoa
import SwiftUI

final class NotchWindowController {
    var notchWindow: NSWindow!
    var detachedWindow: NSWindow?
    var hostingView: NSHostingView<NotchRootView>?

    private var mouseMonitor: Any?
    private var lastMouseCheck = CFAbsoluteTime(0)
    private var collapseWorkItem: DispatchWorkItem?

    @AppStorage("windowMode") var windowMode: WindowMode = .attached

    init() {
        DebugLogger.feature("NotchWindow", "컨트롤러 초기화")
        setupNotchWindow()
        if windowMode == .detached {
            setupDetachedWindow()
        }
        setupMouseTracking()
    }

    deinit {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        collapseWorkItem?.cancel()
    }

    func setupNotchWindow() {
        let screen = NSScreen.main!
        let frame = screen.frame

        notchWindow = NSWindow(
            contentRect: NSRect(x: 0, y: frame.maxY - 32, width: frame.width, height: 600),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        notchWindow.level = .screenSaver // above menu bar
        notchWindow.backgroundColor = .clear
        notchWindow.isOpaque = false
        notchWindow.hasShadow = false
        notchWindow.isMovable = false
        notchWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let rootView = NotchRootView(windowMode: windowMode, onModeChange: { [weak self] mode in
            self?.switchMode(to: mode)
        })
        hostingView = NSHostingView(rootView: rootView)
        notchWindow.contentView = hostingView
    }

    func setupDetachedWindow() {
        let savedFrame = UserDefaults.standard.string(forKey: "detachedFrame")
            .flatMap { NSRectFromString($0) }
            ?? NSRect(x: 500, y: 500, width: 400, height: 500)

        detachedWindow = NSWindow(
            contentRect: savedFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        detachedWindow?.level = .floating
        detachedWindow?.backgroundColor = .clear
        detachedWindow?.isOpaque = false
        detachedWindow?.hasShadow = true
        detachedWindow?.isMovableByWindowBackground = true
        detachedWindow?.contentView = NSHostingView(rootView: DetachedBrowserView())

        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: detachedWindow,
            queue: .main
        ) { [weak self] _ in
            if let panelFrame = self?.detachedWindow?.frame {
                UserDefaults.standard.set(NSStringFromRect(panelFrame), forKey: "detachedFrame")
            }
        }
    }

    func setupMouseTracking() {
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(event)
        }
    }

    func handleMouseMoved(_ event: NSEvent) {
        // 60fps 스로틀
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastMouseCheck >= 1.0 / 60.0 else { return }
        lastMouseCheck = now

        guard let screen = NSScreen.main, let notchRect = screen.notchRect else { return }
        let mouse = NSEvent.mouseLocation

        if NotchDetector.isHover(mouse: mouse, notch: notchRect) {
            collapseWorkItem?.cancel()
            collapseWorkItem = nil
            expandNotch()
        } else if let panelFrame = notchWindow?.frame, !panelFrame.contains(mouse) {
            scheduleCollapse()
        }
    }

    private func scheduleCollapse() {
        collapseWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.collapseNotchIfNeeded()
        }
        collapseWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: item)
    }

    func expandNotch() { /* animate to 420px */ }
    func collapseNotchIfNeeded() { /* collapse if mouse not inside */ }
    func toggle() { notchWindow.orderFrontRegardless() }
    func show() { notchWindow.orderFrontRegardless() }

    func switchMode(to mode: WindowMode) {
        DebugLogger.feature("WindowMode", "모드 전환: \(mode.rawValue)")
        windowMode = mode
        if mode == .detached {
            setupDetachedWindow()
            detachedWindow?.orderFrontRegardless()
        } else {
            detachedWindow?.orderOut(nil)
        }
    }
}
