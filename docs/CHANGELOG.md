# CHANGELOG

## [Unreleased] — macos

- [macos] P0 안정화 (리팩토링 Phase 0):
  캐시 패널 단절 수정 (`DebugLogger.cache/perf` → `LogStore` 배선, 히트율 거짓 0% 복구).
  크래시 2곳 방어 (`WebTab.url` 폴백 + 손상 탭 제거, `NSScreen.main` guard).
  무음 실패 2곳에 `E-MAC-NET-0002` 추가. `E-MAC-PERM-0001` 폐기
  (마우스 감지는 AX 권한 불필요), PLAN_v0.3 `NET-0003` 정정.
  lint 경고 20→11건. unit 44건 통과, lint error 0. perf/cache 영향 없음.
- [macos] 리팩토링 Phase 1 (중복 제거):
  `BrowserChromeView` 추출(노치/분리 24줄 일치 해소, 430→370줄),
  포트 생략 `HostPort` 통합 + 테스트 3건, `NotchMetrics` 상수화,
  `HostingViewFactory`, `onModeChange` 삭제·`AppInfo` 구조체화.
  unit 47건 통과, lint error 0 (경고 11→4건). perf/cache 영향 없음.
- [macos] 리팩토링 Phase 2 (책임 분리):
  `CertTrustHandler`·`DownloadRouting`·`HoverTracker`·`MenuBuilder`·
  `SettingsWindowFactory`·`WebViewPool` 추출 + `windowMode` 일원화.
  테스트 7건 신규 (`DownloadRouting` 3·`HoverTracker` 4).
  unit 54건 통과, lint error 0 (경고 4→2건). perf/cache 영향 없음.

- [macos] Final 아이콘 교체 (T-012):
  3D 공식 아이콘 → 플랫 야자섬 Final(Light: 흰 불투명 배경 + 검정섬).
  `AppIcon.appiconset` 10종(zip 6종 + 1024에서 32·64·256·512 생성),
  메뉴바는 Black → 18/36 다운스케일 2종만 + `isTemplate`·template intent 유지로
  라이트/다크 자동 대응. 원본 4종 `Assets/Icons/Final_*` 보관.
  unit 44건 통과, lint error 0. perf/cache 영향 없음.

- [macos] 새창 열기 지원 (`target=_blank`·`window.open` → 새 탭):
  원인: `WKUIDelegate` 미설정이라 새창 요청이 조용히 버려짐.
  `WebContainerView`에 `uiDelegate` 배선 + `createWebViewWith` 구현 —
  http(s)만 `addTab(urlString:)`으로 새 탭 오픈, 팝업 웹뷰 미생성(중복 로드 없음).
  주소 없는 팝업(`window.open('')`·blob)은 무시 + 로그, `window.close()`는 로그만.
  노치 패널·분리모드 둘 다 배선. `WebContainerViewTests` 3건 신규.
  unit 44건 통과, lint error 0. perf/cache 영향 없음.
- [macos] 다운로드 트레이 완성형 + 노치 융합 + 설정 푸터 (T-011/PLAN_v0.4):
  트레이: 1줄 `파일명 + % 우측`, 2줄 `용량 · 속도 · 남은` 우측 정렬 한 줄 통합(A안) —
  고정폭 컬럼 삭제라 중간 텀·들쑥날쑥 제거, ✕는 두 줄 세로중앙.
  임시파일: `decideDestination` → `<최종이름>.download` + 완료 시 rename,
  취소/실패 시 삭제(best-effort), 중복은 `이름 (n).확장자` 회피.
  노치: pill + 패널 단일 검정 컨테이너(배경·외곽·그림자 1개) + 패널 창 가득(440),
  웹뷰 430으로 확대.
  설정 하단: 번들에서 읽은 앱 이름·버전 + GitHub 링크(공개 저장소 `BoraSarang/WebIsland`).
  ESC: 로컬 키 모니터(keyCode 53, 텍스트 편집 중 통과) + `PanelWindow.cancelOperation`.
  닫기: 툴바 ✕ + 분리모드 메뉴바 토글(열려 있으면 닫기). 제목: 옴니박스 사이트 제목 표시.
  관련 `E-MAC-NET-0002` 유지. unit 44건 통과, lint error 0. perf/cache 영향 없음.

- [macos] 실행 바이너리 이중화 해소 + 클릭 계측:
  `~/Applications` 복사본이 구 빌드(00:01)라 수정 사항 없이 동작·크래시
  재현되던 문제 → 현행 빌드로 교체, 양쪽 dylib 지문 일치 확인.
  노치 탭 제스처·선택·포커스 결과에 계측 로그 추가 (DebugPanel 판독용).
  unit 30건 통과, lint error 0. perf/cache 영향 없음.
- [macos] 탭매니저 공유·동일호스트 구분 (분리모드 불일치·동일 파비콘):
  원인 확정 (DB 실측): 3개 탭이 전부 `10.36.188.13`(8443/3000/3001) —
  같은 호스트=같은 파비콘은 정상. 분리모드는 TabManager 3중복
  (노치/분리/팝오버 각 @StateObject, activeTabID·풀 독립)이 원인.
  `NotchWindowController.tabManager` 단일 소유 + 3곳 주입
  (노치/분리/폴백), 미사용 `DetachedPanelController` 삭제.
  동일 호스트 구분: `WebTab.portBadge`(443/80 생략) 미니 배지 + 툴팁 전체 URL.
  `WebTabTests` 3건 신규. unit 30건 통과, lint error 0. perf/cache 영향 없음.
