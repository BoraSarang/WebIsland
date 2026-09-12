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
| T-007 | WI-n67 | 검증 게이트 (DebugPanel+PERF 실측+E2E) | 대기 |

## 다음 행동

1. `bd update WI-n67 --claim` 후 검증 게이트 (사용자 사용 중이면 headless 사전 확인)
2. 커밋/PR은 사용자 승인 후 (`feat/macos-settings-menu` 분리)
