import Foundation

/// 사설 인증서 신뢰 정책 (1+2 결합).
/// - 사설IP(localhost·10/8·172.16/12·192.168/16·127/8): 자동 신뢰 + 예외 목록에 기록.
/// - 그 외 호스트: 사용자 확인 후 예외 목록에 기록, 이후 자동 신뢰.
enum CertTrustService {
    private static let exceptionsKey = "trustedCertHosts"

    /// 테스트 주입용 저장소.
    static var store: UserDefaults = .standard

    static func trustedHosts() -> Set<String> {
        Set(store.stringArray(forKey: exceptionsKey) ?? [])
    }

    static func remember(host: String) {
        var hosts = trustedHosts()
        guard hosts.insert(host).inserted else { return }
        store.set(Array(hosts), forKey: exceptionsKey)
        DebugLogger.info("인증서 예외 기억: \(host)")
    }

    static func isPrivateIP(_ host: String) -> Bool {
        let lower = host.lowercased()
        if lower == "localhost" {
            return true
        }
        let parts = lower.split(separator: ".")
        guard parts.count == 4 else { return false }
        var octets: [Int] = []
        for part in parts {
            guard let value = Int(part), (0 ... 255).contains(value) else { return false }
            octets.append(value)
        }
        if octets[0] == 10 || octets[0] == 127 {
            return true
        }
        if octets[0] == 192, octets[1] == 168 {
            return true
        }
        if octets[0] == 172, (16 ... 31).contains(octets[1]) {
            return true
        }
        return false
    }
}
