# CHANGELOG

## [Unreleased] — macos

- [macos] 노치 코어: `NotchDetector`(y좌표 수정·순수함수 분리),
  `DebugLogger`([FEATURE]/[ERROR]/[PERF]/[CACHE]),
  `TabManager`(SwiftData+WKWebView풀 LRU 3+공유스토어),
  `WebContainerView`(WKWebView 실구현+2px 프로그레스),
  `FaviconService`(디스크캐시 7일+아바타 분리),
  `WindowMode` 영문화, Detached styleMask·프레임통일, 모니터핸들+60fps스로틀.
  관련 `E-MAC-DB-0001/E-MAC-NET-0001/E-MAC-VALID-0001`. unit 5건 통과,
  swiftlint error 0. RSS 실측은 다음 단계.
- 문서 우선 일式 추가 (PLAN_v0.1_macos, TODO, DESIGN 초안, AGENTS.local).
  perf/cache 영향 없음.
- ZIP 해제·규칙 트리 재배치 (`WebIsland/` 래퍼 → 루트 `Sources/Resources/Assets/Mockups`).
  perf/cache 영향 없음.
- [macos] 빌드 토대: `project.yml`+xcodegen으로 `WebIsland.xcodeproj` 생성,
  번들ID `com.borasarang.WebIsland`, 배포타깃 14.0 (SwiftData 요구),
  xcassets 변환(AppIcon 1024·MenubarIcon 템플릿 16/32),
  `build_and_run.sh`+`env-expiry-check.sh` 추가. `BUILD SUCCEEDED` 확인.
  관련 에러코드 없음. perf/cache 영향 없음.
- [macos] 빌드 수정: `notchRect` Optional 언래핑 (SDK에서
  `auxiliaryTopLeftArea/RightArea`가 Optional). perf/cache 영향 없음.
- [macos] 린트 부채 (다음 단계로 이월): `SettingsView` line-length error 1건,
  trailing-whitespace 경고 다수. perf/cache 영향 없음.
- [macos] 정리: 루트 `AGENTS.md`·`CLAUDE.md` 삭제 (`bd init` 템플릿, 프로젝트 규칙
  없음). 셸 무한대기 방지 규칙은 `AGENTS.local.md` 5항으로 이관.
  `bd` CLI 정상 동작 확인. perf/cache 영향 없음.

## 형식 규칙

- 항목마다 platform 태그(`[macos]`) + 관련 `E-MAC-*` + perf/cache 영향 기록.
