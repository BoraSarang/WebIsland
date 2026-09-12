# AGENTS.local.md — WebIsland 프로젝트 특화 규칙

> 공통 가이드는 `~/.config/opencode/AGENTS.md` 참조. 여기에는 변경·확정 항목만 기록.

## 적용 플랫폼 확정

- 단일 플랫폼: `macos`만. `ios/android/web/chrome/firefox/safari/server` 제외.
- 모노레포·turbo·pnpm 규칙 비적용 (네이티브 단일 앱).
- 네이티브 필수 준수: SwiftUI 주도 + AppKit 예외 (아래).

## 변경 항목 (공통 대비 델타)

1. **AppKit 사용 예외 허용**: 공통은 SwiftUI만이나, 노치 오버레이는
   `NSWindow(level=.screenSaver) + NSScreen.auxiliaryTopLeftArea` 없이는
   구현 불가. `Controllers/`의 윈도우 생성·레벨·호버 추적에 한해 AppKit
   직접 사용 허용. 그 외 UI는 SwiftUI 우선.
2. **번들 ID 확정**: `com.borasarang.WebIsland` (ZIP의 `com.webisland.app` 폐기).
3. **빌드 규격**: `xcodebuild` + Xcode 프로젝트를 정식 산출물로 함.
   SwiftPM(`Package.swift`)은 의존성 병행용으로 유지. `swift build/test` 금지.
   **xcodegen 주의**: 2.45.4가 `resources`를 누락함.
   `xcodegen generate` 후 반드시 `scripts/patch-resources.py` 실행
   (`build_and_run.sh`가 자동 수행 + 가드).
4. **작업 추적 이중화**: `bd`를 정식 진실로 사용. `docs/TODO.md`는
   T-번호 ↔ bd ID 매핑용 패시브 미러 (bd export와 동일 취급).
   에이전트 온보딩은 `bd prime` 직접 실행 (루트 `AGENTS.md`·`CLAUDE.md`는
   2026-09-12 정리 시 삭제 — `bd init` 템플릿이라 프로젝트 규칙 없음).
5. **셸 무한대기 방지**: `cp/mv/rm`은 반드시 `-f` 포함
   (`rm -rf` 재귀). `scp/ssh`는 `-o BatchMode=yes`, `apt-get`은 `-y`.
   (`-i` 별칭 환경에서 y/n 대기로 행(hang) 방지.)

## 플랫폼 추가/제거 시 갱신 대상

- 본 파일 + `docs/AI_MODELS.json` + `docs/plans/PLAN_*` + `build_and_run.sh` 플랫폼 목록.
