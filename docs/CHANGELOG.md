# CHANGELOG

## [Unreleased] — macos

- [macos] 웹뷰 390 인셋·다운로드·JS: 패널 400 안에 웹 390 중앙 배치 (좌우 5px).
  JS 명시 활성화 + 헤드리스 실행 테스트로 확인. `WKDownloadDelegate`로
  표시 불가 MIME → `~/Downloads` 저장 (`E-MAC-NET-0002` 추가).
  unit 18건 통과, lint error 0.
- [macos] 검증 게이트: DebugPanel(`⌘⇧D` 플로팅, 로그 선택복사·캐시 히트율·풀
  표시), 탭 고정/해제 + 고정 탭 닫기 보호. PERF 실측 Cold Start
  0.89/0.50/0.42s (예산 ≤1.5s ✓), RSS 79MB idle (예산 ≤300MB ✓).
  E2E smoke 자동 통과 (TC-SMOKE-001/002). unit 17건 통과, lint error 0.
- [macos] 새 탭 안내 페이지 + 편집 단축키: `+` 버튼은 `about:blank` 기반
  안내 페이지("주소를 입력하세요", 스키마 변경 없음) + 주소창 자동 편집 진입.
  MainMenu 프로그래밍 구축(App/Edit/Window)으로 `⌘C/V/X/A/Z`·우클릭 편집 동작.
  unit 16건 통과, lint error 0.
- [macos] 호버·툴바·옴니박스 수정: S2 301 폴백 탓에 파비콘 실패 →
  faviconV2 직접 호출 + 아바타 이미지 폴백(캐시 저장), 페이지 `link[rel=icon]`
  판독(JS 1단계) 추가. `…` 빈 버튼 → 메뉴(새 탭/설정)로 배선.
  `.nonactivatingPanel` 키 불가로 TextField·단축키 데드 → `PanelWindow`
 (`canBecomeKey`) 도입. unit 14건 통과, lint error 0.
- [macos] 노치 표시·단축키 수정: 600 고정 윈도우 탓에 pill이 화면 밖 렌더됨.
  상태별 윈도우 프레임 리사이즈(idle 180·hover 420·확장 420×520)로 변경,
  상태를 `NotchViewModel`로 중앙집중, 메뉴·단축키 toggle이 실제로 펼치도록 수정.
  프레임 순수함수 단위 테스트 4건 추가. unit 14건 통과, lint error 0.
  Quartz 검증 (180×40, 상단 표시). perf/cache 영향 없음.
- [macos] 실행 치명 버그 수정: Main nib 없이 `@main` 델리게이트가 연결되지 않아
  `didFinishLaunching` 미실행 (윈도우 0개). `main.swift`에서 델리게이트 직접 연결.
  `NSHostingView` 자동 맞춤(`sizingOptions`)으로 오버레이가 180×40으로
  축소되던 문제 수정 + 프레임 명시 고정. Quartz 윈도우 목록으로 검증
  (1800×600, layer 1000). perf/cache 영향 없음.
- [macos] 설정/메뉴바: 상태바 좌클릭 토글·우클릭 메뉴(설정/Dock토글/정보/종료),
  Dock 표시 전환, 전역 단축키 `⌘⇧W`(KeyboardShortcuts)+설정 내 Recorder,
  노치 없는 맥 폴백 팝오버, 설정창·About 배선. `LaunchAtLogin` 패키지 대신
  `SMAppService` 직접 사용 (패키지 클론 stall 회피, 의존성 1개 감소).
  `E-MAC-PERM-0002` 추가. unit 10건 통과, lint error 0.
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
