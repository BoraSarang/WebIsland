import Foundation
import SwiftUI
import WebKit

/// TabManager 풀의 WKWebView를 그대로 붙이는 래퍼 + 2px 프로그레스바.
/// 로드 완료 시 페이지의 link[rel*=icon]을 읽어 파비콘 1단계로 사용.
/// 새 탭 안내 페이지(about:blank)는 안내 HTML을 로드.
struct WebContainerView: NSViewRepresentable {
    let webView: WKWebView
    let url: URL
    let isNewTabPage: Bool
    /// 로드 완료 시 파비콘을 기록할 탭 (약참조로 Coordinator에 전달).
    let tab: WebTab
    /// 리다이렉트/https 업그레이드 후 실제 주소를 탭에 동기화.
    var onURLDidChange: (String) -> Void = { _ in }
    /// target=_blank·window.open 요청을 새 탭으로 (nil이면 주소 없는 팝업이라 무시).
    var onOpenNewWindow: (String) -> Void = { _ in }

    /// 새창 요청에서 새 탭으로 열 주소만 추림 (순수 함수, 단위 테스트 대상).
    /// http(s)만, 그 외(blob·about:blank 등 JS 팝업 포함)는 nil.
    static func newWindowURLString(from request: URLRequest?) -> String? {
        guard let url = request?.url,
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return nil }
        return url.absoluteString
    }

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
        let coordinator = Coordinator()
        coordinator.tab = tab
        coordinator.onURLDidChange = onURLDidChange
        coordinator.onOpenNewWindow = onOpenNewWindow
        return coordinator
    }

    func makeNSView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        // UIDelegate 미설정 시 target=_blank·window.open이 조용히 버려진다.
        webView.uiDelegate = context.coordinator
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

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
        weak var tab: WebTab?
        var onURLDidChange: (String) -> Void = { _ in }
        var onOpenNewWindow: (String) -> Void = { _ in }
        private let certTrustHandler = CertTrustHandler()

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            syncURL(from: webView)
        }

        /// 화면에 커밋된 실제 주소(http/https 한정)를 탭에 반영.
        /// 타이핑 입력(about:blank/오타)이나 팝업 등은 제외하고,
        /// 동일값·중간 리다이렉트 단계는 시간순 최신으로 덮어쓴다.
        private func syncURL(from webView: WKWebView) {
            guard let tab, let current = webView.url else { return }
            guard let scheme = current.scheme?.lowercased(),
                  scheme == "http" || scheme == "https"
            else { return }
            let resolved = current.absoluteString
            guard resolved != tab.urlString else { return }
            onURLDidChange(resolved)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript(
                "document.querySelector('link[rel*=\"icon\"]')?.href ?? ''"
            ) { [weak self] result, _ in
                guard let href = result as? String, !href.isEmpty else { return }
                Task { [weak self] in
                    guard let tab = self?.tab else { return }
                    let pageKey = tab.faviconKey
                    if let img = await FaviconService.shared.fetchIconHREF(href, pageKey: pageKey) {
                        await MainActor.run {
                            tab.cachedFavicon = img
                        }
                    }
                }
            }
        }

        // MARK: - 사설 인증서 (확인 후 기억 + 사설IP 자동 신뢰)

        func webView(
            _ webView: WKWebView,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {
            certTrustHandler.handle(challenge: challenge, completionHandler: completionHandler)
        }

        // MARK: - 새창 (target=_blank·window.open → 새 탭)

        /// 별도 팝업 웹뷰 대신 새 탭으로 연다. nil 반환이라 중복 로드 없음.
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard let urlString = WebContainerView.newWindowURLString(from: navigationAction.request) else {
                let logged = navigationAction.request.url?.absoluteString.prefix(80) ?? "nil"
                DebugLogger.info("새창 무시 (주소 없는 팝업): \(logged)")
                return nil
            }
            DebugLogger.feature("NewWindow", "새 탭으로 열기: \(urlString.prefix(120))")
            onOpenNewWindow(urlString)
            return nil
        }

        /// JS window.close()는 로그만 (메인 탭 오닫기 방지, 팝업 추적은 후속).
        func webViewDidClose(_ webView: WKWebView) {
            DebugLogger.info("window.close() 수신, 무시")
        }

        // MARK: - 다운로드 (표시 불가 MIME → ~/Downloads 저장)

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            let urlString = navigationAction.request.url?.absoluteString ?? ""
            if navigationAction.request.url?.scheme == "blob" {
                // blob: 다운로드는 WebKit 단독 불가 → JS 브리지 필요. 우선 로그로 판별.
                DebugLogger.info("blob 다운로드 감지 (브리지 필요): \(urlString.prefix(80))")
                decisionHandler(.allow)
                return
            }
            if navigationAction.shouldPerformDownload {
                DebugLogger.feature("Download", "action 경로: \(urlString.prefix(120))")
                decisionHandler(.download)
            } else {
                decisionHandler(.allow)
            }
        }

        func webView(
            _ webView: WKWebView,
            navigationAction: WKNavigationAction,
            didBecome download: WKDownload
        ) {
            let filename = DownloadRouting.actionFilename(request: navigationAction.request)
            DebugLogger.feature(
                "Download",
                "시작(action): \(filename)"
            )
            download.delegate = self
            DownloadManager.shared.register(download, filename: filename)
        }

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
            let filename = DownloadRouting.responseFilename(response: navigationResponse.response)
            DebugLogger.feature(
                "Download",
                "시작(response): \(filename)"
            )
            download.delegate = self
            DownloadManager.shared.register(download, filename: filename)
        }

        func download(
            _ download: WKDownload,
            decideDestinationUsing response: URLResponse,
            suggestedFilename: String,
            completionHandler: @escaping (URL?) -> Void
        ) {
            // 완료 전까지 임시 `.download` 파일로 저장하고, 완료 시 최종 이름으로 rename.
            let tempURL = DownloadRouting.tempURL(suggestedFilename: suggestedFilename)
            DebugLogger.feature("Download", "임시 저장: \(tempURL.lastPathComponent)")
            DownloadManager.shared.setDestination(tempURL, for: download)
            completionHandler(tempURL)
        }

        func downloadDidFinish(_ download: WKDownload) {
            guard let id = DownloadManager.shared.itemID(for: download) else {
                DebugLogger.error(code: "E-MAC-NET-0002", "완료 매칭 실패: 트레이 고아 항목 가능")
                return
            }
            DownloadManager.shared.finish(id: id)
        }

        func download(
            _ download: WKDownload,
            didFailWithError error: Error,
            resumeData: Data?
        ) {
            DebugLogger.feature(
                "Download",
                "didFail 도달: code=\((error as NSError).code) (\(error.localizedDescription))"
            )
            guard let id = DownloadManager.shared.itemID(for: download) else {
                DebugLogger.error(code: "E-MAC-NET-0002", "다운로드 실패: \(error.localizedDescription)")
                return
            }
            DownloadManager.shared.fail(id: id, error: error)
        }
    }
}
