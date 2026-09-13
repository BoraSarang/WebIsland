import Combine
import SwiftUI
import WebKit

struct NotchRootView: View {
    var onModeChange: (WindowMode) -> Void

    @ObservedObject var viewModel: NotchViewModel
    @ObservedObject var tabManager: TabManager

    var state: NotchViewModel.State { viewModel.state }

    var body: some View {
        VStack(spacing: 0) {
            notchPill
            if state == .expanded && viewModel.windowMode == .attached,
               let tab = tabManager.activeTab
            {
                browserPanel(for: tab)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        // 단일 실루엣: 노치에서 자라난 하나의 덩어리 (단일 배경·클립·그림자).
        // 개별 pill/패널의 둥근 이음매·따로 노는 그림자가 "밑에 올려둔 창"처럼 보이던 원인.
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 20, y: 8)
        // 검정 융합 위 크롬(툴바·트레이)은 항상 다크 취급 (라이트 모드 검정 위 검정 방지).
        // WKWebView 렌더링에는 영향 없음 (SwiftUI 환경값만).
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: state)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: tabManager.activeTabID)
        .onHover { hovering in
            guard state != .expanded else { return }
            // 렌더 패스 중 상태 변경 시 AttributeGraph 재진입 크래시.
            // 다음 런루프로 미뤄 안전하게 반영.
            DispatchQueue.main.async {
                viewModel.state = hovering ? .hovered : .idle
            }
        }
        .onExitCommand {
            NotificationCenter.default.post(name: .wiDismissPanel, object: nil)
        }
    }

    // MARK: - Notch Pill (노치 실측 기준, 중앙은 비움)

    var notchPill: some View {
        HStack(spacing: 8) {
            if state == .idle {
                // 노치 전체가 가려지므로 지시자는 좌측 가시 영역에 배치.
                if let tab = tabManager.activeTab {
                    FaviconView(tab: tab, isActive: true)
                } else {
                    Circle().fill(Color.white.opacity(0.8)).frame(width: 8, height: 8)
                }
                Spacer()
            } else {
                TabStripView(
                    tabs: tabManager.tabs,
                    activeID: tabManager.activeTabID,
                    gapWidth: viewModel.centerGap,
                    onSelect: {
                        DebugLogger.feature("NotchRoot", "탭 제스처 수신: \($0.urlString)")
                        tabManager.selectTab($0)
                        viewModel.state = .expanded
                    },
                    onClose: { tabManager.closeTab($0) },
                    onTogglePin: { tabManager.togglePin($0) },
                    onAdd: { tabManager.addTab() }
                )
            }
        }
        // 가시 영역 36pt 한가운데에 오도록 leading 6 (아이콘 24).
        .padding(.horizontal, state == .idle ? 6 : 16)
        .frame(
            width: state == .idle ? viewModel.idleWidth : viewModel.expandedWidth,
            height: 40
        )
        // 외곽 모양·그림자는 바깥 단일 컨테이너가 담당 (이음매 무단차).
        // pill은 위만 둥글게(컨테이너 클립에 맡김) 아래는 패널과 직선으로 만남.
        .background(Color.black)
        .onTapGesture {
            DebugLogger.feature("NotchRoot", "노치 탭: \(state) → 토글")
            viewModel.state = (state == .expanded) ? .hovered : .expanded
        }
    }

    // MARK: - Browser Panel (창 가득 × 844, 블랙 융합)

    func browserPanel(for tab: WebTab) -> some View {
        let webView = tabManager.webView(for: tab)
        return VStack(spacing: 0) {
            WebProgressBar(webView: webView)
            ToolbarView(
                webView: webView,
                url: tab.url,
                isNewTabPage: tab.isNewTabPage,
                onNavigate: { tabManager.navigateActive(to: $0) },
                onAddTab: { tabManager.addTab() },
                onOpenSettings: {
                    (NSApp.delegate as? AppDelegate)?.openSettings()
                },
                onDismiss: {
                    (NSApp.delegate as? AppDelegate)?.notchWindowController?.dismissPanel()
                }
            )
            DownloadTrayView()
            WebContainerView(
                webView: webView,
                url: tab.url,
                isNewTabPage: tab.isNewTabPage,
                tab: tab,
                onURLDidChange: { tabManager.syncURL(tab, $0) }
            )
                .id(tab.id)
                .frame(width: viewModel.expandedWidth - 10)
        }
        .frame(width: viewModel.expandedWidth, height: 844)
        .background(Color.black)
    }
}

