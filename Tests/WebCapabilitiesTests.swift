import WebKit
import XCTest
@testable import WebIsland

/// WKWebView JS 실행 확인 (헤드리스).
@MainActor
final class WebCapabilitiesTests: XCTestCase {
    final class Delegate: NSObject, WKNavigationDelegate {
        var onFinish: (() -> Void)?
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onFinish?()
        }
    }

    func testJavaScriptEnabled() async throws {
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 390, height: 100))
        let delegate = Delegate()
        webView.navigationDelegate = delegate
        let finished = expectation(description: "load finish")
        delegate.onFinish = { finished.fulfill() }
        webView.loadHTMLString("<html><body><script>window.__wiProbe = 6 * 7;</script></body></html>", baseURL: nil)
        await fulfillment(of: [finished], timeout: 10)
        let value = try await webView.evaluateJavaScript("window.__wiProbe")
        XCTAssertEqual(value as? Int, 42)
    }
}
