import XCTest
@testable import WebIsland

final class DownloadFileStoreTests: XCTestCase {
    private func makeTempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func testUniqueDestinationAvoidsCollision() {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        FileManager.default.createFile(
            atPath: dir.appendingPathComponent("report.pdf").path,
            contents: Data()
        )

        let first = DownloadFileStore.uniqueDestination(in: dir, suggested: "report.pdf")
        XCTAssertEqual(first.lastPathComponent, "report (2).pdf")

        let noExt = DownloadFileStore.uniqueDestination(in: dir, suggested: "export")
        XCTAssertEqual(noExt.lastPathComponent, "export")
    }

    func testRemoveIfExistsDeletesFile() throws {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let target = dir.appendingPathComponent("temp.download")
        try Data("x".utf8).write(to: target)

        XCTAssertTrue(DownloadFileStore.removeIfExists(at: target))
        XCTAssertFalse(FileManager.default.fileExists(atPath: target.path))
    }

    func testRemoveIfExistsMissingReturnsFalse() {
        let dir = makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        XCTAssertFalse(
            DownloadFileStore.removeIfExists(at: dir.appendingPathComponent("none.download"))
        )
    }
}
