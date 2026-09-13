import Combine
import XCTest
@testable import WebIsland

final class LogStoreTests: XCTestCase {
    func testHitRateEmptyIsZero() {
        let store = LogStore()
        XCTAssertEqual(store.hitRate, 0)
    }

    func testHitRateMath() {
        let store = LogStore()
        store.cacheHits = 3
        store.cacheMisses = 1
        XCTAssertEqual(store.hitRate, 0.75, accuracy: 0.001)
    }

    func testAppendCapsBuffer() {
        let store = LogStore()
        for index in 0..<250 {
            store.append(level: "INFO", message: "m\(index)")
        }
        XCTAssertEqual(store.entries.count, 200)
        XCTAssertEqual(store.entries.last?.message, "m249")
    }

    func testRecordCacheCounts() {
        let store = LogStore()
        let done = expectation(description: "record drains on main")
        store.recordCache(hit: true)
        store.recordCache(hit: false)
        store.recordCache(hit: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { done.fulfill() }
        wait(for: [done], timeout: 1.0)
        XCTAssertEqual(store.cacheHits, 2)
        XCTAssertEqual(store.cacheMisses, 1)
        XCTAssertEqual(store.hitRate, 2.0 / 3.0, accuracy: 0.001)
    }
}
