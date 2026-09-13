# session-2026-09-13-macos (8줄 요약)

1. 무엇을: 온보딩 랜딩(T-010/WI-361) 구현 + 검증 중 발견 3건 수정
   (인증서 프롬프트 오탐·온보딩 미감지·랜딩 하단 짤림).
2. 플랫폼: macos 단일 (`com.borasarang.WebIsland`, 14.0, xcodebuild).
3. 빌드+PERF+CACHE: BUILD SUCCEEDED, TEST SUCCEEDED (unit 21건),
   swiftlint 변경 4파일 0 violations. perf/cache 영향 없음.
4. 남은TODO: 수동 검증 3종 — ① github.com 무프롬프트 로드+ESC 없이 클릭,
   ② 설정 OFF→ON 재토글 후 랜딩 "허용됨"→시작하기 전환,
   ③ 랜딩 480×400 짤림 해소 확인 → bd close → 푸시·PR.
5. 전달로그: ① 인증서 — didReceive 구현 시 WebKit 기본 검증이 대리자로
   대체되므로 유효 CA에도 프롬프트. `SecTrustEvaluateAsyncWithError` 게이트로
   통과 시 무프롬프트 수락. 클릭 불가는 `runModal`이 팝오버 뒤에 가려
   이벤트 독점(ESC까지 무반응) → alert level `.screenSaver` 상향.
   ② 미감지 — 설정 ON 표시는 구 바이너리(TCC는 ad-hoc CDHash 바인딩,
   빌드마다 변경: DerivedData `1ae09085` ≠ ~/Applications `9646ba3f`).
   현 바이너리 기준 OFF→ON 재토글 필요. 폴링+`accessibility.api`+활성화 병합됨.
   ③ 랜딩 360→400 + 카드 우측 상태 배지(허용됨/필요함).
   검증용 예외 목록 비움 — 백업 `/tmp/wi_trusted_backup.txt`.
6. 문서갱신: PLAN_v0.2(§0 추가)·TODO(T-010 구현 완료 표기)·CHANGELOG 항목.
7. 큐상태: WI-361 진행중. 분기 `feat/macos-trust-tabs-download`, 원격 없음.
8. E2E: smoke 자동 통과. 사용자 사용 중이므로 headless·수동 확인은 사용자 담당.