// MARK: - Tab Strip (물리 노치 중앙 비움, 좌우 분할)

struct TabStripView: View {
    var tabs: [WebTab]
    var activeID: WebTab.ID?
    var gapWidth: CGFloat
    var onSelect: (WebTab) -> Void
    var onClose: (WebTab) -> Void
    var onTogglePin: (WebTab) -> Void
    var onAdd: () -> Void

    private var leftTabs: [WebTab] {
        Array(tabs.prefix((tabs.count + 1) / 2))
    }

    private var rightTabs: [WebTab] {
        Array(tabs.dropFirst((tabs.count + 1) / 2))
    }

    var body: some View {
        HStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(Array(leftTabs.enumerated()), id: \.element.id) { index, tab in
                    tabButton(tab, index: index)
                }
            }
            Spacer()
                .frame(width: gapWidth)
            HStack(spacing: 4) {
                ForEach(Array(rightTabs.enumerated()), id: \.element.id) { offset, tab in
                    tabButton(tab, index: leftTabs.count + offset)
                }
            }
            Button("+") { onAdd() }
                .buttonStyle(.plain)
                .foregroundColor(.white)
                .keyboardShortcut("t", modifiers: .command)
                .help("\(NSLocalizedString("menu.newTab", comment: "")) (⌘T)")
        }
        .frame(height: 32)
    }

    @ViewBuilder
    private func tabButton(_ tab: WebTab, index: Int) -> some View {
        FaviconView(tab: tab, isActive: activeID == tab.id)
            // 부모 pill 토글보다 우선 (펼친 상태에서 탭 눌러도 닫히지 않음).
            .highPriorityGesture(
                TapGesture().onEnded { onSelect(tab) }
            )
            .contextMenu {
                Button(tab.isPinned
                    ? NSLocalizedString("tab.unpin", comment: "")
                    : NSLocalizedString("tab.pin", comment: "")) { onTogglePin(tab) }
                Button(NSLocalizedString("tab.close", comment: "")) { onClose(tab) }
            }
            .keyboardShortcut(
                KeyEquivalent(Character("\(index + 1)")),
                modifiers: .command
            )
            .help("\(tab.urlString) (⌘\(index + 1))")
    }
}

struct FaviconView: View {
    var tab: WebTab
    var isActive: Bool
    @State private var icon: NSImage?

    var body: some View {
        ZStack {
            if isActive {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 28, height: 28)
            }
            if let fav = tab.cachedFavicon {
                Image(nsImage: fav)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else if tab.isNewTabPage {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)
            } else {
                Text(tab.firstLetter)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)
            }
        }
        .frame(width: 24, height: 24)
        .overlay(alignment: .bottomTrailing) {
            if tab.isPinned, !tab.isNewTabPage {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
            }
        }
        .overlay(alignment: .bottomLeading) {
            // 동일 호스트 탭 구분용 포트 배지 (핀 표시와 겹치면 핀 우선).
            if let badge = tab.portBadge, !tab.isPinned, !tab.isNewTabPage {
                Text(badge)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    .offset(x: -5, y: 5)
            }
        }
        .task(id: tab.urlString) {
            DebugLogger.feature("FaviconView", "task: \(tab.host)")
            if let img = await FaviconService.shared.fetchFavicon(for: tab.url) {
                icon = img
                tab.cachedFavicon = img
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .wiFaviconDidUpdate)) { note in
            guard (note.userInfo?["key"] as? String) == tab.faviconKey else { return }
            // 로컬 서버는 기존 아이콘이 있어도 바뀐 파비콘을 다시 받아 반영.
            let isLocal = CertTrustService.isPrivateIP(tab.host)
            guard isLocal || tab.cachedFavicon == nil else { return }
            Task { @MainActor in
                if let img = await FaviconService.shared.fetchFavicon(for: tab.url) {
                    icon = img
                    tab.cachedFavicon = img
                    DebugLogger.feature("FaviconView", "notify 재fetch 적용: \(tab.host)")
                }
            }
        }
    }
}

