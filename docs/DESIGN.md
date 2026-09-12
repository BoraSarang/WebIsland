# DESIGN.md — WebIsland 디자인 기준안 (승인 요청)

> 스킬 경유: `macos-app-design + ios-the-final-5-percent + apple-design`.
> 기준: "딱 맥 앱 같아야 함". 무단 구현 금지 — 아래 안 승인 후 구현.

## 1. 목업 3종 분석

- `notch-seamless-mockup_*` (약 188KB): 노치 확장 pill + 브라우저 패널 일체형.
  ARCH의 "단일 윈도우, gap 0, 단일 그림자/머티리얼"과 일치. Boring Notch 방식.
- `notch-browser-mockup_*` (약 193KB): 노치 브라우저 동작형. 호버→확장
  인터랙션 레퍼런스로 적합.
- `menubarweb-mockup_*` (약 196KB): 전통 메뉴바 팝오버형. 노치 없는 맥
  폴백용 레퍼런스로 적합.

## 2. 제안 (승인 요청안)

- **기준안: notch-seamless를 Attached 기본으로 채택.**
- notch-browser는 호버/확장 타이밍·파비콘 스트립 레퍼런스로만 참조.
- menubarweb은 `hasNotch==false` 폴백(상태바 팝오버) 전용으로 참조.
- 이유: PRD "Attached(기본)·Seamless" 명시, ARCH 단일윈도우 근거,
  메뉴바 위 오버레이에서 두 윈도우 방식은 그림자·배경이 따로 놀아 티가 남.

## 3. 스펙 (ZIP PRD·ARCH 계승 + 맥 컨벤션 보정)

| Before (ZIP 스켈레톤) | After (제안) | 달라지는 점 |
|---|---|---|
| `notchPill` 180→420×32, radius 16, 검정 단색, 그림자 임의 | pill 180→420×40, `RoundedRectangle(20, continuous)`, 검정으로 하드웨어 노치 커버, 그림자는 패널과 단일로 합성 | 노치가 확장된 것처럼 일체감 있게 보임 |
| `browserPanel` 400×480이 별도 그림자·별도 머티리얼로 분리된 인상 | Attached는 pill+panel을 단일 `Path`·단일 머티리얼(`.hudWindow`/`ultraThinMaterial`)·단일 그림자(0 8 32, 18%)로 합성, gap 0, 화살표 없음 | 두 덩이가 아닌 하나의 덩어리로 자라남 |
| `.onHover`만으로 상태 전환, 무한 재트리거 가능 | hover 진입 즉시 expand, 이탈 시 0.3s 디바운스 후 collapse, 60fps 스로틀, 진입점 `[INFO][FEATURE]` 로그 | 호버 깜빡임이 사라지고 300ms 내 오픈 체감 |
| 탭이 첫글자 `Text`만 표시, 활성 pill 임의 | 탭 32px 높이·파비콘 16px·활성 pill `#E8E8E8`(라이트)/`white 15%`(다크), `+` 버튼, 우클릭 메뉴(이름변경·고정·삭제), `Cmd+1~5` 힌트 툴팁 | 맥 사이드바·툴바 컨벤션과 동일한 밀도·호버·단축키 힌트 |
| `ToolbarView` 버튼 동작 없음, 도메인 고정 텍스트 | 뒤로/앞으로/새로고침 + Omnibox(평소 도메인만, 클릭 시 전체 URL 편집, lock 아이콘) + 2px 프로그레스바 상단 | 브라우저 최소 조작이 메뉴·단축키와 일대일로 대응 |
| Detached가 `.borderless+.titled` 충돌, 그림자·이동 규격 없음 | Detached 패널 400×500, `.borderless+.nonactivatingPanel`, `isMovableByWindowBackground=true`, 위치 `UserDefaults` 저장·복원 | 드래그 이동이 네이티브 플로팅 패널처럼 동작 |
| 메뉴바 클릭 동작·Dock 토글 미배선 | 좌클릭=패널 토글, 우클릭/`Ctrl+클릭`=설정·Dock표시토글·정보·종료. Dock 토글은 `setActivationPolicy(.regular/.accessory)` 즉시 반영 | 메뉴바 앱 규격(템플릿 아이콘 16px, `@2x` 32px) 준수 |
| 설정이 `Form` 임의 크기 | `Settings` 씬, 상단 탭(일반/윈도우모드), 580×420, 컨트롤 우측·라벨 좌측, 저장버튼 없음(`@AppStorage` 즉시 반영) | 시스템 설정과 동일한 폼 리듬 |
| 모션 값만 상수 (`response:0.35`) | spring `response:0.35, dampingFraction:0.75`, 진입 0.42s·복귀 0.32s, `value:` 스코프 지정, `Reduce Motion` 시 크로스페이드 | 끊김·역주행 벽돌벽 없이 인터럽트 가능 |

## 4. 비목표 (이번 세션)

- 풀 브라우저 기능(확장 프로그램), App Store 배포, 워크스페이스·광고차단(V2).

## 5. 승인 요청

1. 기준안을 `notch-seamless`로 확정해도 되나요?
2. 폴백(`hasNotch==false`)을 menubarweb 팝오버로 고정해도 되나요?
3. 탭 활성 pill·Omnibox 규격을 위 표대로 잠가도 되나요?
