# E2E PLAN — WebIsland macos

> 브라우저 재사용 불가(네이티브 앱), 병렬 ≤2, headless 우선.
> full은 커밋/PR 게이트 + 사용자 허락 시. 시간 예산 smoke ≤2분.

## TC-SMOKE-001 앱 실행·노치 pill 표시 (자동)

1. `pkill WebIsland`, 실행 파일 직접 기동.
2. 10초 내 Quartz 윈도우 목록에 WebIsland 윈도우 1개 (180~440×40, 상단).
3. 프로세스 종료. 기대: 타임아웃 없음.

## TC-SMOKE-002 단축키 기본값 등록 (자동)

1. 실행 후 `defaults read com.borasarang.WebIsland`에
   `KeyboardShortcuts_togglePanel`(⌘⇧W), `KeyboardShortcuts_debugPanel`(⌘⇧D) 존재.

## TC-MAN-001 호버·확장·패널 (수동, 스크린샷 첨부)

1. 노치 호버 → 420+ pill + 파비콘 좌우 분할 (노치 뒤 가림 없음).
2. 클릭 → 440×520 패널 + 실페이지 로드.
3. `⌘⇧W` 토글, 우클릭 메뉴, `⌘⇧D` 디버그 패널.

## TC-MAN-002 옴니박스·새 탭 (수동)

1. `+` → 안내 페이지 + 자동 포커스, 입력·엔터 이동.
2. `⌘V` 붙여넣기·`⌘A` 선택 동작.

## 부하 (해당 시, 사용자 미사용 중에만)

- k6 해당 없음 (로컬 앱). PERF 게이트로 대체: Cold Start ≤1.5s, RSS ≤300MB.
