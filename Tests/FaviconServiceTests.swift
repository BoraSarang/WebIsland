import AppKit
import XCTest
@testable import WebIsland

final class FaviconServiceTests: XCTestCase {
    /// 테스트용 4×4 PNG 생성.
    private func samplePNG() -> Data {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 4,
            pixelsHigh: 4,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        return rep.representation(using: .png, properties: [:])!
    }

    /// 실제 야생 ICO(16×16 BMP 엔트리) fixture.
    /// 합성 ICO는 ImageIO가 거부하므로 실측 바이트를 내장한다.
    private func realWorldICO() -> Data {
        let b64 = "AAABAAEAEBAAAAEAIAAoBQAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
            + "AAAAERETdhMTE8UODg4SAAAAAAAAAAAPDw8REREUsRMTE2kAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFBQUlhMTFPwTExTt"
            + "AAAAGQAAAAAAAAAAAAAAGBUVF/8VFRf/EREThQAAAAAAAAAAAAAAAAAAAAAAAAAAERESwRMTFO4REREeEBAQEAAAAAAAAAAAAAAA"
            + "AAAAAA0TExT1FRUX/xUVF/8RERSvAAAAAAAAAAAAAAAAFBQUmRUVF/8GBhEsDg4OXA8PD8EPDw8iAAAAAAAAAAAPDw80EBAQ/xUV"
            + "F/8VFRf/FRUX/xQUFI8AAAAAEBAQMA8ND/8AAAD5AQEB7QICAv8CAgL2Dg4OOAAAAAAAAAAACAgIQAICAusVFRf/FRUX/xUVF/8V"
            + "FRf/ERERLRQUFZwUFBX/AQEB/A8PEfsNDRE7AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADQ0SOhMTFOcVFRf/FRUX/xISEpoTExPZ"
            + "FRUX/xUVF/8TExNPAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARERFMFRUX/xUVF/8TExPaExMU9hUVF/8UFBTwAAAA"
            + "AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAhMTFPEVFRf/ExMU9hMTFPcVFRf/FBQU4QAAAAAAAAAAAAAAAAAA"
            + "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAUFBThFRUX/xMTFPcUFBTeFRUX/xMTFPkPDw8hAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
            + "AAAAAAAAAAAAAAAQEBAfExMU+BUVF/8UFBTeEREUohUVF/8VFRf/Dw8PNAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
            + "EBAQQBUVF/8VFRf/EREUog4ODjgVFRf/FRUX/xISEpgAAAAAAAAADAAAAAoAAAAAAAAAAAAAAAwAAAABAAAAABISEpgVFRf/FRUX"
            + "/w4ODjgAAAAAEREUpBUVF/8RERLBDg4ONgAAAIENDQ3cEhIU2BISFNgTExT3AAAAdAUFBTcRERLBFRUX/xERFKQAAAAAAAAAAAAA"
            + "AAMTExPGFRUX/xUVF/8VFRf/FRUX/xUVF/8VFRf/FRUX/xUVF/8VFRf/FRUX/xMTE8YAAAADAAAAAAAAAAAAAAAAAAAAAxERFKIV"
            + "FRf/FRUX/xUVF/8VFRf/FRUX/xUVF/8VFRf/FRUX/xERFKIAAAADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEBAQPhMTE5cTExPZ"
            + "EhIU8hISFPITExPZExMTlxAQED4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
            + "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
            + "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
            + "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="
        return Data(base64Encoded: b64)!
    }

    func testDecodePNG() {
        XCTAssertNotNil(FaviconService.decodeImage(samplePNG()))
    }

    func testDecodeICO() {
        // 야생 ICO(16×16 BMP 엔트리)가 NSImage 직접 경로 또는
        // ImageIO 폴백 경로로 디코딩되는지 검증.
        let ico = realWorldICO()
        let decoded = FaviconService.decodeImage(ico)
        XCTAssertNotNil(decoded, "ICO 디코딩")
        XCTAssertEqual(decoded?.size.width, 16)
        XCTAssertEqual(decoded?.size.height, 16)
    }

    func testDecodeGarbage() {
        XCTAssertNil(FaviconService.decodeImage(Data([0, 1, 2, 3])))
    }

    func testDiskCacheVersioned() {
        XCTAssertEqual(FaviconService.diskCacheVersion, "favicons-v2")
    }

    func testAvatarFallbackNotPersisted() async throws {
        // .invalid는 RFC 2606 예약 TLD라 즉시 실패한다.
        let url = URL(string: "https://invalid.invalid")!
        let img = await FaviconService.shared.fetchFavicon(for: url)
        XCTAssertNotNil(img, "폴백 아바타 반환")
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let file = caches
            .appendingPathComponent("WebIsland/\(FaviconService.diskCacheVersion)", isDirectory: true)
            .appendingPathComponent("invalid.invalid.png")
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: file.path),
            "아바타 폴백은 디스크에 저장하지 않음 (오염 방지)"
        )
    }

    func testWebTabCachedFaviconDefaultNil() {
        let tab = WebTab(url: URL(string: "https://example.com")!, order: 0)
        XCTAssertNil(tab.cachedFavicon)
    }
}
