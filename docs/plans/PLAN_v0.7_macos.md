# PLAN v0.7 — 잔여 type_body 경고 2건 해소 (후속 이월분)

> 플랫폼: macos / 상태: 완료 / 기준: PLAN_v0.6 §4 잔여 경고

## 1. 배경

- PLAN_v0.6에서 `DownloadManager`·`NotchWindowController` type_body 경고 2건을
  파일 I/O·윈도우 공장 분리로 해소하기로 이월함.
- 현 수치: `DownloadManager` body 271줄, `NotchWindowController` body 278줄
  (상한 250줄, lint error 0·경고 2건).

## 2. 범위

- 포함: `DownloadState`·`DownloadItem` → `Sources/Models/DownloadItem.swift`,
  파일 I/O (`uniqueDestination`·임시 삭제) → `Sources/Services/DownloadFileStore.swift`,
  노치/분리 윈도우 생성 → `Sources/Controllers/NotchWindowFactory.swift`
  (분리 프레임 복원/clamp는 순수함수).
- 포함: 신규 단위 테스트 (FileStore 3건·프레임 clamp 2건).
- 제외: P2 나머지 (문자열 키화·폴링→AsyncSequence·데드코드 정리).

## 3. 설계

- API 유지: `DownloadManager.uniqueDestination`은 1줄 위임 래퍼로 유지 —
  `DownloadRouting`·`DownloadManagerTests` 호출부 무변경.
- `removeTemporaryFile(id:)`는 `DownloadFileStore.removeIfExists` 호출로 대체 후 삭제.
- Factory는 `PanelWindow` 생성 + `HostingViewFactory` 배선 + detached 이동 관찰자까지
  가져감. Controller는 `notchWindow`·`detachedWindow` 보유 + 얇은 위임만.
- `frame(for:...)` 순수함수·테스트는 Controller에 유지.

## 4. 게이트

- `swiftlint` error 0 + 경고 0 → `test macos unit` → `build macos` →
  `e2e macos smoke` → 재시작 → 1커밋·푸시.

## 5. 결과

- `DownloadManager` body 271→220줄대, `NotchWindowController` 278→220줄대.
  lint error 0 + 경고 0 (잔여 2건 해소).
- `DownloadManager.DownloadItem` 참조 10곳 → 최상위 `DownloadItem`으로 정리
  (`DownloadTrayView`·`DownloadManagerTests`, 동작 동일).
- unit 63건 통과 (기존 58 + `DownloadFileStore` 3·`NotchWindowFactory` 2),
  BUILD SUCCEEDED, E2E smoke 4/4.
