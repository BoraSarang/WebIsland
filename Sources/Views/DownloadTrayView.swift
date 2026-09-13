import SwiftUI

/// 다운로드 진행/완료/취소/실패를 툴바 아래에 표시하는 상단 배너.
/// 아이템이 하나도 없으면 레이아웃 공간을 차지하지 않는다.
struct DownloadTrayView: View {
    @ObservedObject private var manager = DownloadManager.shared

    var body: some View {
        if !manager.items.isEmpty {
            VStack(spacing: 0) {
                ForEach(manager.items) { item in
                    DownloadRow(item: item)
                }
            }
            .background(Color.black.opacity(0.35))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - 포맷 헬퍼 (순수 함수, 단위 테스트 대상)

    static func byteText(_ count: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: count, countStyle: .file)
    }

    /// 1분 미만은 초만, 이상은 분·초 (42 → "42초", 185 → "3분 5초").
    static func remainingClockText(_ seconds: Double) -> String {
        let totalSec = max(0, Int(seconds))
        let min = totalSec / 60
        let sec = totalSec % 60
        if min == 0 { return "\(sec)초" }
        if sec == 0 { return "\(min)분" }
        return "\(min)분 \(sec)초"
    }

    /// 종류별 칸 표시용 값 (고정 폭 셀에 들어가 자릿수 변화가 레이아웃에 영향 없음).
    static func sizeText(for item: DownloadItem) -> String {
        if item.totalBytes > 0 {
            return "\(byteText(item.receivedBytes)) / \(byteText(item.totalBytes))"
        } else if item.receivedBytes > 0 {
            return byteText(item.receivedBytes)
        }
        return "—"
    }

    static func speedText(for item: DownloadItem) -> String {
        guard item.speedBytesPerSecond > 0 else { return "—" }
        return "\(byteText(Int64(item.speedBytesPerSecond)))/s"
    }

    static func remainingText(for item: DownloadItem) -> String {
        let value = item.remainingSeconds.map(remainingClockText) ?? "--"
        return String(format: NSLocalizedString("download.remaining", comment: ""), value)
    }

    static func percentText(for item: DownloadItem) -> String {
        "\(Int(item.progress * 100))%"
    }

    /// 2줄 통합 메타 한 줄: "용량 · 속도 · 남은" (우측 정렬용, %는 1줄 우측).
    static func metaLine(for item: DownloadItem) -> String {
        "\(sizeText(for: item)) · \(speedText(for: item)) · \(remainingText(for: item))"
    }
}

private struct DownloadRow: View {
    let item: DownloadItem

    var body: some View {
        if item.state == .downloading {
            downloadingBody
        } else {
            settledBody
        }
    }

    private var clampedProgress: Double {
        max(0, min(1, item.progress))
    }

    // MARK: - 진행 중 (파일명 + 통합 메타 한 줄 + 하단 얇은 바, A안)

    private var downloadingBody: some View {
        ZStack(alignment: .bottomLeading) {
            // 1줄 파일명에 최대폭 양보, 2줄 메타 우측 한 줄 통합이라 중간 텀 없음.
            // ✕는 바깥 HStack 세로중앙이라 위·아래 어색함 없음.
            HStack(spacing: 8) {
                statusIcon
                VStack(alignment: .leading, spacing: 2) {
                    // 1줄: 파일명(최대폭) + % 우측.
                    HStack(spacing: 6) {
                        Text(item.filename)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(DownloadTrayView.percentText(for: item))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text(DownloadTrayView.metaLine(for: item))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                cancelButton
                    .padding(4)
                    .contentShape(Rectangle())
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .padding(.bottom, 8)

            // 행 바닥 고정 2pt 바: 폭 자체는 레이아웃과 무관(값만 갱신)이라 깜빡임 없음.
            // 0.5s 폴링 사이를 linear로 메워 끊김 없이 이어진다.
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.accentColor.opacity(0.2))
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geo.size.width * clampedProgress)
                    .animation(.linear(duration: 0.45), value: item.progress)
            }
            .frame(height: 2)
        }
    }

    // MARK: - 완료/취소/실패 (1줄)

    private var settledBody: some View {
        HStack(spacing: 8) {
            statusIcon
            Text(item.filename)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
            if item.state == .finished {
                Button {
                    if let url = item.destinationURL {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                } label: {
                    Label(
                        NSLocalizedString("download.showInFinder", comment: ""),
                        systemImage: "magnifyingglass"
                    )
                    .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else if let text = item.errorText {
                Text(text)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Button {
                DownloadManager.shared.dismiss(id: item.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .frame(height: 36)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch item.state {
        case .downloading:
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        case .finished:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(.green)
        case .cancelled:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundStyle(.red)
        }
    }

    private var cancelButton: some View {
        Button {
            DownloadManager.shared.cancel(id: item.id)
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help(NSLocalizedString("download.cancel", comment: ""))
    }
}
