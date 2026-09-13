import Cocoa
import Foundation

/// 노치 호버 감지 상태머신 (60fps 스로틀 + 0.3초 접기 디바운스).
/// NSEvent 모니터 생명주기는 컨트롤러 담당, 진입/이탈 판단만 여기로.
/// 핫패스라 의도적 무음 (로그 금지). 단위 테스트 대상.
final class HoverTracker {
    /// 호버 진입 (idle → hovered 반영용).
    var onEnter: () -> Void = {}
    /// 호버 이탈 디바운스 만료 (hovered → idle 반영용, expanded면 무시).
    var onExit: () -> Void = {}

    private var lastCheck = CFAbsoluteTime(0)
    private var collapseWorkItem: DispatchWorkItem?

    /// 매 mouseMoved마다 호출. 지오메트리만 받아 판단한다.
    func track(mouse: NSPoint, panelFrame: NSRect?, notch: NSRect?, state: NotchViewModel.State) {
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastCheck >= 1.0 / 60.0 else { return }
        lastCheck = now

        guard let notch else { return }
        if NotchDetector.isHover(mouse: mouse, notch: notch) {
            collapseWorkItem?.cancel()
            collapseWorkItem = nil
            if state == .idle {
                onEnter()
            }
        } else if let panelFrame, !panelFrame.contains(mouse) {
            scheduleCollapse()
        }
    }

    func cancel() {
        collapseWorkItem?.cancel()
        collapseWorkItem = nil
    }

    private func scheduleCollapse() {
        collapseWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.onExit()
        }
        collapseWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: item)
    }

    deinit {
        collapseWorkItem?.cancel()
    }
}
