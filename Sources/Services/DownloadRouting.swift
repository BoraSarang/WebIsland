import Foundation
import WebKit

/// 다운로드 라우팅 순수 로직 (파일명 추림 + 임시 경로).
/// WK delegate 배선은 `WebContainerView.Coordinator`에 남기고,
/// 테스트 가능한 결정 로직만 여기로. 단위 테스트 대상.
enum DownloadRouting {
    /// action 경로 파일명 (없으면 전체 URL, 그것도 없으면 "파일").
    static func actionFilename(request: URLRequest) -> String {
        request.url?.lastPathComponent
            ?? request.url?.absoluteString
            ?? "파일"
    }

    /// response 경로 파일명 (suggested 우선).
    static func responseFilename(response: URLResponse) -> String {
        response.suggestedFilename
            ?? response.url?.absoluteString
            ?? "파일"
    }

    /// 완료 전까지 쓸 임시 `.download` 경로 (중복 회피 포함).
    /// `DownloadManager`가 `@MainActor`라 호출처도 메인이어야 한다.
    @MainActor
    static func tempURL(suggestedFilename: String) -> URL {
        let base = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return DownloadManager.shared.uniqueDestination(
            in: base,
            suggested: "\(suggestedFilename).download"
        )
    }
}
