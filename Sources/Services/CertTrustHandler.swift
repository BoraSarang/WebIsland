import Cocoa
import Foundation
import Security
import WebKit

/// 사설 인증서 챌린지 처리 (기억된 예외 + 사설IP 자동 신뢰 + 사용자 확인).
/// `WebContainerView.Coordinator`의 WK delegate에서 호출. UI(`NSAlert`) 격리.
/// 정책 결정은 `CertTrustService` 단일 진실.
final class CertTrustHandler {
    func handle(
        challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        let host = challenge.protectionSpace.host
        if CertTrustService.trustedHosts().contains(host) {
            DebugLogger.info("인증서 예외 적용(기억됨): \(host)")
            completionHandler(.useCredential, URLCredential(trust: trust))
            return
        }
        if CertTrustService.isPrivateIP(host) {
            CertTrustService.remember(host: host)
            DebugLogger.feature("CertTrust", "사설IP 자동 신뢰: \(host)")
            completionHandler(.useCredential, URLCredential(trust: trust))
            return
        }
        // WKNavigationDelegate로 didReceive를 구현하면 WebKit의 기본 신뢰
        // 검증이 대리자 책임으로 대체된다. 시스템 체인에 유효한 인증서
        // (예: github.com)는 프롬프트 없이 수락하고, 실제 검증에 실패한
        // 인증서만 사용자 확인으로 보낸다.
        // SecTrustEvaluate*는 네트워크(중간 CA/해지) 접근이 가능하므로
        // 메인 런루프 대신 백그라운드에서 동기 검증한다.
        // (SecTrustEvaluateAsyncWithError는 메인 호출 시 내부 큐 assert로
        // 크래시하므로 사용하지 않는다.)
        DispatchQueue.global(qos: .userInitiated).async {
            var evalError: CFError?
            let trusted = SecTrustEvaluateWithError(trust, &evalError)
            DispatchQueue.main.async {
                if trusted {
                    DebugLogger.feature("CertTrust", "시스템 신뢰 통과: \(host)")
                    completionHandler(.useCredential, URLCredential(trust: trust))
                } else {
                    DebugLogger.feature("CertTrust", "신뢰 검증 실패, 사용자 확인: \(host)")
                    self.askToTrust(host: host, trust: trust, completionHandler: completionHandler)
                }
            }
        }
    }

    private func askToTrust(
        host: String,
        trust: SecTrust,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("certrust.title", comment: "")
        alert.informativeText = String(
            format: NSLocalizedString("certrust.message", comment: ""),
            host
        )
        alert.addButton(withTitle: NSLocalizedString("certrust.continue", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("certrust.cancel", comment: ""))
        // 노치 패널은 `.screenSaver` 레벨이라 기본 알림은 뒤에 가려진다.
        // 경고를 팝오버 위로 올려 사용자 확인이 가능하도록 한다.
        alert.window.level = .screenSaver
        if alert.runModal() == .alertFirstButtonReturn {
            CertTrustService.remember(host: host)
            DebugLogger.feature("CertTrust", "사용자 확인 신뢰: \(host)")
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            DebugLogger.info("인증서 신뢰 거부됨: \(host)")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
