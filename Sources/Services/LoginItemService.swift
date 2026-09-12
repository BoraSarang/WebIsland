import Foundation
import ServiceManagement

/// 로그인 시 자동 실행 (SMAppService 직접 사용 — 외부 의존성 없음).
enum LoginItemService {
    static var isEnabled: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                DebugLogger.feature("LoginItem", "자동 실행: \(newValue)")
            } catch {
                DebugLogger.error(code: "E-MAC-PERM-0002", "자동 실행 변경 실패: \(error.localizedDescription)")
            }
        }
    }
}
