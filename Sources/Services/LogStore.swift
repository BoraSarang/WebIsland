import Combine
import Foundation

/// 인메모리 로그 링버퍼 + 캐시 카운터. DebugPanel(⌘⇧D) 표시용.
/// os_log에는 저장되지 않는 info 레벨도 여기서 확인 가능.
final class LogStore: ObservableObject {
    static let shared = LogStore()

    struct Entry: Identifiable {
        let id = UUID()
        let time: Date
        let level: String
        let message: String
    }

    private let lock = NSLock()
    private var buffer: [Entry] = []
    private let maxEntries = 200

    @Published private(set) var revision = 0
    @Published var cacheHits = 0
    @Published var cacheMisses = 0
    @Published var poolSize = 0

    var entries: [Entry] {
        lock.lock()
        defer { lock.unlock() }
        return buffer
    }

    var hitRate: Double {
        let total = cacheHits + cacheMisses
        guard total > 0 else { return 0 }
        return Double(cacheHits) / Double(total)
    }

    func append(level: String, message: String) {
        lock.lock()
        buffer.append(Entry(time: Date(), level: level, message: message))
        if buffer.count > maxEntries {
            buffer.removeFirst(buffer.count - maxEntries)
        }
        lock.unlock()
        DispatchQueue.main.async { [weak self] in
            self?.revision += 1
        }
    }

    func recordCache(hit: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if hit {
                self.cacheHits += 1
            } else {
                self.cacheMisses += 1
            }
        }
    }
}
