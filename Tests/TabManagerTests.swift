import XCTest
@testable import WebIsland

@MainActor
final class TabManagerTests: XCTestCase {
    func testSeedDefaultsOnEmptyStore() {
        let manager = TabManager(isStoredInMemoryOnly: true)
        XCTAssertEqual(manager.tabs.count, 3)
        XCTAssertNotNil(manager.activeTabID)
    }

    func testAddTabSelectsNewTab() {
        let manager = TabManager(isStoredInMemoryOnly: true)
        manager.addTab(urlString: "https://example.com")
        XCTAssertEqual(manager.tabs.count, 4)
        XCTAssertEqual(manager.activeTab?.host, "example.com")
    }

    func testPlusButtonCreatesBlankGuidePage() {
        let manager = TabManager(isStoredInMemoryOnly: true)
        manager.addTab()
        XCTAssertEqual(manager.tabs.count, 4)
        XCTAssertEqual(manager.activeTab?.isNewTabPage, true)
    }

    func testTogglePinProtectsFromClose() {
        let manager = TabManager(isStoredInMemoryOnly: true)
        guard let first = manager.tabs.first else {
            XCTFail("시드 탭 없음")
            return
        }
        manager.togglePin(first)
        XCTAssertTrue(first.isPinned)
        manager.closeTab(first)
        XCTAssertEqual(manager.tabs.count, 3)
        manager.togglePin(first)
        manager.closeTab(first)
        XCTAssertEqual(manager.tabs.count, 2)
    }

    func testAddTabRejectsInvalidURL() {
        let manager = TabManager(isStoredInMemoryOnly: true)
        manager.addTab(urlString: "ht!tp://[invalid")
        XCTAssertEqual(manager.tabs.count, 3)
    }

    func testAddTabAcceptsBareHost() {
        let manager = TabManager(isStoredInMemoryOnly: true)
        manager.addTab(urlString: "example.org")
        XCTAssertEqual(manager.activeTab?.host, "example.org")
    }

    func testCloseActiveTabReselects() {
        let manager = TabManager(isStoredInMemoryOnly: true)
        guard let active = manager.activeTab else {
            XCTFail("시드 탭 없음")
            return
        }
        manager.closeTab(active)
        XCTAssertEqual(manager.tabs.count, 2)
        XCTAssertNotNil(manager.activeTabID)
    }
}
