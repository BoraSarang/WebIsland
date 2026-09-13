import Cocoa
import Combine
import SwiftUI

final class NotchWindowController {
    var notchWindow: NSWindow!
    var detachedWindow: NSWindow?
    var hostingView: NSHostingView<NotchRootView>?

    let viewModel = NotchViewModel()
    /// 단일 공유 탭 모델. 노치·분리·폴백이 같은 선택/탐색을 본다.
    /// (각 뷰가 TabManager를 따로 만들던 구조에서 분리모드 불일치 발생)
    let tabManager: TabManager!
    private var cancellables = Set<AnyCancellable>()

    private var mouseMonitor: Any?
    private var lastMouseCheck = CFAbsoluteTime(0)
    private var collapseWorkItem: DispatchWorkItem?

    @AppStorage("windowMode") var windowMode: WindowMode = .attached

    init() {
        DebugLogger.feature("NotchWindow", "컨트롤러 초기화")
        tabManager = MainActor.assumeIsolated { TabManager() }
        viewModel.windowMode = windowMode
        setupNotchWindow()
        if windowMode == .detached {
            setupDetachedWindow()
        }
        viewModel.$state
            .sink { [weak self] state in
                self?.layout(for: state, animated: true)
                if state == .expanded {
                    // 비활성 앱의 non-activating 패널은 클릭을 받지 못한다.
                    // 사용자 의도(탭·노치 클릭)로 확장될 때만 키 윈도우로 전환.
                    DispatchQueue.main.async { [weak self] in
                        self?.focusPanel()
                    }
                }
            }
            .store(in: &cancellables)
        // 설정 화면에서 모드 변경 시 실시간 전환.
        NotificationCenter.default.addObserver(
            forName: .wiWindowModeChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.windowMode = self.storedWindowMode()
            self.switchMode(to: self.windowMode)
        }
        setupMouseTracking()
    }

    private func storedWindowMode() -> WindowMode {
        WindowMode(rawValue: UserDefaults.standard.string(forKey: "windowMode") ?? "") ?? .attached
    }

    deinit {
        mouseMonitor.map(NSEvent.removeMonitor)
        collapseWorkItem?.cancel()
    }

    // MARK: - 상태별 윈도우 프레임 (순수 함수 — 단위 테스트 대상)

    static let pillHeight: CGFloat = 40
    static let panelHeight: CGFloat = 480

    static func frame(
        for state: NotchViewModel.State,
        midX: CGFloat,
        topY: CGFloat,
        windowMode: WindowMode,
        notchWidth: CGFloat = 220
    ) -> NSRect {
        let idleW = notchWidth + 72
        let expandedW = max(420, notchWidth + 220)
        switch state {
        case .idle:
            return NSRect(x: midX - idleW / 2, y: topY - pillHeight, width: idleW, height: pillHeight)
        case .hovered:
            return NSRect(x: midX - expandedW / 2, y: topY - pillHeight, width: expandedW, height: pillHeight)
        case .expanded:
            if windowMode == .attached {
                let height = pillHeight + panelHeight
                return NSRect(x: midX - expandedW / 2, y: topY - height, width: expandedW, height: height)
            }
            return NSRect(x: midX - expandedW / 2, y: topY - pillHeight, width: expandedW, height: pillHeight)
        }
    }

