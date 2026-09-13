import WebKit
import XCTest
@testable import WebIsland

final class DownloadRoutingTests: XCTestCase {
    func testActionFilenamePrefersLastPath() {
        let request = URLRequest(url: URL(string: "https://example.com/files/app.dmg")!)
        XCTAssertEqual(DownloadRouting.actionFilename(request: request), "app.dmg")
    }

    func testResponseFilenamePrefersSuggested() {
        let url = URL(string: "https://example.com/dl?id=1")!
        let response = URLResponse(
            url: url, mimeType: "application/octet-stream",
            expectedContentLength: 10, textEncodingName: nil
        )
        // suggestedFilename 기본값(마지막 경로 조각)을 그대로 쓴다.
        XCTAssertEqual(DownloadRouting.responseFilename(response: response), response.suggestedFilename)
    }

    @MainActor
    func testTempURLHasDownloadSuffix() {
        let temp = DownloadRouting.tempURL(suggestedFilename: "app.dmg")
        XCTAssertTrue(temp.lastPathComponent.hasSuffix(".dmg.download"), temp.lastPathComponent)
        XCTAssertTrue(temp.path.contains("Downloads") || temp.path.contains("tmp"))
    }
}