// MARK: - Toolbar (뒤로/앞으로/새로고침 + 옴니박스 + 메뉴)

struct ToolbarView: View {
    var webView: WKWebView
    var url: URL
    var isNewTabPage: Bool
    var onNavigate: (String) -> Void
    var onAddTab: () -> Void
    var onOpenSettings: () -> Void
    var onDismiss: () -> Void

    @State private var editing = false
    @State private var draft = ""
    @State private var pageTitle = ""
    @FocusState private var addressFocused: Bool

    /// 호스트 + 비기본 포트 표시 (기본 80/443은 생략).
    private var displayHostPort: String {
        guard let host = url.host else { return url.absoluteString }
        guard let port = url.port else { return host }
        let scheme = url.scheme?.lowercased()
        if (scheme == "https" && port == 443) || (scheme == "http" && port == 80) {
            return host
        }
        return "\(host):\(port)"
    }

    var body: some View {
        HStack(spacing: 4) {
            Button { webView.goBack() } label: {
                Image(systemName: "chevron.left")
            }
            .keyboardShortcut("[", modifiers: .command)
            Button { webView.goForward() } label: {
                Image(systemName: "chevron.right")
            }
            .keyboardShortcut("]", modifiers: .command)
            Button { webView.reload() } label: {
                Image(systemName: "arrow.clockwise")
            }
            .keyboardShortcut("r", modifiers: .command)
            Spacer()
            if editing {
                TextField(
                    NSLocalizedString("omnibox.placeholder", comment: ""),
                    text: $draft,
                    onCommit: {
                        editing = false
                        onNavigate(draft)
                    }
                )
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
                .frame(width: 200)
                .focused($addressFocused)
            } else if isNewTabPage {
                Button {
                    draft = ""
                    editing = true
                } label: {
                    Text(NSLocalizedString("omnibox.newTabHint", comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    draft = url.absoluteString
                    editing = true
                } label: {
                    HStack(spacing: 4) {
                        if url.scheme?.lowercased() == "https" {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                        }
                        // 무슨 사이트인지 한눈에 알도록 제목 우선, 없으면 호스트.
                        Text(pageTitle.isEmpty ? displayHostPort : pageTitle)
                            .font(.system(size: 12))
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Menu {
                Button(NSLocalizedString("menu.newTab", comment: "")) { onAddTab() }
                Button(NSLocalizedString("menu.settings", comment: "")) { onOpenSettings() }
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 28)
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .help(NSLocalizedString("toolbar.close", comment: ""))
        }
        .padding(8)
        .frame(height: 36)
        .onReceive(webView.publisher(for: \.title)) { title in
            pageTitle = title ?? ""
        }
        .onAppear {
            // 새 탭은 주소 입력부터 시작.
            if isNewTabPage {
                draft = ""
                editing = true
                // 포커스는 다음 런루프에 (윈도우 키 전환 후).
                DispatchQueue.main.async {
                    addressFocused = true
                }
            }
        }
    }
}

struct DetachedBrowserView: View {
    @ObservedObject var tabManager: TabManager

    var body: some View {
        VStack(spacing: 0) {
            if let tab = tabManager.activeTab {
                let webView = tabManager.webView(for: tab)
                WebProgressBar(webView: webView)
                ToolbarView(
                    webView: webView,
                    url: tab.url,
                    isNewTabPage: tab.isNewTabPage,
                    onNavigate: { tabManager.navigateActive(to: $0) },
                    onAddTab: { tabManager.addTab() },
                    onOpenSettings: {
                        (NSApp.delegate as? AppDelegate)?.openSettings()
                    },
                    onDismiss: {
                        (NSApp.delegate as? AppDelegate)?.notchWindowController?.dismissPanel()
                    }
                )
                DownloadTrayView()
                WebContainerView(
                    webView: webView,
                    url: tab.url,
                    isNewTabPage: tab.isNewTabPage,
                    tab: tab,
                    onURLDidChange: { tabManager.syncURL(tab, $0) }
                )
                    .id(tab.id)
            }
        }
        .frame(width: 400, height: 844)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onExitCommand {
            NotificationCenter.default.post(name: .wiDismissPanel, object: nil)
        }
    }
}
