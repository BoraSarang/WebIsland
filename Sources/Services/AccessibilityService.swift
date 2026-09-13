import AppKit
import ApplicationServices
import Combine

/// 손쉬운 사용(접근성) 권한 상태·요청. 전역 마우스 모니터(노치 호버)의 전제.
/// 실행마다 시스템 프롬프트를 자동으로 띄우지 않고, 온보딩 버튼을 통해서만
/// 시스템 설정으로 유도한다. (macOS 26 기준 kAXTrustedCheckOptionPrompt 비권장)
enum AccessibilityService {
    /// 현재 권한이 허용되었는지.
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// 시스템 설정의 손쉬운 사용(접근성) 프라이버시 페인을 연다.
    /// 성공 여부를 반환한다.
    @discardableResult
    static func openSystemSettings() -> Bool {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        let opened = NSWorkspace.shared.open(url)
        if opened {
            DebugLogger.feature("Accessibility", "시스템 설정(손쉬운 사용) 열기")
        } else {
            DebugLogger.error(code: "E-MAC-PERM-0003", "시스템 설정 열기 실패")
        }
        return opened
    }

    /// 권한 상태를 1초 폴링 + 시스템 설정 변경 알림으로 알려준다.
    /// 손쉬운 사용 권한을 실행 중에 켜면 `AXIsProcessTrusted()`가 잠시
    /// 이전 값을 반환하므로, 알림 수신 뒤 짧게 지연해 재확인한다.
    static func pollTrusted(interval: TimeInterval = 1.0) -> AnyPublisher<Bool, Never> {
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .map { _ in () }
            .merge(with: Self.distributedChangePublisher)
            .merge(with: Self.activePublisher)
            .prepend(())
            .map { _ in isTrusted }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    /// 시스템 설정(손쉬운 사용) 변경 시 `com.apple.accessibility.api`가 전파된다.
    /// 알림 직후에도 TCC 반영 지연이 있어 짧게 delay한 뒤 재확인한다.
    private static let distributedChangePublisher: AnyPublisher<Void, Never> = {
        let subject = PassthroughSubject<Void, Never>()
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.accessibility.api"),
            object: nil,
            queue: .main
        ) { _ in
            DebugLogger.feature("Accessibility", "권한 변경 알림 수신, 재확인 예약")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                subject.send(())
            }
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            DebugLogger.feature("Accessibility", "접근성 표시 옵션 변경, 재확인 예약")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                subject.send(())
            }
        }
        return subject.eraseToAnyPublisher()
    }()

    /// 앱이 다시 활성화될 때(설정 앱에서 복귀) 즉시 재확인.
    private static let activePublisher: AnyPublisher<Void, Never> = {
        NotificationCenter.default
            .publisher(for: NSApplication.didBecomeActiveNotification)
            .map { _ in () }
            .eraseToAnyPublisher()
    }()
}