    func layout(for state: NotchViewModel.State, animated: Bool) {
        guard let screen = NSScreen.main else { return }
        if let notch = screen.notchRect {
            viewModel.notchWidth = notch.width
        }
        let midX = screen.notchRect?.midX ?? screen.frame.midX
        let rect = Self.frame(
            for: state,
            midX: midX,
            topY: screen.frame.maxY,
            windowMode: windowMode,
            notchWidth: viewModel.notchWidth
        )
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.35
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                notchWindow.animator().setFrame(rect, display: true)
            }
        } else {
            notchWindow.setFrame(rect, display: true)
        }
    }

    func setupNotchWindow() {
        let screen = NSScreen.main!
        if let notch = screen.notchRect {
            viewModel.notchWidth = notch.width
        }
        let idleRect = Self.frame(
            for: .idle,
            midX: screen.notchRect?.midX ?? screen.frame.midX,
            topY: screen.frame.maxY,
            windowMode: windowMode,
            notchWidth: viewModel.notchWidth
        )

        notchWindow = PanelWindow(
            contentRect: idleRect,
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

        let rootView = NotchRootView(
            onModeChange: { [weak self] mode in
                self?.switchMode(to: mode)
            },
            viewModel: viewModel,
            tabManager: tabManager
        )
        hostingView = NSHostingView(rootView: rootView)
        // NSHostingView 기본값은 윈도우를 콘텐츠 크기에 자동 맞춤.
        // 오버레이는 수동 크기이므로 자동 맞춤 해제.
        hostingView?.sizingOptions = []
        hostingView?.frame = NSRect(origin: .zero, size: idleRect.size)
        hostingView?.autoresizingMask = [.width, .height]
        notchWindow.contentView = hostingView
        notchWindow.setFrame(idleRect, display: false)
    }

    func setupDetachedWindow() {
        // 중복 생성 방지: 이미 있으면 앞으로만 내보낸다.
        // (모드 전환 반복 시 플로팅 창이 쌓이던 버그 수정)
        if detachedWindow != nil {
            detachedWindow?.orderFrontRegardless()
            return
        }
        let savedFrame = UserDefaults.standard.string(forKey: "detachedFrame")
            .flatMap { NSRectFromString($0) }
            ?? NSRect(x: 500, y: 500, width: 400, height: 500)

        detachedWindow = PanelWindow(
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
        let detachedHosting = NSHostingView(rootView: DetachedBrowserView(tabManager: tabManager))
        detachedHosting.sizingOptions = []
        detachedHosting.frame = NSRect(origin: .zero, size: savedFrame.size)
        detachedHosting.autoresizingMask = [.width, .height]
        detachedWindow?.contentView = detachedHosting
        detachedWindow?.setFrame(savedFrame, display: false)
        detachedWindow?.orderFrontRegardless()

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
        removeMouseMonitor()
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMoved(event)
        }
    }

    /// 손쉬운 사용 권한이 나중에 허용된 뒤 호버 감지를 재장착한다.
    func refreshMouseTracking() {
        DebugLogger.feature("MouseTracking", "모니터 재장착 (권한 허용 후)")
        setupMouseTracking()
    }

    private func removeMouseMonitor() {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
    }

    /// 확장 상태에서 패널이 클릭·키 입력을 받도록 앱 활성화 + 키 윈도우 지정.
    /// `.nonactivatingPanel`은 클릭 시 자동으로 키가 되지 않아 ESC 전까지
    /// 무반응처럼 보이는 문제를 해결한다.
    /// 분리모드에서는 플로팅 창을 키로 만든다 (노치가 아닌 실제 상호작용 창).
    private func focusPanel() {
        NSApp.activate(ignoringOtherApps: true)
        if windowMode == .detached, let detached = detachedWindow {
            detached.makeKeyAndOrderFront(nil)
            DebugLogger.feature("Panel", "포커스: detached (active=\(NSApp.isActive))")
        } else if let notch = notchWindow {
            notch.makeKeyAndOrderFront(nil)
            DebugLogger.feature("Panel", "포커스: notch (active=\(NSApp.isActive))")
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
            if viewModel.state == .idle {
                // 렌더 패스 재진입 방지: 상태 변경은 다음 런루프에.
                DispatchQueue.main.async { [weak self] in
                    self?.viewModel.state = .hovered
                }
            }
        } else if let panelFrame = notchWindow?.frame, !panelFrame.contains(mouse) {
            scheduleCollapse()
        }
    }

    private func scheduleCollapse() {
        collapseWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.viewModel.state != .expanded {
                self.viewModel.state = .idle
            }
        }
        collapseWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: item)
    }

    /// 메뉴바 클릭·단축키: 패널 열고 닫기.
    func toggle() {
        notchWindow.orderFrontRegardless()
        if windowMode == .detached {
            setupDetachedWindow()
        }
        if viewModel.state == .expanded {
            viewModel.state = .hovered
        } else {
            DebugLogger.feature("Panel", "패널 열기")
            viewModel.state = .expanded
        }
    }

    func show() {
        notchWindow.orderFrontRegardless()
        if windowMode == .detached {
            detachedWindow?.orderFrontRegardless()
        }
    }

    func switchMode(to mode: WindowMode) {
        DebugLogger.feature("WindowMode", "모드 전환: \(mode.rawValue)")
        windowMode = mode
        viewModel.windowMode = mode
        if mode == .detached {
            setupDetachedWindow()
            detachedWindow?.orderFrontRegardless()
        } else {
            detachedWindow?.orderOut(nil)
        }
        layout(for: viewModel.state, animated: true)
    }
}
