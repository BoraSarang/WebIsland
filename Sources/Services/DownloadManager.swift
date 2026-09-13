import Combine
import Foundation
import WebKit

/// WKDownload 진행·취소·완료를 패널 트레이에 반영하는 싱글턴.
/// 이벤트는 Coordinator(didBecome/DownloadFinish/Fail)에서 등록한다.
@MainActor
final class DownloadManager: ObservableObject {
    static let shared = DownloadManager()

    /// 트레이 표시 목록 (다운로딩 + 8초 내 완료/실패/취소). 최신순.
    @Published private(set) var items: [DownloadItem] = []

    /// 활성 다운로드만 (배지/기타 계산용).
    var activeItems: [DownloadItem] {
        items.filter { $0.state == .downloading }
    }

    private var downloadsByID: [UUID: WKDownload] = [:]
    private var observationsByID: [UUID: NSKeyValueObservation] = [:]
    private var destinationsByID: [UUID: URL] = [:]
    private var startedAtByID: [UUID: TimeInterval] = [:]
    private var lastSampleByID: [UUID: (time: TimeInterval, bytes: Int64)] = [:]
    private var scheduledRemovals: [UUID: Task<Void, Never>] = [:]
    /// KVO 원시 샘플 버퍼 (0.5s 폴링에서 일괄 반영 — 초당 수십 회 재렌더 방지).
    private struct ProgressSample {
        var fraction: Double
        var completed: Int64
        var total: Int64
    }
    private var progressBufferByID: [UUID: ProgressSample] = [:]
    private var pollTimer: Timer?

    private init() {}

    // MARK: - 등록 / 진행

    /// 다운로드 시작을 트레이에 등록하고 진행률 KVO를 건다.
    func register(_ download: WKDownload, filename: String) {
        let item = DownloadItem(filename: filename)
        items.insert(item, at: 0)
        downloadsByID[item.id] = download
        startedAtByID[item.id] = ProcessInfo.processInfo.systemUptime

        observationsByID[item.id] = download.progress.observe(
            \.fractionCompleted,
            options: [.initial, .new]
        ) { [weak self] progress, _ in
            Task { @MainActor in
                // KVO는 즉시 화면을 건드리지 않고 버퍼에만 저장 (TubeKeep 폴링 방식).
                self?.bufferProgress(
                    id: item.id,
                    fraction: progress.fractionCompleted,
                    completed: progress.completedUnitCount,
                    total: progress.totalUnitCount
                )
            }
        }

        DebugLogger.feature("Download", "트레이 등록: \(filename)")
        ensurePollTimer()
        trimIfNeeded()
    }

    private func bufferProgress(
        id: UUID,
        fraction: Double,
        completed: Int64,
        total: Int64
    ) {
        progressBufferByID[id] = ProgressSample(
            fraction: fraction,
            completed: completed,
            total: total
        )
    }

    // MARK: - 종료 상태

    /// 완료: `.download` 임시 파일을 최종 이름으로 rename.
    func finish(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              items[index].state == .downloading
        else { return }

        let filename = items[index].filename
        guard let tempURL = destinationsByID[id] else {
            items[index].state = .failed
            items[index].errorText = NSLocalizedString("download.failed", comment: "")
            DebugLogger.error(code: "E-MAC-NET-0002", "임시경로 유실: \(filename)")
            cleanup(id: id)
            scheduleAutoRemove(id: id)
            return
        }

        do {
            let directory = tempURL.deletingLastPathComponent()
            let finalURL = uniqueDestination(in: directory, suggested: filename)
            try FileManager.default.moveItem(at: tempURL, to: finalURL)

            items[index].filename = finalURL.lastPathComponent
            items[index].destinationURL = finalURL
            items[index].state = .finished
            items[index].progress = 1
            DebugLogger.feature("Download", "완료: \(finalURL.lastPathComponent)")
        } catch {
            items[index].state = .failed
            items[index].errorText = error.localizedDescription
            removeTemporaryFile(id: id)
            DebugLogger.error(
                code: "E-MAC-NET-0002",
                "저장 완료 처리 실패: \(filename) (\(error.localizedDescription))"
            )
        }
        cleanup(id: id)
        scheduleAutoRemove(id: id)
    }

