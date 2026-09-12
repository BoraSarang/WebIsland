# PLAN v0.1 — WebIsland macOS 노치 브라우저 (MVP 스켈레톤 → 빌드 통과)

> 플랫폼: macos / 상태: 초안 / 기준 문서: ZIP 내 PRD·ARCHITECTURE·MENUBAR_GUIDE

## 1. 목표

- 빈 repo → 규칙 트리 재배치 완료 (WI-mg5 닫힘).
- MVP 스켈레톤 빌드 우선: `xcodebuild` 통과 + 노치 호버/확장 + 탭 1개 브라우저 동작 확인.
- 성능 예산: Cold Start ≤1.5s, RSS ≤300MB, 60fps, 캐시 히트 ≥70%.

## 2. 범위 (이번 세션)

- 포함: 문서 일式 (본 파일+TODO+DESIGN+CHANGELOG+AGENTS.local),
  Xcode 프로젝트 생성, 번들ID 전환, xcassets 변환,
  `build_and_run.sh debug macos` smoke 통과,
  스켈레톤 결함 수정안 확정 (TabManager 권장안 포함).
- 제외: V1 전체(단축키·Detached 완성·LaunchAtLogin·프로그레스바),
  full/E2E (커밋/PR 게이트 + 사용자 허락 시).

## 3. 스켈레톤 결함 목록 (수정 예정)

1. `notchRect` y좌표 버그 (0 기준 → 스크린 상단 기준으로 교정).
2. `detachedFrame` 저장 불일치 (`NSRect` 객체 저장 vs `String` 읽기 → `String` 통일).
3. `DetachedPanelController` styleMask 충돌 (`.borderless+.titled` → `.borderless+.nonactivatingPanel`).
4. 글로벌 마우스 모니터 미보관 (해제 누락 → 핸들 보관 + `removeMonitor`).
5. 스로틀 없음 (60fps 스로틀 + 0.3s collapse 타이머 중복 방지).
6. `WebContainerView` 플레이스홀더 → `WKWebView` Representable 실구현.
7. `TabManager` 미싱 → SwiftData 권장안으로 신규 (아래 4장).
8. `WindowMode` 한글 rawValue → 영문 raw + 표시문자열 분리.
9. `FaviconService` JS 1단계·디스크캐시 미싱 → 4단계 + 7일 캐시.
10. `DebugLogger`, `E-MAC-*`, `error_message_ko.json` 미싱.

## 4. TabManager 권장안 (사용자 승인: 권장 방식)

- **SwiftData `@Model WebTab` 유지** (ZIP·PRD·ARCH 일치).
- 이유: 탭=사이트 고정 소량 데이터, 순서·고정·커스텀타이틀 영속에 적합.
  UserDefaults안은 쿼리·마이그레이션에 불리.
- 구성: `TabManager` = SwiftData 영속 + 메모리 `WKWebView` 풀(활성1+캐시2)
  + `WKWebsiteDataStore.default` 공유 (로그인 유지). V2에서 isolated 옵션.
- 풀 밖 탭은 URL만 보관, on-demand 로드 → RSS ≤300MB 달성.

## 5. 순서 (게이트 고정)

문서 작성 → 코드 구현 → smoke+unit(`-only-testing`) →
`./build_and_run.sh debug macos` → DebugPanel 검증(ERROR 0) →
DoD 체크 → bd close.

## 6. 브랜치·커밋

- `chore/macos-init` (문서+재배치) → `feat/macos-build-base`
  → `feat/macos-notch-core`. main 직접 푸시 금지. 1커밋 1관심사.
