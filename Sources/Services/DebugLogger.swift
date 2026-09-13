import Foundation
import os

/// DebugPanel·로그 게이트용 구조화 로거. 모든 로그는 이 경유 필수.
/// os_log와 별개로 `~/Library/Caches/WebIsland/debug.log`에 누적 기록해
/// os_log 로그 수집이 꺼진 환경에서도 확인이 가능하다.
enum DebugLogger {
    private static let log = Logger(
        subsystem: "com.borasarang.WebIsland",
        category: "app"
    )

    private static let logFileLock = NSLock()
    private static let logFileURL: URL = {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let dir = base.appendingPathComponent("WebIsland", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("debug.log")
    }()

    /// 시스템 로그 수집이 꺼진 환경 대비 파일 기록 (진단용).
    private static func appendFile(_ line: String) {
        logFileLock.lock()
        defer { logFileLock.unlock() }
        let stamp = ISO8601DateFormatter().string(from: Date())
        let entry = "[\(stamp)] \(line)\n"
        guard let data = entry.data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: logFileURL) {
            do {
                _ = try handle.seekToEnd()
                handle.write(data)
                try handle.close()
            } catch {
                // 파일 기록 실패는 로그 기능 자체를 막지 않는다.
            }
        } else {
            try? data.write(to: logFileURL)
        }
    }

    /// 신규 기능 진입점 로그 (기능당 1개 이상 의무).
    static func feature(_ name: String, _ message: String = "진입") {
        log.info("[INFO] [FEATURE] \(name, privacy: .public) — \(message, privacy: .public)")
        appendFile("[INFO] [FEATURE] \(name) — \(message)")
        LogStore.shared.append(level: "FEATURE", message: "\(name) — \(message)")
    }

    static func info(_ message: String) {
        log.info("[INFO] \(message, privacy: .public)")
        appendFile("[INFO] \(message)")
        LogStore.shared.append(level: "INFO", message: message)
    }

    /// 실패 경로 로그. 에러코드 + `error_message_ko.json` 메시지 매핑.
    static func error(code: String, _ message: String) {
        log.error("[ERROR] \(code, privacy: .public) \(message, privacy: .public)")
        appendFile("[ERROR] \(code) \(message)")
        LogStore.shared.append(level: "ERROR", message: "\(code) \(message)")
    }

    static func perf(_ message: String) {
        log.info("[PERF] \(message, privacy: .public)")
        appendFile("[PERF] \(message)")
        LogStore.shared.append(level: "PERF", message: message)
    }

    static func cache(hit: Bool, _ message: String) {
        log.info("[CACHE] \(hit ? "HIT" : "MISS", privacy: .public) \(message, privacy: .public)")
        appendFile("[CACHE] \(hit ? "HIT" : "MISS") \(message)")
        LogStore.shared.recordCache(hit: hit)
        LogStore.shared.append(level: hit ? "CACHE HIT" : "CACHE MISS", message: message)
    }
}
