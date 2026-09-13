import XCTest
@testable import WebIsland

final class SettingsViewTests: XCTestCase {
    func testAppInfoReadsBundleKeys() {
        let info = SettingsView.appInfo(from: [
            "CFBundleName": "Web Island",
            "CFBundleShortVersionString": "0.1.0",
            "CFBundleVersion": "42",
        ])
        XCTAssertEqual(info.name, "Web Island")
        XCTAssertEqual(info.version, "0.1.0")
        XCTAssertEqual(info.build, "42")
    }

    func testAppInfoFallsBackWhenKeysMissing() {
        let info = SettingsView.appInfo(from: [:])
        XCTAssertEqual(info.name, "Web Island")
        XCTAssertEqual(info.version, "—")
        XCTAssertEqual(info.build, "—")
    }

    func testRepositoryURL() {
        XCTAssertEqual(
            SettingsView.repositoryURL.absoluteString,
            "https://github.com/BoraSarang/WebIsland"
        )
    }
}
