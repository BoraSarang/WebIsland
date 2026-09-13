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

    func testFaviconKeyIsolatesByPort() {
        // 동일 호스트의 다른 포트는 서로 다른 캐시 키를 가진다.
        XCTAssertEqual(tab("http://10.36.188.13:8443/").faviconKey, "10.36.188.13:8443")
        XCTAssertEqual(tab("http://10.36.188.13:3000/").faviconKey, "10.36.188.13:3000")
        XCTAssertEqual(tab("http://10.36.188.13:3001/").faviconKey, "10.36.188.13:3001")
        // 기본 포트는 호스트만 (포트 배지 생략 규칙과 일치).
        XCTAssertEqual(tab("https://github.com").faviconKey, "github.com")
        XCTAssertEqual(tab("https://example.com:443/").faviconKey, "example.com")
        XCTAssertEqual(tab("http://example.com:80/").faviconKey, "example.com")
    }
}
