import Cocoa
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
            askToTrust(host: host, trust: trust, completionHandler: completionHandler)
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
            if alert.runModal() == .alertFirstButtonReturn {
                CertTrustService.remember(host: host)
                DebugLogger.feature("CertTrust", "사용자 확인 신뢰: \(host)")
                completionHandler(.useCredential, URLCredential(trust: trust))
            } else {
                DebugLogger.info("인증서 신뢰 거부됨: \(host)")
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
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
            DebugLogger.feature(
                "Download",
                "시작(action): \(navigationAction.request.url?.lastPathComponent ?? "파일")"
            )
            download.delegate = self
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
