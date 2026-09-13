# TODO — WebIsland (bd 미러, 정식 진실은 `bd list`)

> bd ID ↔ T-번호 매핑. 상태 변경은 `bd update/close`가 정식.

| T-번호 | bd ID | 내용 | 상태 |
|---|---|---|---|
| T-001 | WI-mg5 | ZIP 해제·폴더 재구성 | 완료 |
| T-002 | WI-0et | 문서 우선 일式 (PLAN/TODO/DESIGN/CHANGELOG/AGENTS.local) | 완료 |
| T-003 | WI-iwe | 목업 3종 분석·기준안 제안 및 승인 | 완료 (seamless·폴백·규격 승인) |
| T-004 | WI-c4q | 빌드 토대 (Xcodeproj+번들ID+xcassets+build_and_run.sh) | 완료 |
| T-005 | WI-6h0 | 노치 코어 (감지+호버+Attached+WKWebView풀+TabManager+Favicon) | 완료 |
| T-006 | WI-jcp | 설정/메뉴바 (Dock토글+자동실행+단축키+우클릭+폴백) | 완료 |
| T-007 | WI-n67 | 검증 게이트 (DebugPanel+PERF 실측+E2E) | 완료 (full E2E 수동분은 사용자 테스트로 대체) |
| T-008 | WI-ovj | 웹뷰 390 인셋·다운로드·JS 확인 | 완료 |
| T-009 | WI-mui | 인증서·탭·다운로드·분리모드·아이콘 | 완료 (수동 검증 통과, bd close) |
| T-010 | WI-361 | 손쉬운 사용 권한 온보딩 랜딩 창 + AppIcon 불투명 배경 | 완료 (수동 검증 통과, bd close) |
| T-011 | — | 다운로드 진행 트레이 v2 (임시파일 rename/삭제·용량/속도/남은/경과) + ESC 닫기 확정 + 툴바 ✕·메뉴바 플로팅 토글 + 사이트 제목 표시 | 완료 (수동 검증 통과) |
| T-012 | — | Final 아이콘 교체 (Dock Light 계열 10종 + 메뉴바 Black 템플릿 18/36) | 완료 (수동 검증 통과) |
| T-013 | — | 전체 리팩토링 P0+P1+E2E | PLAN_v0.6 작성, Phase 2 완료 (게이트 통과) |

## 다음 행동 (다음 세션 우선순위)

1. ~~실행 후 창 미표시 원인 확정~~ → **완료**: `PanelWindow`가 NSWindow인데
   `.nonactivatingPanel` 사용 → AppKit 거부. NSPanel 서브클래스로 수정.
   (진단 함정: CGWindowList owner는 "웹 아일랜드" — "WebIsland" 필터는 0개 오인)
2. TC-MAN + LAN 3종 (탭 전환·다운로드·인증서·분리모드) 수동 검증.
3. 원격 설정 시 푸시·PR (현재 9개 분기, 미푸시).
