import Cocoa
import Combine
import SwiftData
import WebKit

/// 탭 영속(SwiftData) + WKWebView 풀(활성 1 + 캐시 2, LRU 제거).
/// 풀 밖 탭은 URL만 보관, on-demand 로드. 로그인 유지는 공유 데이터스토어.
@MainActor
final class TabManager: ObservableObject {
    @Published private(set) var tabs: [WebTab] = []
    @Published var activeTabID: WebTab.ID?

    private var pool: [WebTab.ID: WKWebView] = [:]
    private var lru: [WebTab.ID] = []
    private let maxPoolSize = 3

    private var context: ModelContext?

    var activeTab: WebTab? {
        tabs.first { $0.id == activeTabID }
    }

    init() {
        DebugLogger.feature("TabManager", "초기화")
        setupStore()
        loadTabs()
    }

    // MARK: - Store

    private func setupStore() {
        do {
            let container = try ModelContainer(for: WebTab.self)
            context = ModelContext(container)
        } catch {
            DebugLogger.error(code: "E-MAC-DB-0001", "탭 저장소 열기 실패, 인메모리 폴백")
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            if let container = try? ModelContainer(for: WebTab.self, configurations: config) {
                context = ModelContext(container)
            }
        }
    }

    private func loadTabs() {
        guard let context else { return }
        do {
            var descriptor = FetchDescriptor<WebTab>(sortBy: [SortDescriptor(\.order)])
            descriptor.fetchLimit = 50
            tabs = try context.fetch(descriptor)
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

    func addTab(urlString: String = "https://duckduckgo.com") {
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
        DebugLogger.feature("TabManager.closeTab", tab.host)
        if let webView = pool.removeValue(forKey: tab.id) {
            webView.stopLoading()
        }
        lru.removeAll { $0 == tab.id }
        tabs.removeAll { $0.id == tab.id }
        context?.delete(tab)
        if activeTabID == tab.id {
            activeTabID = tabs.sorted { $0.order < $1.order }.last?.id
        }
        save()
    }

    func selectTab(_ tab: WebTab) {
        activeTabID = tab.id
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

    private func validatedURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), url.scheme != nil, url.host != nil {
            return url
        }
        if let url = URL(string: "https://\(trimmed)"), url.host != nil {
            return url
        }
        return nil
    }

    // MARK: - WebView Pool

    func webView(for tab: WebTab) -> WKWebView {
        if let existing = pool[tab.id] {
            touch(tab.id)
            DebugLogger.cache(hit: true, "웹뷰 풀: \(tab.host)")
            if existing.url == nil {
                existing.load(URLRequest(url: tab.url))
            }
            return existing
        }
        DebugLogger.cache(hit: false, "웹뷰 풀: \(tab.host)")
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.applicationNameForUserAgent = "WebIsland/0.1"
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.load(URLRequest(url: tab.url))
        pool[tab.id] = webView
        touch(tab.id)
        evictIfNeeded()
        DebugLogger.perf("웹뷰 풀 크기: \(pool.count)/\(maxPoolSize)")
        return webView
    }

    private func touch(_ id: WebTab.ID) {
        lru.removeAll { $0 == id }
        lru.append(id)
    }

    private func evictIfNeeded() {
        while lru.count > maxPoolSize, let oldest = lru.first {
            lru.removeFirst()
            if oldest != activeTabID {
                pool.removeValue(forKey: oldest)?.stopLoading()
            }
        }
    }
}
