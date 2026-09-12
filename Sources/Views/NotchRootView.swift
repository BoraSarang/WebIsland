import SwiftUI
import WebKit

struct NotchRootView: View {
    var windowMode: WindowMode
    var onModeChange: (WindowMode) -> Void

    @StateObject private var tabManager = TabManager()
    @State private var state: NotchState = .idle

    enum NotchState { case idle, hovered, expanded }

    var body: some View {
        VStack(spacing: 0) {
            notchPill
            if state == .expanded && windowMode == .attached,
               let tab = tabManager.activeTab
            {
                browserPanel(for: tab)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: state)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: tabManager.activeTabID)
        .onHover { hovering in
            if hovering {
                state = state == .expanded ? .expanded : .hovered
            } else if state != .expanded {
                state = .idle
            }
        }
        .onTapGesture {
            DebugLogger.feature("NotchRoot", "노치 탭: \(state) → 토글")
            state = (state == .expanded) ? .hovered : .expanded
        }
    }

    // MARK: - Notch Pill (180→420×40)

    var notchPill: some View {
        HStack(spacing: 8) {
            if state == .idle {
                if let tab = tabManager.activeTab {
                    FaviconView(tab: tab, isActive: true)
                } else {
                    Circle().fill(Color.white.opacity(0.8)).frame(width: 8, height: 8)
                }
            } else {
                TabStripView(
                    tabs: tabManager.tabs,
                    activeID: tabManager.activeTabID,
                    onSelect: { tabManager.selectTab($0) },
                    onClose: { tabManager.closeTab($0) },
                    onAdd: { tabManager.addTab() }
                )
            }
        }
        .frame(width: state == .idle ? 180 : 420, height: 40)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(
            color: .black.opacity(state == .expanded ? 0 : 0.2),
            radius: 8,
            y: 4
        )
    }

    // MARK: - Browser Panel (400×480, gap 0)

    func browserPanel(for tab: WebTab) -> some View {
        let webView = tabManager.webView(for: tab)
        return VStack(spacing: 0) {
            WebProgressBar(webView: webView)
            ToolbarView(
                webView: webView,
                url: tab.url,
                onNavigate: { tabManager.navigateActive(to: $0) }
            )
            WebContainerView(webView: webView, url: tab.url)
        }
        .frame(width: 400, height: 480)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 20, y: 8)
    }
}

// MARK: - Tab Strip (32px 행, 파비콘 16px, Cmd+1~5)

struct TabStripView: View {
    var tabs: [WebTab]
    var activeID: WebTab.ID?
    var onSelect: (WebTab) -> Void
    var onClose: (WebTab) -> Void
    var onAdd: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(tabs.prefix(5).enumerated()), id: \.element.id) { index, tab in
                FaviconView(tab: tab, isActive: activeID == tab.id)
                    .onTapGesture { onSelect(tab) }
                    .contextMenu {
                        Button("닫기") { onClose(tab) }
                    }
                    .keyboardShortcut(
                        KeyEquivalent(Character("\(index + 1)")),
                        modifiers: .command
                    )
                    .help("\(tab.host) (⌘\(index + 1))")
            }
            Button("+") { onAdd() }
                .buttonStyle(.plain)
                .foregroundColor(.white)
                .keyboardShortcut("t", modifiers: .command)
                .help("새 탭 (⌘T)")
        }
        .frame(height: 32)
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
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Text(tab.firstLetter)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)
            }
        }
        .frame(width: 24, height: 24)
        .task(id: tab.urlString) {
            icon = await FaviconService.shared.fetchFavicon(for: tab.url)
        }
    }
}

// MARK: - Toolbar (뒤로/앞으로/새로고침 + 옴니박스 + 메뉴)

struct ToolbarView: View {
    var webView: WKWebView
    var url: URL
    var onNavigate: (String) -> Void

    @State private var editing = false
    @State private var draft = ""

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
                TextField("주소 입력", text: $draft, onCommit: {
                    editing = false
                    onNavigate(draft)
                })
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))
                .frame(width: 200)
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
            Button { } label: {
                Image(systemName: "ellipsis")
            }
        }
        .padding(8)
        .frame(height: 36)
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
                    onNavigate: { tabManager.navigateActive(to: $0) }
                )
                WebContainerView(webView: webView, url: tab.url)
            }
        }
        .frame(width: 400, height: 500)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
