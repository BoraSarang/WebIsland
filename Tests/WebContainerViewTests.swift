import XCTest
@testable import WebIsland

final class WebContainerViewTests: XCTestCase {
    func testNewWindowPassesHttpURL() {
        let request = URLRequest(url: URL(string: "https://example.com/page")!)
        XCTAssertEqual(
            WebContainerView.newWindowURLString(from: request),
            "https://example.com/page"
        )
    }

    func testNewWindowRejectsNonHttp() {
        let blob = URLRequest(url: URL(string: "blob:https://example.com/x")!)
        let blank = URLRequest(url: URL(string: "about:blank")!)
        XCTAssertNil(WebContainerView.newWindowURLString(from: blob))
        XCTAssertNil(WebContainerView.newWindowURLString(from: blank))
    }

    func testNewWindowRejectsNilRequest() {
        XCTAssertNil(WebContainerView.newWindowURLString(from: nil))
    }
}
