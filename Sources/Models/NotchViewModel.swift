import Cocoa
import Combine

/// 노치 상태 단일 진실. 컨트롤러(윈도우 프레임)와 뷰(콘텐츠)가 공유.
/// 물리 노치 뒤에 가려지지 않도록 모든 너비는 실측 노치 너비 기준.
final class NotchViewModel: ObservableObject {
    enum State {
        case idle
        case hovered
        case expanded
    }

    @Published var state: State = .idle
    /// 실측 물리 노치 너비 (기본값은 14형 실측 220).
    @Published var notchWidth: CGFloat = 220
    /// 창 모드. 구조체 init 시점이 아닌 실시간 값으로 뷰가 구독한다.
    /// (모드 전환 후에도 노치가 구 모드로 동작하던 버그 수정)
    @Published var windowMode: WindowMode = .attached

    /// 양옆 가시 영역 36씩 확보.
    var idleWidth: CGFloat { notchWidth + 72 }
    /// 양옆 가시 영역 110씩 확보 (최소 420).
    var expandedWidth: CGFloat { max(420, notchWidth + 220) }
    /// 탭 스트립 중앙 비움 (노치 + 여유 16).
    var centerGap: CGFloat { notchWidth + 16 }
}
