import XCTest
@testable import WebIsland

final class NotchDetectorTests: XCTestCase {
    func testRectWithNotch() {
        let left = NSRect(x: 0, y: 1000, width: 200, height: 32)
        let right = NSRect(x: 400, y: 1000, width: 200, height: 32)
        let rect = NotchDetector.rect(left: left, right: right)
        XCTAssertNotNil(rect)
        XCTAssertEqual(rect?.minX, 200)
        XCTAssertEqual(rect?.width, 200)
        XCTAssertEqual(rect?.minY, 1000)
        XCTAssertEqual(rect?.height, 32)
    }

    func testRectWithoutNotch() {
        let left = NSRect(x: 0, y: 1000, width: 300, height: 32)
        let right = NSRect(x: 300, y: 1000, width: 300, height: 32)
        XCTAssertNil(NotchDetector.rect(left: left, right: right))
    }

    func testRectZeroLeftArea() {
        let left = NSRect(x: 0, y: 0, width: 0, height: 0)
        let right = NSRect(x: 0, y: 0, width: 600, height: 32)
        XCTAssertNil(NotchDetector.rect(left: left, right: right))
    }

    func testHoverInsideExpandedArea() {
        let notch = NSRect(x: 200, y: 1000, width: 200, height: 32)
        XCTAssertTrue(NotchDetector.isHover(mouse: NSPoint(x: 300, y: 1010), notch: notch))
    }

    func testHoverOutsideExpandedArea() {
        let notch = NSRect(x: 200, y: 1000, width: 200, height: 32)
        XCTAssertFalse(NotchDetector.isHover(mouse: NSPoint(x: 0, y: 0), notch: notch))
    }
}
