# PLAN v0.3 — 다운로드 진행률 트레이 (상단 배너 + Finder 보기)

> 플랫폼: macos / 상태: 구현 예정 / 기준: PLAN_v0.2 + 사용자 피드백
> 스킬: `macos-app-design` 경유

## 1. 배경 (발견된 문제)

- WKDownload 다운로드는 동작하지만 진행률·취소·완료 확인이 전혀 없어
  "멍 때리는" 경험. `WebContainerView.Coordinator`에서 시작/완료/실패를
  디버그 로그로만 남김.
- 파일명 중복 시 `~/Downloads` 그대로 덮어씀.
- 사용자 결정(2026-09-13): ① 툴바 바로 아래 상단 배너 ② 완료 후 트레이
  유지 + Finder에서 보기.

## 2. 범위

- 포함: `DownloadManager`(진행 수집·취소·중복 이름·보유 상한),
  `DownloadTrayView`(상단 배너), Coordinator 배선(시작/완료/실패/취소),
  attached 패널 + 분리 창 양쪽 적용, unit 테스트, 디버그 로그.
- 제외: blob URL 다운로드(JS 브리지 후속), 일시정지(WKDownload 미지원),
  full/E2E.

## 3. 설계

1. **DownloadManager** (`Sources/Services/DownloadManager.swift`, `@MainActor`)
   - `DownloadItem`: id(UUID), filename, destinationURL, progress(0…1),
     state(downloading/finished/cancelled/failed), errorText.
   - `activeItems`(트레이 표시용) / `items`(최근 5건 유지).
   - `register(download:filename:)` → KVO로 `download.progress.fractionCompleted`.
     WKDownload는 코디네이터별 인스턴스라 Dictionary로 보유.
   - `finish(item)`, `fail(item, error)`, `cancel(item)` → `download.cancel()`.
   - 완료/실패/취소 8초 후 자동 제거(패널이 닫혀도 상태 유지 보장).
   - `uniqueDestination(in:suggested:)`: `이름 (2).ext` 충돌 회피.
2. **DownloadTrayView** (`Sources/Views/DownloadTrayView.swift`)
   - 조건부 표시: 다운로드 중/최근 이벤트 있을 때 36pt 배너.
   - 행: 파일명(1줄) + 상태 아이콘 + 진행 바(또는 퍼센트) + 행동 버튼.
   - 완료: "Finder에서 보기" → `NSWorkspace.shared.activateFileViewerSelecting`.
   - 취소/실패: "닫기". 진행 중: "취소".
3. **배선** (`Views/WebContainerView.swift` Coordinator)
   - `navigationAction/navigationResponse didBecome download` 2곳에서
     `DownloadManager.shared.register`.
   - `decideDestinationUsing`에서 `uniqueDestination` 호출 후 경로 반환.
   - `downloadDidFinish` → `finish`, `didFailWithError` → `NSURLErrorCancelled`
     이면 cancelled, 아니면 failed(`E-MAC-NET-0003`).
4. **적용** (`Views/NotchRootView.swift`)
   - `browserPanel(for:)` VStack: `WebProgressBar` 아래
     `DownloadTrayView` 삽입 (조건부 내부 자체 처리).
   - `DetachedBrowserView` 동일 삽입.

## 4. 에러코드

- `E-MAC-NET-0003`: 다운로드 실패 (기존 0002와 병행, userInfo에 파일명).

## 5. 순서 (게이트 고정)

문서 → DownloadManager → DownloadTrayView → Coordinator 배선 → 뷰 삽입 →
unit 테스트 → xcodebuild build/test → 배포·수동 확인 → swiftlint →
DoD → T-011 close.

## 6. 브랜치·커밋

- 브랜치: `feat/macos-trust-tabs-download` (현행)
- 커밋: `feat(macos): 다운로드 진행률 트레이 (진행·취소·완료 Finder 보기)`