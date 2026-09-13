import Combine
import SwiftUI
import WebKit

// MARK: - Browser Chrome (노치/분리 공용: 진행바 + 툴바 + 트레이 + 웹뷰)

/// `browserPanel`과 `DetachedBrowserView`의 완전일치 배선(24줄)을 한 곳으로.
/// 껍데기(너비·배경·클립)만 호출처가 담당한다.
struct BrowserChromeView: View {
    @ObservedObject var tabManager: TabManager
    var tab: WebTab
    /// 노치는 웹뷰만 10pt 인셋, 분리는 자연폭 (nil이면 제약 없음).
    var webWidth: CGFloat?

    var body: some View {
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
                onURLDidChange: { tabManager.syncURL(tab, $0) },
                onOpenNewWindow: { tabManager.addTab(urlString: $0) }
            )
                .id(tab.id)
                .frame(width: webWidth)
        }
    }
}

/// 웹뷰 상단 2px 로딩 진행바.
struct WebProgressBar: View {
    @State private var progress: Double = 0
    let webView: WKWebView

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: geo.size.width * progress, height: 2)
                .opacity(progress >= 1.0 || progress == 0 ? 0 : 1)
        }
        .frame(height: 2)
        .onReceive(webView.publisher(for: \.estimatedProgress)) { value in
            progress = value
        }
    }
}
