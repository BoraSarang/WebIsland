import XCTest
@testable import WebIsland

final class CertTrustTests: XCTestCase {
    override func setUp() {
        super.setUp()
        CertTrustService.store = UserDefaults(suiteName: "WebIslandTests.CertTrust")!
        CertTrustService.store.removePersistentDomain(forName: "WebIslandTests.CertTrust")
    }

    func testPrivateIPv4Ranges() {
        XCTAssertTrue(CertTrustService.isPrivateIP("10.36.188.13"))
        XCTAssertTrue(CertTrustService.isPrivateIP("10.0.0.1"))
        XCTAssertTrue(CertTrustService.isPrivateIP("172.16.0.1"))
        XCTAssertTrue(CertTrustService.isPrivateIP("172.31.255.255"))
        XCTAssertTrue(CertTrustService.isPrivateIP("192.168.1.1"))
        XCTAssertTrue(CertTrustService.isPrivateIP("127.0.0.1"))
        XCTAssertTrue(CertTrustService.isPrivateIP("localhost"))
    }

    func testPublicHostsNotPrivate() {
        XCTAssertFalse(CertTrustService.isPrivateIP("8.8.8.8"))
        XCTAssertFalse(CertTrustService.isPrivateIP("172.15.0.1"))
        XCTAssertFalse(CertTrustService.isPrivateIP("172.32.0.1"))
        XCTAssertFalse(CertTrustService.isPrivateIP("example.com"))
        XCTAssertFalse(CertTrustService.isPrivateIP("not an ip"))
        XCTAssertFalse(CertTrustService.isPrivateIP("10.0.0.999"))
    }

    func testRememberRoundTrip() {
        XCTAssertTrue(CertTrustService.trustedHosts().isEmpty)
        CertTrustService.remember(host: "10.36.188.13")
        XCTAssertTrue(CertTrustService.trustedHosts().contains("10.36.188.13"))
        CertTrustService.remember(host: "10.36.188.13")
        XCTAssertEqual(CertTrustService.trustedHosts().count, 1)
    }
}
