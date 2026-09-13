# PLAN v0.8 — P2 잔여 (데드코드·설정키·폴링 전환)

> 플랫폼: macos / 상태: 완료 / 기준: PLAN_v0.6 제외 항목 실측 (2026-09-14)

## 1. 실측 결과

- `TabManager.moveTab`: 호출 0·테스트 0 → 삭제.
- `DownloadItem.elapsed` + tick 기록: 읽기 0 (트레이 미표시) → 삭제.
- 아바타(`AvatarGenerator`): `FaviconService` 폴백 + 테스트 사용 중 → 제외.
- WebTab 미사용 3종 (`customTitle`·`faviconURLString`·`createdAt`):
  `@Model` 스키마 변경 → 마이그레이션 위험으로 제외 (유지).
- 설정 키 문자열 흩어짐: `showInDock`×5·`launchAtLogin`×2·`windowMode`×2 →
  `AppSettingsKeys` 상수화. Notification은 확장 상수済み·`detachedFrameKey`도
  factory 상수済み라 제외.
- 폴링: `Timer.scheduledTimer` + Task 홉 → `Task.sleep` 루프 (동작 동일).

## 2. 범위

- Phase A: moveTab 삭제·elapsed 삭제·`AppSettingsKeys` 신설 + 전수 교체.
- Phase B: `pollTimer` → `pollTask` 전환 (`tick` 본체 유지).
- 제외: 아바타·WebTab 스키마·FaviconService 분리·문자열 현지화 키화.

## 3. 위험·주의

- `@AppStorage(상수)` Fernandez 컴파일 확인 (문자열 리터럴 아니어도 됨).
- Task 루프: `Task.isCancelled` + `try? sleep` 종료 조건, `stopPollTimer`는
  cancel + nil. `remove`·`tick` 무활성 시 동일 호출 유지.
- SwiftData 스키마 손대지 않음 (마이그레이션 불필요).

## 4. 게이트

- lint error 0 → unit → build → e2e smoke → 1커밋·푸시·재시작.

## 5. 결과

- `moveTab`·`elapsed`(+`startedAtByID`) 삭제, `AppSettingsKeys` 4종 + 10곳 교체.
- `pollTimer` → `pollTask` 전환 (`tick` 본체 유지). `@AppStorage(상수)` 컴파일 확인.
- lint error 0 + 경고 0 유지, unit 63건 통과, BUILD SUCCEEDED, E2E smoke 4/4.
