import Cocoa
import XCTest
@testable import WebIsland

final class HoverTrackerTests: XCTestCase {
    private func tracker() -> (HoverTracker, NSMutableArray) {
        let tracker = HoverTracker()
        let calls = NSMutableArray()
        tracker.onEnter = { calls.add("enter") }
        tracker.onExit = { calls.add("exit") }
        return (tracker, calls)
    }

    func testEnterOnIdleHover() {
        let (tracker, calls) = tracker()
        let notch = NSRect(x: 800, y: 900, width: 220, height: 30)
        tracker.track(
            mouse: NSPoint(x: 910, y: 915),
            panelFrame: nil,
            notch: notch,
            state: .idle
        )
        XCTAssertEqual(calls as? [String], ["enter"])
    }

    func testNoEnterWhenExpanded() {
        let (tracker, calls) = tracker()
        let notch = NSRect(x: 800, y: 900, width: 220, height: 30)
        tracker.track(
            mouse: NSPoint(x: 910, y: 915),
            panelFrame: nil,
            notch: notch,
            state: .expanded
        )
        XCTAssertEqual((calls as? [String]) ?? [], [])
    }

    func testExitDebounced() {
        let (tracker, calls) = tracker()
        let notch = NSRect(x: 800, y: 900, width: 220, height: 30)
        let panel = NSRect(x: 700, y: 100, width: 420, height: 884)
        let expectation = expectation(description: "collapse after debounce")
        tracker.onExit = {
            (calls as NSMutableArray).add("exit")
            expectation.fulfill()
        }
        tracker.track(mouse: NSPoint(x: 0, y: 0), panelFrame: panel, notch: notch, state: .hovered)
        wait(for: [expectation], timeout: 1.0)
    }

    func testCancelPreventsExit() {
        let (tracker, calls) = tracker()
        let notch = NSRect(x: 800, y: 900, width: 220, height: 30)
        let panel = NSRect(x: 700, y: 100, width: 420, height: 884)
        tracker.track(mouse: NSPoint(x: 0, y: 0), panelFrame: panel, notch: notch, state: .hovered)
        tracker.cancel()
        tracker.onExit = { XCTFail("cancel 후 onExit 호출됨") }
        let done = expectation(description: "debounce window elapsed")
        // 0.3초 디바운스 이후에도 onExit이 오지 않아야 한다.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { done.fulfill() }
        wait(for: [done], timeout: 1.0)
        XCTAssertEqual((calls as? [String]) ?? [], [])
    }
}
