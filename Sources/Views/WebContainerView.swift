import Cocoa
import Combine
import Security
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
            guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
                  let trust = challenge.protectionSpace.serverTrust
            else {
                completionHandler(.performDefaultHandling, nil)
                return
            }
            let host = challenge.protectionSpace.host
            if CertTrustService.trustedHosts().contains(host) {
                DebugLogger.info("인증서 예외 적용(기억됨): \(host)")
                completionHandler(.useCredential, URLCredential(trust: trust))
                return
            }
            if CertTrustService.isPrivateIP(host) {
                CertTrustService.remember(host: host)
                DebugLogger.feature("CertTrust", "사설IP 자동 신뢰: \(host)")
                completionHandler(.useCredential, URLCredential(trust: trust))
                return
            }
            // WKNavigationDelegate로 didReceive를 구현하면 WebKit의 기본 신뢰
            // 검증이 대리자 책임으로 대체된다. 시스템 체인에 유효한 인증서
            // (예: github.com)는 프롬프트 없이 수락하고, 실제 검증에 실패한
            // 인증서만 사용자 확인으로 보낸다.
            // SecTrustEvaluate*는 네트워크(중간 CA/해지) 접근이 가능하므로
            // 메인 런루프 대신 백그라운드에서 동기 검증한다.
            // (SecTrustEvaluateAsyncWithError는 메인 호출 시 내부 큐 assert로
            // 크래시하므로 사용하지 않는다.)
            DispatchQueue.global(qos: .userInitiated).async {
                var evalError: CFError?
                let trusted = SecTrustEvaluateWithError(trust, &evalError)
                DispatchQueue.main.async {
                    if trusted {
                        DebugLogger.feature("CertTrust", "시스템 신뢰 통과: \(host)")
                        completionHandler(.useCredential, URLCredential(trust: trust))
                    } else {
                        DebugLogger.feature("CertTrust", "신뢰 검증 실패, 사용자 확인: \(host)")
                        self.askToTrust(host: host, trust: trust, completionHandler: completionHandler)
                    }
                }
            }
        }

        private func askToTrust(
            host: String,
            trust: SecTrust,
            completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("certrust.title", comment: "")
            alert.informativeText = String(
                format: NSLocalizedString("certrust.message", comment: ""),
                host
            )
            alert.addButton(withTitle: NSLocalizedString("certrust.continue", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("certrust.cancel", comment: ""))
            // 노치 패널은 `.screenSaver` 레벨이라 기본 알림은 뒤에 가려진다.
            // 경고를 팝오버 위로 올려 사용자 확인이 가능하도록 한다.
            alert.window.level = .screenSaver
            if alert.runModal() == .alertFirstButtonReturn {
                CertTrustService.remember(host: host)
                DebugLogger.feature("CertTrust", "사용자 확인 신뢰: \(host)")
                completionHandler(.useCredential, URLCredential(trust: trust))
            } else {
                DebugLogger.info("인증서 신뢰 거부됨: \(host)")
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
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
            let filename = navigationAction.request.url?.lastPathComponent
                ?? navigationAction.request.url?.absoluteString
                ?? "파일"
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
            let filename = navigationResponse.response.suggestedFilename
                ?? navigationResponse.response.url?.absoluteString
                ?? "파일"
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
            let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            let tempURL = DownloadManager.shared.uniqueDestination(
                in: downloads,
                suggested: "\(suggestedFilename).download"
            )
            DebugLogger.feature("Download", "임시 저장: \(tempURL.lastPathComponent)")
            DownloadManager.shared.setDestination(tempURL, for: download)
            completionHandler(tempURL)
        }

        func downloadDidFinish(_ download: WKDownload) {
            DebugLogger.info("다운로드 완료")
            guard let id = DownloadManager.shared.itemID(for: download) else { return }
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
