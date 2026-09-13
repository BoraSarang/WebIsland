import Cocoa
import Combine
import SwiftData
import WebKit

/// 탭 영속(SwiftData) + WKWebView 풀(`WebViewPool` 위임, 활성 1 + 캐시 2).
/// 풀 밖 탭은 URL만 보관, on-demand 로드. 로그인 유지는 공유 데이터스토어.
@MainActor
final class TabManager: ObservableObject {
    @Published private(set) var tabs: [WebTab] = []
    @Published var activeTabID: WebTab.ID?

    private let webPool = WebViewPool()

    private var context: ModelContext?

    var activeTab: WebTab? {
        tabs.first { $0.id == activeTabID }
    }

    init(isStoredInMemoryOnly: Bool = false) {
        DebugLogger.feature("TabManager", "초기화")
        setupStore(isStoredInMemoryOnly: isStoredInMemoryOnly)
        loadTabs()
    }

    // MARK: - Store

    private func setupStore(isStoredInMemoryOnly: Bool) {
        let config = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
        do {
            let container = try ModelContainer(for: WebTab.self, configurations: config)
            context = ModelContext(container)
        } catch {
            DebugLogger.error(code: "E-MAC-DB-0001", "탭 저장소 열기 실패")
        }
    }

    private func loadTabs() {
        guard let context else { return }
        do {
            var descriptor = FetchDescriptor<WebTab>(sortBy: [SortDescriptor(\.order)])
            descriptor.fetchLimit = 50
            let fetched = try context.fetch(descriptor)
            // 손상된 URL 영속값은 로드 시점에 제거 (WebTab.url 강제언랩 크래시 방지).
            let corrupt = fetched.filter { URL(string: $0.urlString) == nil }
            for tab in corrupt {
                DebugLogger.error(code: "E-MAC-DB-0001", "손상 탭 제거: \(tab.urlString.prefix(80))")
                context.delete(tab)
            }
            tabs = fetched.filter { URL(string: $0.urlString) != nil }
        } catch {
            DebugLogger.error(code: "E-MAC-DB-0001", "탭 불러오기 실패")
            tabs = []
        }
        if tabs.isEmpty {
            seedDefaultTabs()
        }
        if activeTabID == nil {
            activeTabID = tabs.first?.id
        }
    }

    private func seedDefaultTabs() {
        let defaults = ["https://github.com", "https://notion.so", "https://linear.app"]
        for (index, raw) in defaults.enumerated() {
            if let url = URL(string: raw) {
                let tab = WebTab(url: url, order: index)
                context?.insert(tab)
                tabs.append(tab)
            }
        }
        save()
    }

    private func save() {
        guard let context else { return }
        do {
            try context.save()
        } catch {
            DebugLogger.error(code: "E-MAC-DB-0001", "탭 저장 실패")
        }
    }

    // MARK: - CRUD

    /// + 버튼: 빈 안내 페이지 탭 (URL 입력 유도).
    func addTab() {
        DebugLogger.feature("TabManager.addTab", "새 탭 안내 페이지")
        let tab = WebTab(
            url: URL(string: "about:blank")!,
            order: (tabs.map(\.order).max() ?? -1) + 1
        )
        context?.insert(tab)
        tabs.append(tab)
        activeTabID = tab.id
        save()
    }

    func addTab(urlString: String) {
        DebugLogger.feature("TabManager.addTab", urlString)
        guard let url = validatedURL(urlString) else {
            DebugLogger.error(code: "E-MAC-VALID-0001", "잘못된 주소: \(urlString)")
            return
        }
        let tab = WebTab(url: url, order: (tabs.map(\.order).max() ?? -1) + 1)
        context?.insert(tab)
        tabs.append(tab)
        activeTabID = tab.id
        save()
    }

    func closeTab(_ tab: WebTab) {
        if tab.isPinned {
            DebugLogger.info("고정 탭은 닫기 불가, 고정 해제 후 닫기: \(tab.host)")
            return
        }
        DebugLogger.feature("TabManager.closeTab", tab.host)
        webPool.remove(tab.id)
        tabs.removeAll { $0.id == tab.id }
        context?.delete(tab)
        if activeTabID == tab.id {
            activeTabID = tabs.sorted { $0.order < $1.order }.last?.id
        }
        save()
    }

    func selectTab(_ tab: WebTab) {
        let previous = activeTabID?.uuidString.prefix(8) ?? "없음"
        DebugLogger.feature("TabManager.selectTab", "\(tab.urlString) (이전: \(previous))")
        activeTabID = tab.id
    }

    func togglePin(_ tab: WebTab) {
        DebugLogger.feature("TabManager.togglePin", "\(tab.host): \(!tab.isPinned)")
        tab.isPinned.toggle()
        objectWillChange.send()
        save()
    }

    func moveTab(from source: IndexSet, to destination: Int) {
        var ordered = tabs.sorted { $0.order < $1.order }
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, tab) in ordered.enumerated() {
            tab.order = index
        }
        tabs = ordered
        save()
    }

    func navigateActive(to urlString: String) {
        guard let url = validatedURL(urlString), let tab = activeTab else {
            DebugLogger.error(code: "E-MAC-VALID-0001", "잘못된 주소: \(urlString)")
            return
        }
        tab.urlString = url.absoluteString
        webView(for: tab).load(URLRequest(url: url))
        save()
    }

    /// 리다이렉트·https 업그레이드 후 WebView가 커밋한 실측 URL을 탭에 반영.
    func syncURL(_ tab: WebTab, _ urlString: String) {
        guard tab.urlString != urlString else { return }
        DebugLogger.info("URL 실측 동기화: \(urlString)")
        tab.urlString = urlString
        save()
    }

    private func validatedURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), Self.isLoadable(url) {
            return url
        }
        if let url = URL(string: "https://\(trimmed)"), Self.isLoadable(url) {
            return url
        }
        return nil
    }

    private static func isLoadable(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host, !host.isEmpty
        else { return false }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-")
        return host.rangeOfCharacter(from: allowed.inverted) == nil
    }

    // MARK: - WebView Pool (`WebViewPool` 위임)

    func webView(for tab: WebTab) -> WKWebView {
        webPool.webView(for: tab, activeID: activeTabID)
    }

    var poolSize: Int { webPool.count }
}
