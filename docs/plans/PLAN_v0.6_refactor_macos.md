# PLAN v0.6 — 전체 리팩토링 (P0+P1 + E2E)

> 플랫폼: macos / 상태: Phase 1 완료, Phase 2 대기 / 기준: 3방향 정밀 분석 (2026-09-14)

## 0. 확정 범위

- P0+P1. P2(데드코드·문자열 키화)는 후순위 제외.
- UI 테스트 방침: AppKit 실생성 금지, 순수함수 추출 후 단위 테스트 + E2E(Playwright).

## 1. Phase 0 — 완료 (커밋 대기)

- 0-1 LogStore 단절: `DebugLogger.cache/perf` → `LogStore.append` + `recordCache` 배선,
  `CACHE MISS` 주황색 추가. 히트율 패널 거짓 0% 복구.
- 0-2 크래시 2곳: `WebTab.url` 폴백 + `loadTabs` 손상 탭 제거(`DB-0001`),
  `setupNotchWindow` guard + `UI-0001` (미사용 코드 해소).
- 0-3 무음 실패: `finish` 임시경로 유실·`downloadDidFinish` 매칭 실패에 `NET-0002`.
- 0-4 스펙: PLAN_v0.3 `NET-0003` 폐기 정정, `PERM-0001` json 삭제
  (마우스 감지는 AX 권한 불필요라 실패 분기 없음).
- 0-5 lint: `--fix` + `dt/fm/v2` 개명 + `urls[0]` 3곳 guard + `selectTab` 120자.
  경고 20→11건 (잔여는 Phase 1/2 구조분).
- 주의: `--fix`가 `let _ =` → `_ =`로 바꿔 ViewBuilder 빌드 깨짐 1건 발생 →
  `swiftlint:disable:next`로 원복. 교훈: `--fix` 후 반드시 빌드.
- 게이트: unit 44건 통과, lint error 0, BUILD SUCCEEDED.

## 2. Phase 1 — 중복 제거 (완료)

- 1-1 `BrowserChromeView` 추출 → 별도 파일 (24줄 일치 해소, 430→370줄).
- 1-2 포트 생략 `HostPort` 통합 (`WebTab`·`Toolbar`·`Favicon`) + `HostPortTests` 3건.
- 1-3 `NotchMetrics` 상수화 (40/400/844) + `frame()` 단일 진실. 폴백 팝오버 400×500은 별도 규격 유지.
- 1-4 `HostingViewFactory` (노치·분리·디버그·온보딩). 설정 창은 패턴 상이로 제외.
- 1-5 `onModeChange` 삭제·`AppInfo` 구조체화 (`large_tuple` 해소).
- 게이트: unit 47건 통과, lint error 0 (경고 11→4건, 잔여는 Phase 2 구조분).

## 3. Phase 2 — 책임 분리 (이후)

- 2-1 `Coordinator` → `CertTrustHandler` + `DownloadRouting`.
- 2-2 `HoverTracker` 추출 + `windowMode` 일원화.
- 2-3 `AppDelegate` → `MenuBuilder`·`SettingsWindowFactory`.
- 2-4 `TabManager` → `TabStore`·`WebViewPool`.

## 4. Phase 3 — 테스트 + E2E

- 단위: 풀 경계·상태머신·`clampedFrame`·`LogStore` 링버퍼.
- E2E: 트레이·새창·ESC·분리모드 (headless, workers≤2).

## 5. 브랜치·커밋

- 브랜치: `feat/macos-trust-tabs-download` (현행)
- Phase당 1커밋. Phase 0: `fix(macos): P0 안정화 (로그 단절·크래시·무음실패·lint)`
