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
| T-009 | WI-mui | 인증서·탭·다운로드·분리모드·아이콘 | 구현 완료·검증 대기 |

## 다음 행동 (다음 세션 우선순위)

1. 실행 후 창 미표시 원인 확정 (프레임워크 매핑은 되나 윈도우 0개).
   `WIProbe` 파일 추적 또는 Console unified log로 `show()` 이후 추적.
2. TC-MAN + LAN 3종 (탭 전환·다운로드·인증서·분리모드) 수동 검증.
3. 원격 설정 시 푸시·PR (현재 9개 분기, 미푸시).
