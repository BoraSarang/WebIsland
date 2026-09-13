import Foundation

/// 다운로드 상태 (DownloadManager와 트레이가 공유).
enum DownloadState: String {
    case downloading, finished, cancelled, failed
}

/// 트레이 표시용 다운로드 항목.
struct DownloadItem: Identifiable, Equatable {
    let id = UUID()
    /// 진행 중 표시용 최종 파일명 (임시 확장자 미포함).
    var filename: String
    /// `.download` 임시 경로 (decideDestination 결정).
    var temporaryURL: URL?
    /// 완료 후 최종 저장 경로 (Finder 보기용).
    var destinationURL: URL?
    var progress: Double = 0
    var state: DownloadState = .downloading
    var errorText: String?

    // 진행 메타
    var totalBytes: Int64 = 0
    var receivedBytes: Int64 = 0
    var speedBytesPerSecond: Double = 0
    var remainingSeconds: Double?
    var elapsed: TimeInterval = 0
}