    func fail(id: UUID, error: Error) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              items[index].state == .downloading
        else { return }
        if (error as NSError).code == NSURLErrorCancelled {
            items[index].state = .cancelled
            items[index].errorText = NSLocalizedString("download.cancelled", comment: "")
            DebugLogger.feature("Download", "취소됨: \(items[index].filename)")
        } else {
            items[index].state = .failed
            items[index].errorText = error.localizedDescription
            DebugLogger.error(
                code: "E-MAC-NET-0002",
                "다운로드 실패: \(items[index].filename) (\(error.localizedDescription))"
            )
        }
        removeTemporaryFile(id: id)
        cleanup(id: id)
        scheduleAutoRemove(id: id)
    }

    /// 사용자 취소: WKDownload 중단 요청 → didFail(NSURLErrorCancelled)로 상태 전환.
    /// WebKit 취소가 미묘하게 전파되지 않는 케이스에 대비해 Progress도 함께 중단.
    func cancel(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              items[index].state == .downloading,
              let download = downloadsByID[id]
        else { return }
        let filename = items[index].filename
        DebugLogger.feature("Download", "취소 요청: \(filename)")
        download.progress.cancel()
        download.cancel { resumeData in
            Task { @MainActor [weak self] in
                self?.markCancelled(id: id)
            }
            DebugLogger.feature(
                "Download",
                "cancel 콜백 도달: \(filename) (resume=\(resumeData?.count ?? 0) bytes)"
            )
        }
    }

    /// didFail 도달 없이 cancel 콜백만 왔을 때도 상태를 취소로 정리.
    private func markCancelled(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              items[index].state == .downloading
        else { return }
        items[index].state = .cancelled
        items[index].errorText = NSLocalizedString("download.cancelled", comment: "")
        DebugLogger.feature("Download", "취소 확정(콜백): \(items[index].filename)")
        removeTemporaryFile(id: id)
        cleanup(id: id)
        scheduleAutoRemove(id: id)
    }

    // MARK: - 목록 관리

    private func removeTemporaryFile(id: UUID) {
        guard let temp = destinationsByID[id] ?? items.first(where: { $0.id == id })?.temporaryURL
        else { return }
        DownloadFileStore.removeIfExists(at: temp)
    }

    private func cleanup(id: UUID) {
        downloadsByID[id] = nil
        observationsByID[id]?.invalidate()
        observationsByID[id] = nil
        destinationsByID[id] = nil
        startedAtByID[id] = nil
        lastSampleByID[id] = nil
        progressBufferByID[id] = nil
    }

    private func scheduleAutoRemove(id: UUID, after seconds: TimeInterval = 8) {
        scheduledRemovals[id]?.cancel()
        scheduledRemovals[id] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.remove(id: id)
        }
    }

    private func remove(id: UUID) {
        items.removeAll { $0.id == id }
        scheduledRemovals[id]?.cancel()
        scheduledRemovals[id] = nil
        if activeItems.isEmpty { stopPollTimer() }
    }

    /// 완료·실패·취소 항목을 트레이에서 즉시 제거 (닫기 버튼).
    func dismiss(id: UUID) {
        remove(id: id)
    }

    /// WKDownload로부터 등록 시점의 아이템 id를 역검색.
    func itemID(for download: WKDownload) -> UUID? {
        downloadsByID.first(where: { $0.value === download })?.key
    }

    /// decideDestination 시점의 임시 저장 경로를 기록 (WKDownload에 destination API 없음).
    /// 진행 중 표시 파일명은 최종 이름 유지(임시 확장자 미노출).
    func setDestination(_ url: URL, for download: WKDownload) {
        guard let id = itemID(for: download) else { return }
        destinationsByID[id] = url
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].temporaryURL = url
        }
    }

    /// 최근 5건 유지 (다운로딩 항목 포함해 오래된 것부터 제거).
    private func trimIfNeeded() {
        guard items.count > 5 else { return }
        while let last = items.last, items.count > 5 {
            cleanup(id: last.id)
            scheduledRemovals[last.id]?.cancel()
            items.removeLast()
        }
    }

    // MARK: - 0.5s 폴링 (TubeKeep startQueuePolling 방식)

    private func ensurePollTimer() {
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    /// 버퍼된 진행 반영 + 경과 갱신을 한 번에 (초당 2회 재렌더로 고정).
    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        var hasActive = false
        for index in items.indices where items[index].state == .downloading {
            let id = items[index].id
            hasActive = true
            if let sample = progressBufferByID[id] {
                items[index].progress = sample.fraction
                items[index].receivedBytes = sample.completed
                if sample.total > 0 { items[index].totalBytes = sample.total }

                // 속도: 0.5s 폴링 간격 차분을 EMA로 스무딩.
                if let last = lastSampleByID[id] {
                    let interval = now - last.time
                    let delta = sample.completed - last.bytes
                    if interval > 0, delta > 0 {
                        let instant = Double(delta) / interval
                        let prev = items[index].speedBytesPerSecond
                        items[index].speedBytesPerSecond = prev > 0 ? prev * 0.7 + instant * 0.3 : instant
                    }
                    lastSampleByID[id] = (now, sample.completed)
                } else {
                    lastSampleByID[id] = (now, sample.completed)
                }

                let speed = items[index].speedBytesPerSecond
                let total = items[index].totalBytes
                items[index].remainingSeconds = (total > 0 && speed > 0)
                    ? Double(total - sample.completed) / speed
                    : nil
                progressBufferByID[id] = nil
            }
            if let start = startedAtByID[id] {
                items[index].elapsed = now - start
            }
        }
        if !hasActive { stopPollTimer() }
    }

    private func stopPollTimer() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - 저장 경로

    /// 주어진 디렉토리에 중복 파일명이 있으면 `이름 (n).확장자`로 회피.
    /// 실체는 `DownloadFileStore` (호출부 호환용 위임).
    func uniqueDestination(in directory: URL, suggested: String) -> URL {
        DownloadFileStore.uniqueDestination(in: directory, suggested: suggested)
    }
}
