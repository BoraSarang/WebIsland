# PLAN v0.4 — 다운로드 임시파일·메타 / ESC 확정 / 창 닫기 / 사이트 제목

> 플랫폼: macos / 상태: 구현 진행 / 기준: PLAN_v0.3 + 사용자 테스트 피드백
> 스킬: `macos-app-design` 경유

## 1. 배경 (사용자 피드백, 2026-09-13)

- **다운로드 파일명**: `decideDestination`에서 최종 파일명 그대로 저장 → 완료 전에
  `.download` 임시 파일로 받다가 완료 시 rename하고, 취소/실패 시 **삭제** 필요.
- **메타 정보**: 진행바는 만족, 용량·속도·남은 시간·경과 시간 표시 필요.
- **ESC 미동작**: SwiftUI `.onExitCommand`가 웹뷰 ESC 소비로 불리지 않음.
  → 로컬 키 모니터로 ESC를 가로채 "메뉴바 클릭과 같은 앱 함수 호출" 방식.
- **플로팅/패널 닫기**: ESC가 안 되면 닫을 방법이 없음 → 툴바 ✕ 버튼 +
  메뉴바 아이콘 클릭(플로팅 토글) 필요.
- **주소 표시**: 옴니박스에 URL 대신 **사이트 제목** 표시(클릭 시 편집 유지).

## 2. 범위

- 포함(DownloadManager): 임시 파일 명 로직(finish rename / 취소·실패 삭제),
  메타 트래킹(용량·속도 EMA·남은 시간·경과), cancel 콜백 정리.
- 포함(WebContainerView): `decideDestination` → `<최종이름>.download`.
- 포함(DownloadTrayView): 2줄(진행 바 + 메타) 레이아웃.
- 포함(ESC): NotchWindowController 로컬 키 모니터 + PanelWindow.cancelOperation.
- 포함(닫기): ToolbarView ✕ 버튼, AppDelegate 메뉴바 플로팅 토글(열면 닫기).
- 포함(제목): ToolbarView `webView.publisher(for: \.title)` → 페이지 제목 표시.
- 제외: blob 다운로드, 중단/재개(resumeData), 다운로드 폴더 선택.

## 3. 설계

### 3.1 DownloadManager
- `DownloadItem` 확장: `temporaryURL`, `totalBytes`, `receivedBytes`,
  `speedBytesPerSecond`, `remainingSeconds`, `elapsed`.
- `register`: `startedAt` 기록 + 1초 클록 타이머(다운로딩 항목 경과 갱신) 기동.
- KVO: `fractionCompleted` + 진행 시점의 `completedUnitCount/totalUnitCount` →
  receivedBytes/totalBytes 갱신. 스피드는 0.5s 단위 차분을 EMA(0.7/0.3)로 스무딩.
- `finish(id:)`: 최종 명 `uniqueDestination`(중복 회피) → `FileManager.moveItem`
  (임시→최종) → filename/최종 경로 갱신. 실패 시 임시 삭제 + failed.
- `fail(id:)`/`markCancelled`: `.download` 임시 파일 삭제(best-effort),
  이미 상태 전환됐으면 두 번째 무시(guard `.downloading`).
- `setDestination`: 임시 경로 기록, 진행 표시 파일명은 **최종 이름** 유지
  (`.download` 붙지 않음).

### 3.2 WebContainerView
- `decideDestination`: `suggested + ".download"`를 `uniqueDestination`으로
  충돌 회피 → `completionHandler(tempURL)`.

### 3.3 DownloadTrayView
- 다운로딩 행 48pt: 1줄 = 아이콘·파일명·%·✕(취소) / 2줄 = 진행 바 +
  `용량 · 속도 · 남은시간 · 경과`.
- 완료/취소/실패는 기존 36pt 한 줄 유지.
- 포맷 헬퍼(순수 함수, 테스트 대상): `ByteCountFormatter` + 시간 표기.

### 3.4 ESC 닫기
- `NSEvent.addLocalMonitorForEvents(.keyDown)`로 keyCode 53 감지.
  - `NSApp.keyWindow?.firstResponder is NSTextField`면 그대로 통과(편집 취소).
  - expanded 또는 detached 창 visible이면 `dismissPanel()` + 이벤트 소비(nil).
- `PanelWindow.cancelOperation` override로 보조(웹뷰 비포커스 케이스).

### 3.5 닫기 버튼 / 메뉴바 토글
- `ToolbarView`에 `onDismiss` 클로저, ellipsis 옆 ✕ 버튼 → `dismissPanel()`.
- `NotchWindowController.toggle()`: detached 모드에서 visible이면 닫기
  (orderOut + hovered), 아니면 열기. attached는 기존.

### 3.6 사이트 제목
- `ToolbarView`: `@State pageTitle`, `webView.publisher(for: \.title)` 반영.
- 미편집 상태 버튼 라벨 = `pageTitle.isEmpty ? displayHostPort : pageTitle`.
- 클릭 시 기존대로 `draft = url.absoluteString` 편집 진입. 새 탭 힌트 유지.

## 4. 에러코드

- `E-MAC-NET-0002` 유지: 다운로드 실패(rename 실패 포함, userInfo는 로그로).

## 5. 순서 (게이트 고정)

문서 → DownloadManager → Coordinate/decideDestination → DownloadTrayView →
ESC 모니터 → 닫기 버튼·토글 → 사이트 제목 → unit → build/test → 배포·수동 확인→
swiftlint → DoD → T-011 close.

## 6. 브랜치·커밋

- 브랜치: `feat/macos-trust-tabs-download` (현행)
- 커밋: `feat(macos): 다운로드 임시파일·메타 크레이 + ESC/닫기 + 사이트 제목`
  (관심사 분리 가능 시 2개로: download / esc-close-title)