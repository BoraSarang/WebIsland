import Foundation
import os

/// DebugPanel·로그 게이트용 구조화 로거. 모든 로그는 이 경유 필수.
enum DebugLogger {
    private static let log = Logger(
        subsystem: "com.borasarang.WebIsland",
        category: "app"
    )

    /// 신규 기능 진입점 로그 (기능당 1개 이상 의무).
    static func feature(_ name: String, _ message: String = "진입") {
        log.info("[INFO] [FEATURE] \(name, privacy: .public) — \(message, privacy: .public)")
        LogStore.shared.append(level: "FEATURE", message: "\(name) — \(message)")
    }

    static func info(_ message: String) {
        log.info("[INFO] \(message, privacy: .public)")
        LogStore.shared.append(level: "INFO", message: message)
    }

    /// 실패 경로 로그. 에러코드 + `error_message_ko.json` 메시지 매핑.
    static func error(code: String, _ message: String) {
        log.error("[ERROR] \(code, privacy: .public) \(message, privacy: .public)")
        LogStore.shared.append(level: "ERROR", message: "\(code) \(message)")
    }

    static func perf(_ message: String) {
        log.info("[PERF] \(message, privacy: .public)")
    }

    static func cache(hit: Bool, _ message: String) {
        log.info("[CACHE] \(hit ? "HIT" : "MISS", privacy: .public) \(message, privacy: .public)")
    }
}
