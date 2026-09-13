import XCTest
@testable import WebIsland

final class NotchLayoutTests: XCTestCase {
    let midX: CGFloat = 900
    let topY: CGFloat = 1000
    /// 14형 실측 노치 너비.
    let notchWidth: CGFloat = 220

    func frame(
        for state: NotchViewModel.State,
        windowMode: WindowMode = .attached
    ) -> NSRect {
        NotchWindowController.frame(
            for: state, midX: midX, topY: topY,
            windowMode: windowMode, notchWidth: notchWidth
        )
    }

    func testIdleFrameWiderThanNotch() {
        let rect = frame(for: .idle)
        // 양옆 36씩 가시: 노치 뒤에 완전히 숨지 않음.
        XCTAssertEqual(rect.width, notchWidth + 72)
        XCTAssertEqual(rect.height, 40)
        XCTAssertEqual(rect.midX, midX, accuracy: 0.001)
        XCTAssertEqual(rect.maxY, topY, accuracy: 0.001)
    }

    func testHoveredFrame() {
        let rect = frame(for: .hovered)
        XCTAssertEqual(rect.width, 440)
        XCTAssertEqual(rect.height, 40)
        XCTAssertEqual(rect.midX, midX, accuracy: 0.001)
        XCTAssertEqual(rect.maxY, topY, accuracy: 0.001)
    }

    func testExpandedAttachedFrame() {
        let rect = frame(for: .expanded)
        XCTAssertEqual(rect.width, 440)
        XCTAssertEqual(rect.height, NotchWindowController.pillHeight + NotchWindowController.panelHeight)
        XCTAssertEqual(rect.midX, midX, accuracy: 0.001)
        XCTAssertEqual(rect.maxY, topY, accuracy: 0.001)
    }

    func testExpandedDetachedKeepsPill() {
        let rect = frame(for: .expanded, windowMode: .detached)
        XCTAssertEqual(rect.width, 440)
        XCTAssertEqual(rect.height, 40)
    }

    func testViewModelWidths() {
        let model = NotchViewModel()
        model.notchWidth = 220
        XCTAssertEqual(model.idleWidth, 292)
        XCTAssertEqual(model.expandedWidth, 440)
        XCTAssertEqual(model.centerGap, 236)
    }
}
