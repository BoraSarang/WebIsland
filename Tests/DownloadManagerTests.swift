import XCTest
@testable import WebIsland

final class DownloadManagerTests: XCTestCase {
    @MainActor
    func testUniqueDestinationAvoidsCollision() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        FileManager.default.createFile(
            atPath: dir.appendingPathComponent("report.pdf").path,
            contents: Data()
        )
        let manager = DownloadManager.shared

        // 기존 파일과 충돌하면 (n) 접미사.
        let first = manager.uniqueDestination(in: dir, suggested: "report.pdf")
        XCTAssertEqual(first.lastPathComponent, "report (2).pdf")

        // 확장자가 없는 파일명도 그대로 유지.
        let noExt = manager.uniqueDestination(in: dir, suggested: "export")
        XCTAssertEqual(noExt.lastPathComponent, "export")

        // (2)도 이미 있으면 (3)으로 오름.
        FileManager.default.createFile(atPath: first.path, contents: Data())
        let third = manager.uniqueDestination(in: dir, suggested: "report.pdf")
        XCTAssertEqual(third.lastPathComponent, "report (3).pdf")
    }

    /// 완료 rename 캐스케이드: `.download` 임시 파일이 중복 회피된 최종 명으로 이동한다.
    @MainActor
    func testRenameTempToFinal() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        // 기존 최종 파일이 있어 (n) 접미사가 붙어야 하는 상황.
        FileManager.default.createFile(
            atPath: dir.appendingPathComponent("app.dmg").path,
            contents: Data()
        )
        let temp = dir.appendingPathComponent("app.dmg.download")
        try Data("payload".utf8).write(to: temp)

        let final = DownloadManager.shared.uniqueDestination(in: dir, suggested: "app.dmg")
        XCTAssertEqual(final.lastPathComponent, "app (2).dmg")

        try FileManager.default.moveItem(at: temp, to: final)
        XCTAssertFalse(FileManager.default.fileExists(atPath: temp.path))
        XCTAssertEqual(try String(contentsOf: final, encoding: .utf8), "payload")
    }

    func testDurationFormatting() {
        XCTAssertEqual(DownloadTrayView.remainingClockText(0), "0초")
        XCTAssertEqual(DownloadTrayView.remainingClockText(42), "42초")
        XCTAssertEqual(DownloadTrayView.remainingClockText(60), "1분")
        XCTAssertEqual(DownloadTrayView.remainingClockText(65), "1분 5초")
        XCTAssertEqual(DownloadTrayView.remainingClockText(185), "3분 5초")
        XCTAssertEqual(DownloadTrayView.remainingClockText(-5), "0초")
    }

    func testMetaPlaceholders() {
        let fresh = DownloadManager.DownloadItem(filename: "a.dmg")
        XCTAssertEqual(DownloadTrayView.sizeText(for: fresh), "—")
        XCTAssertEqual(DownloadTrayView.speedText(for: fresh), "—")
    }

    /// A안 통합 메타: 1줄 "%" + 2줄 "용량 · 속도 · 남은" 3칸 고정.
    func testMetaLineOrder() {
        var item = DownloadManager.DownloadItem(filename: "VSCode-darwin-arm64.dmg")
        item.progress = 0.36
        item.receivedBytes = 103 * 1_000_000
        item.totalBytes = 283_300_000
        item.speedBytesPerSecond = 16_300_000
        item.remainingSeconds = 11

        XCTAssertEqual(DownloadTrayView.percentText(for: item), "36%")
        let line = DownloadTrayView.metaLine(for: item)
        XCTAssertTrue(line.contains(DownloadTrayView.sizeText(for: item)), "용량 포함: \(line)")
        XCTAssertTrue(line.contains(DownloadTrayView.speedText(for: item)), "속도 포함: \(line)")
        XCTAssertTrue(line.contains(DownloadTrayView.remainingText(for: item)), "남은 시간 포함: \(line)")
        XCTAssertEqual(line.components(separatedBy: " · ").count, 3, "3칸 고정: \(line)")
    }

    func testMetaLinePlaceholders() {
        let fresh = DownloadManager.DownloadItem(filename: "a.dmg")
        XCTAssertEqual(DownloadTrayView.percentText(for: fresh), "0%")
        let line = DownloadTrayView.metaLine(for: fresh)
        XCTAssertTrue(line.hasPrefix("— · — · "), "초기값 플레이스홀더: \(line)")
    }
}
