import Foundation

/// 다운로드 파일 I/O (DownloadManager type_body 분리의 파일 담당).
/// FileManager 직접 호출만 모았고 상태 변경은 호출자가 한다.
enum DownloadFileStore {
    /// 주어진 디렉토리에 중복 파일명이 있으면 `이름 (n).확장자`로 회피.
    static func uniqueDestination(in directory: URL, suggested: String) -> URL {
        let fileManager = FileManager.default
        let base = (suggested as NSString).deletingPathExtension
        let ext = (suggested as NSString).pathExtension
        var candidate = directory.appendingPathComponent(suggested)
        var suffix = 2
        while fileManager.fileExists(atPath: candidate.path) {
            let name = ext.isEmpty
                ? "\(base) (\(suffix))"
                : "\(base) (\(suffix)).\(ext)"
            candidate = directory.appendingPathComponent(name)
            suffix += 1
        }
        return candidate
    }

    /// 존재하면 삭제하고 결과 반환 (best-effort, 실패는 로그만).
    @discardableResult
    static func removeIfExists(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        do {
            try FileManager.default.removeItem(at: url)
            DebugLogger.feature("Download", "임시 파일 삭제: \(url.lastPathComponent)")
            return true
        } catch {
            DebugLogger.info("임시 파일 삭제 실패: \(url.lastPathComponent) (\(error.localizedDescription))")
            return false
        }
    }
}
