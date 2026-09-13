import Cocoa
import XCTest
@testable import WebIsland

final class NotchWindowFactoryTests: XCTestCase {
    func testDetachedFrameDefaultsWithoutSaved() {
        let screen = NSRect(x: 0, y: 0, width: 1512, height: 982)
        let frame = NotchWindowFactory.detachedFrame(saved: nil, screen: screen)

        XCTAssertEqual(frame.width, NotchMetrics.detachedWidth)
        XCTAssertEqual(frame.height, NotchMetrics.panelHeight)
    }

    func testDetachedFrameClampsUndersizedSaved() {
        let screen = NSRect(x: 0, y: 0, width: 1512, height: 982)
        let saved = NSStringFromRect(NSRect(x: 500, y: 500, width: 400, height: 500))
        let frame = NotchWindowFactory.detachedFrame(saved: saved, screen: screen)

        XCTAssertEqual(frame.width, NotchMetrics.detachedWidth)
        XCTAssertEqual(frame.height, NotchMetrics.panelHeight)
    }
}
