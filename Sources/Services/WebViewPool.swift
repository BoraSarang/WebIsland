import Foundation
import WebKit

/// WKWebView 풀 (활성 1 + 캐시 2, LRU 제거).
/// 풀 밖 탭은 URL만 보관, on-demand 로드. 로그·카운터는 풀 책임.
/// `TabManager`에서 위임받아 사용. `@MainActor` (WebKit 요구).
@MainActor
final class WebViewPool {
    private var pool: [WebTab.ID: WKWebView] = [:]
    private var lru: [WebTab.ID] = []
    private let maxPoolSize = 3

    var count: Int { pool.count }

    func webView(for tab: WebTab, activeID: WebTab.ID?) -> WKWebView {
        if let existing = pool[tab.id] {
            touch(tab.id)
            DebugLogger.cache(hit: true, "웹뷰 풀: \(tab.host)")
            // 새 탭 안내 페이지는 뷰(WebContainerView)가 로드 담당.
            if existing.url == nil, !tab.isNewTabPage {
                existing.load(URLRequest(url: tab.url))
            }
            return existing
        }
        DebugLogger.cache(hit: false, "웹뷰 풀: \(tab.host)")
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.applicationNameForUserAgent = "WebIsland/0.1"
        if #available(macOS 11.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        let webView = WKWebView(frame: .zero, configuration: config)
        if !tab.isNewTabPage {
            webView.load(URLRequest(url: tab.url))
        }
        pool[tab.id] = webView
        touch(tab.id)
        evictIfNeeded(activeID: activeID)
        LogStore.shared.poolSize = pool.count
        DebugLogger.perf("웹뷰 풀 크기: \(pool.count)/\(maxPoolSize)")
        return webView
    }

    /// 탭 닫기: 로드 중단 + 풀·LRU에서 제거.
    func remove(_ id: WebTab.ID) {
        pool.removeValue(forKey: id)?.stopLoading()
        lru.removeAll { $0 == id }
        LogStore.shared.poolSize = pool.count
    }

    private func touch(_ id: WebTab.ID) {
        lru.removeAll { $0 == id }
        lru.append(id)
    }

    private func evictIfNeeded(activeID: WebTab.ID?) {
        while lru.count > maxPoolSize, let oldest = lru.first {
            lru.removeFirst()
            if oldest != activeID {
                pool.removeValue(forKey: oldest)?.stopLoading()
            }
        }
    }
}