- [macos] 설정 크래시·분리모드·파비콘 수정:
  크래시: 설정 창 닫기 후 재오픈 시 EXC_BAD_ACCESS (단순 NSWindow가
  `isReleasedWhenClosed` 기본값으로 닫힘 → 강한 참조 댕글링).
  설정·디버그 창에 `isReleasedWhenClosed=false` (온보딩 창과 동일).
  관련 `E-MAC-*` 없음. unit 27건 통과, lint error 0.
  분리모드: ① `setupDetachedWindow` 반복 생성으로 플로팅 창 누적 →
  기존 창 재사용 가드. ② `NotchRootView.windowMode`가 init 시점 고정값이라
  전환 후에도 노치가 구 모드로 동작 → `NotchViewModel.windowMode`
  @Published 실시간 구독. ③ 확장 포커스가 노치로만 가던 문제 →
  분리모드에서는 detached 창을 키로. perf/cache 영향 없음.
  파비콘: ① 아바타 폴백이 디스크 캐시(TTL 7일)를 오염시켜 일시적 실패가
  7일간 실제 아이콘을 가림 → 폴백은 메모리만 저장 + 디렉토리
  `favicons-v2`로 버전범프(구 오염 무효화). ② JS link icon이 CDN 호스트
  키로 저장·버려지고 로드 후 갱신이 없던 데드 경로 → 페이지 호스트 키 저장
  + `wiFaviconDidUpdate` 발행, `WebTab.cachedFavicon`(@Transient) 우선 표시.
  ③ ICO 디코딩 ImageIO 폴백(`decodeImage`, macOS 26 NSImage도 ICO 처리하나
  안전망 유지). `FaviconServiceTests` 6건 신규. perf/cache 영향 없음.
  접근성: 분산 알림 옵저버 토큰 미보관(즉시 해제 무음 버그) → 유지.
  perf/cache 영향 없음.

- [macos] 온보딩 랜딩 수정 + 인증서 프롬프트 근본 수정 (WI-361):
  인증서: didReceive 대리자가 WebKit 기본 신뢰 검증을 대체하므로 유효한
  공개 CA 인증서(예: github.com)에도 프롬프트가 떴던 문제 수정.
  `SecTrustEvaluateAsyncWithError` 게이트 추가로 시스템 신뢰 통과 시
  프롬프트 없이 수락, 실제 검증 실패 시에만 사용자 확인.
  남은 프롬프트는 `alert.window.level=.screenSaver`로 팝오버 뒤 가림 해소.
  관련 `E-MAC-NET-*` 없음(기존 코드 재사용). unit 21건 통과, lint error 0.
  온보딩: 1초 폴링 + `com.apple.accessibility.api` 분산 알림(0.2s 지연 재확인)
  + `didBecomeActive` 병합으로 실행 중 허용 즉시 감지.
  랜딩 창 480×360→400(하단 짤림 해소), 권한 카드 우측 상태 배지
  (`onboarding.status.badge.granted/required` ko/en) 추가.
  미감지 원인 확정: 설정 ON 표시는 이전 바이너리(TCC는 ad-hoc 서명 CDHash
  바인딩, 빌드마다 변경) — 현재 바이너리 기준으로 OFF→ON 재토글 필요.
  perf/cache 영향 없음.
- [macos] 창 미표시 원인 확정·수정 (WI-mui 검증):
  `PanelWindow`가 NSWindow 기반인데 `.nonactivatingPanel`(0x80) styleMask 사용 →
  AppKit가 거부 (`NSWindow does not support nonactivating panel styleMask 0x80`).
  `NSPanel` 서브클래스로 전환 + `hidesOnDeactivate=false` (오버레이 상주).
  검증 시 소유자명 필터 교훈: CGWindowList의 owner는 CFBundleDisplayName
  ("웹 아일랜드")이라 "WebIsland" 필터로 0개 오인 — "웹 아일랜드"로 매칭.
  실행 검증: idle pill 292×40 @ (754,0), layer=1000(screenSaver), onscreen=true.
  unit 21건 통과, lint error 0. perf/cache 영향 없음.
- [macos] 인증서·탭·다운로드·분리모드·아이콘 (WI-mui, 검증 대기):
  사설IP 자동 신뢰 + 예외 기억 (`CertTrustService`, `certrust.*` 키),
  `NSAllowsLocalNetworking`, 탭 전환 `.id()` 교체 + 파비콘탭 펼치기
  (부모 토글 억제), 다운로드 action 정책 + blob 판별 로그,
  분리모드 실시간 전환 (NotificationCenter) + 패널 표시 보장,
  공식 아이콘 세트 적용 (AppIcon full set, Menubar 18pt template,
  `CFBundleIconName`, 원본 `Assets/Icons` 보관).
  unit 21건 통과, lint error 0. 실행 후 창 미표시 잔여 이슈 있음 (다음 세션 우선).
- [macos] 실행 안정화: `LSMinimumSystemVersion` 숫자 기입 크래시
  (`<real>` → `"14.0"` 문자열, project.yml 단일 진실) 수정.
  호버 렌더 재진입 크래시 수정 (상태 변경을 다음 런루프로).
  xcodegen 리소스 누락 → pbxproj 수동 등록 (lproj+xcassets+knownRegions ko).
  unit 18건 통과, lint error 0. idle pill 정상 표시 확인.
- [macos] 스트링 통일·설정 Form: 하드코딩 한글 제거
  (`menu.newTab/tab.close/tab.pin/tab.unpin/omnibox.*` 키 추가, 한·영).
  상태바 메뉴와 `…` 메뉴 동일 키 사용. 설정 화면 grouped Form +
  header/footer 정리 + 단축키 `LabeledContent` 행. unit 18건 통과, lint error 0.
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
