import XCTest
@testable import WebIsland

final class WebTabTests: XCTestCase {
    private func tab(_ urlString: String) -> WebTab {
        WebTab(url: URL(string: urlString)!, order: 0)
    }

    func testPortBadgeCustomPort() {
        XCTAssertEqual(tab("https://10.36.188.13:8443/").portBadge, ":8443")
        XCTAssertEqual(tab("http://10.36.188.13:3000/").portBadge, ":3000")
    }

    func testPortBadgeOmitsDefaultPorts() {
        XCTAssertNil(tab("https://github.com").portBadge)
        XCTAssertNil(tab("http://example.com").portBadge)
        XCTAssertNil(tab("https://example.com:443/").portBadge)
        XCTAssertNil(tab("http://example.com:80/").portBadge)
    }

    func testPortBadgeNewTabPage() {
        XCTAssertNil(tab("about:blank").portBadge)
    }
}
