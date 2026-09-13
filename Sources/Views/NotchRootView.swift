import Combine
import SwiftUI
import WebKit

struct NotchRootView: View {
    var onModeChange: (WindowMode) -> Void

    @ObservedObject var viewModel: NotchViewModel
    @StateObject private var tabManager = TabManager()

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
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(
            color: .black.opacity(state == .expanded ? 0 : 0.2),
            radius: 8,
            y: 4
        )
        .onTapGesture {
            DebugLogger.feature("NotchRoot", "노치 탭: \(state) → 토글")
            viewModel.state = (state == .expanded) ? .hovered : .expanded
        }
    }

    // MARK: - Browser Panel (400×480, gap 0)

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
                }
            )
            WebContainerView(webView: webView, url: tab.url, isNewTabPage: tab.isNewTabPage, tab: tab)
                .id(tab.id)
                .frame(width: 390)
        }
        .frame(width: 400, height: 480)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 20, y: 8)
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
            .help("\(tab.host) (⌘\(index + 1))")
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
        .task(id: tab.urlString) {
            if let img = await FaviconService.shared.fetchFavicon(for: tab.url) {
                icon = img
                tab.cachedFavicon = img
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .wiFaviconDidUpdate)) { note in
            guard tab.cachedFavicon == nil,
                  (note.userInfo?["host"] as? String) == tab.host
            else { return }
            Task { @MainActor in
                if let img = await FaviconService.shared.fetchFavicon(for: tab.url) {
                    icon = img
                    tab.cachedFavicon = img
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

    @State private var editing = false
    @State private var draft = ""
    @FocusState private var addressFocused: Bool

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
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text(url.host ?? url.absoluteString)
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
        }
        .padding(8)
        .frame(height: 36)
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
    @StateObject private var tabManager = TabManager()

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
                    }
                )
                WebContainerView(webView: webView, url: tab.url, isNewTabPage: tab.isNewTabPage, tab: tab)
                    .id(tab.id)
            }
        }
        .frame(width: 400, height: 500)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
