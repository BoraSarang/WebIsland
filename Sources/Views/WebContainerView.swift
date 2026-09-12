import Combine
import SwiftUI
import WebKit

/// TabManager 풀의 WKWebView를 그대로 붙이는 래퍼 + 2px 프로그레스바.
/// 로드 완료 시 페이지의 link[rel*=icon]을 읽어 파비콘 1단계로 사용.
/// 새 탭 안내 페이지(about:blank)는 안내 HTML을 로드.
struct WebContainerView: NSViewRepresentable {
    let webView: WKWebView
    let url: URL
    let isNewTabPage: Bool

    /// 새 탭 안내 HTML (패널 머티리얼이 비치도록 투명 배경).
    static let newTabHTML = """
        <!DOCTYPE html>
        <html lang="ko">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        :root { color-scheme: light dark; }
        body {
            margin: 0; height: 100vh; display: flex;
            align-items: center; justify-content: center;
            font-family: -apple-system, sans-serif; background: transparent;
        }
        p { color: #888; font-size: 15px; letter-spacing: -0.2px; }
        </style>
        </head>
        <body><p>주소를 입력하세요</p></body>
        </html>
        """

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        loadIfNeeded(webView)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        loadIfNeeded(nsView)
    }

    private func loadIfNeeded(_ view: WKWebView) {
        if isNewTabPage {
            // loadHTMLString 완료 후 url은 about:blank이 되어 재로드 방지.
            if view.url?.absoluteString != "about:blank" {
                view.loadHTMLString(Self.newTabHTML, baseURL: nil)
            }
        } else if view.url == nil {
            view.load(URLRequest(url: url))
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKDownloadDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript(
                "document.querySelector('link[rel*=\"icon\"]')?.href ?? ''"
            ) { result, _ in
                guard let href = result as? String, !href.isEmpty else { return }
                Task {
                    await FaviconService.shared.fetchIconHREF(href)
                }
            }
        }

        // MARK: - 다운로드 (표시 불가 MIME → ~/Downloads 저장)

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
        ) {
            if navigationResponse.canShowMIMEType {
                decisionHandler(.allow)
            } else {
                decisionHandler(.download)
            }
        }

        func webView(
            _ webView: WKWebView,
            navigationResponse: WKNavigationResponse,
            didBecome download: WKDownload
        ) {
            DebugLogger.feature(
                "Download",
                "시작: \(navigationResponse.response.suggestedFilename ?? "파일")"
            )
            download.delegate = self
        }

        func download(
            _ download: WKDownload,
            decideDestinationUsing response: URLResponse,
            suggestedFilename: String,
            completionHandler: @escaping (URL?) -> Void
        ) {
            let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            completionHandler(downloads.appendingPathComponent(suggestedFilename))
        }

        func downloadDidFinish(_ download: WKDownload) {
            DebugLogger.info("다운로드 완료")
        }

        func download(
            _ download: WKDownload,
            didFailWithError error: Error,
            resumeData: Data?
        ) {
            DebugLogger.error(code: "E-MAC-NET-0002", "다운로드 실패: \(error.localizedDescription)")
        }
    }
}

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
