import Cocoa
import SwiftUI

/// 디버그 패널 컨트롤러 (⌘⇧D 플로팅 윈도우).
final class DebugPanelController {
    static let shared = DebugPanelController()
    private var panel: NSPanel?

    func toggle() {
        if let panel, panel.isVisible {
            panel.orderOut(nil)
            return
        }
        show()
    }

    func show() {
        DebugLogger.feature("DebugPanel", "열기")
        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            panel.title = "WebIsland Debug"
            // 설정 창과 동일한 over-release 크래시 방지.
            panel.isReleasedWhenClosed = false
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces]
            let hosting = HostingViewFactory.make(
                rootView: DebugPanelView(),
                size: NSSize(width: 560, height: 420)
            )
            panel.contentView = hosting
            panel.setFrame(NSRect(x: 0, y: 0, width: 560, height: 420), display: false)
            panel.center()
            self.panel = panel
        }
        panel?.makeKeyAndOrderFront(nil)
    }
}

struct DebugPanelView: View {
    @ObservedObject private var store = LogStore.shared
    @State private var selection = Set<UUID>()
    @State private var copied = false

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    var body: some View {
        // revision 구독용 (entries는 스냅샷 반환). ViewBuilder라 선언문 필요.
        // swiftlint:disable:next redundant_discardable_let
        let _ = store.revision
        VStack(spacing: 8) {
            HStack {
                Text("캐시 히트율: \(Int(store.hitRate * 100))%")
                    .font(.system(size: 12, weight: .semibold))
                Text("(HIT \(store.cacheHits) / MISS \(store.cacheMisses))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("웹뷰 풀: \(store.poolSize)/3")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Button(copied ? "복사됨" : "선택 복사") {
                    copySelection()
                }
                .help("선택한 줄 복사 (⌘⇧D 패널)")
            }
            List(selection: $selection) {
                ForEach(store.entries) { entry in
                    HStack(alignment: .top, spacing: 8) {
                        Text(Self.formatter.string(from: entry.time))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .frame(width: 76, alignment: .leading)
                        Text(entry.level)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(levelColor(entry.level))
                            .frame(width: 74, alignment: .leading)
                        Text(entry.message)
                            .font(.system(size: 11))
                            .textSelection(.enabled)
                    }
                    .tag(entry.id)
                }
            }
            .listStyle(.plain)
        }
        .padding(12)
        .frame(minWidth: 560, minHeight: 420)
    }

    private func levelColor(_ level: String) -> Color {
        switch level {
        case "ERROR": return .red
        case "FEATURE": return .blue
        case "PERF": return .purple
        case "CACHE HIT": return .green
        case "CACHE MISS": return .orange
        default: return .secondary
        }
    }

    private func copySelection() {
        let lines: [LogStore.Entry]
        if selection.isEmpty {
            lines = store.entries
        } else {
            lines = store.entries.filter { selection.contains($0.id) }
        }
        let text = lines.map {
            "\(Self.formatter.string(from: $0.time)) [\($0.level)] \($0.message)"
        }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copied = false
        }
    }
}
