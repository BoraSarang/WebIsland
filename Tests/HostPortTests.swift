import XCTest
@testable import WebIsland

final class HostPortTests: XCTestCase {
    func testBadgeOmitsDefaultPorts() {
        XCTAssertNil(HostPort.badge(port: 443, scheme: "https"))
        XCTAssertNil(HostPort.badge(port: 80, scheme: "http"))
        XCTAssertNil(HostPort.badge(port: nil, scheme: "https"))
    }

    func testBadgeKeepsNonDefaultPorts() {
        XCTAssertEqual(HostPort.badge(port: 8443, scheme: "https"), ":8443")
        XCTAssertEqual(HostPort.badge(port: 3000, scheme: "http"), ":3000")
        XCTAssertEqual(HostPort.badge(port: 80, scheme: "https"), ":80")
        XCTAssertEqual(HostPort.badge(port: 443, scheme: nil), ":443")
    }

    func testCacheKeyAndDisplay() {
        XCTAssertEqual(HostPort.cacheKey(host: "example.com", port: 443, scheme: "https"), "example.com")
        XCTAssertEqual(HostPort.cacheKey(host: "example.com", port: 3000, scheme: "http"), "example.com:3000")
        XCTAssertEqual(HostPort.cacheKey(host: nil, port: 3000, scheme: "http"), "")
        XCTAssertEqual(
            HostPort.display(host: "example.com", port: nil, scheme: "https", fallback: "FB"),
            "example.com"
        )
        XCTAssertEqual(HostPort.display(host: nil, port: nil, scheme: nil, fallback: "FB"), "FB")
    }
}
