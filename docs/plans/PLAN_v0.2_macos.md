# PLAN v0.2 — 손쉬운 사용 권한 온보딩(랜딩) 창 + 아이콘 배경 교정

> 플랫폼: macos / 상태: 구현 완료(수동 검증 대기) / 기준: PLAN_v0.1 + bd WI-mui 검증 중 발견
> 스킬: `macos-app-design` 경유
>
> ## 0. 추가 수정 (검증 중 발견, 2026-09-13)
>
> - **인증서 프롬프트 오탐**: `WKNavigationDelegate.didReceive`를 구현하면
>   WebKit 기본 신뢰 검증이 대리자 책임으로 대체되므로, 유효한 공개 CA
>   인증서(예: github.com)에도 신뢰 검증 없이 프롬프트가 떴음.
>   `SecTrustEvaluateAsyncWithError` 게이트 추가로 시스템 신뢰 통과 시
>   프롬프트 없이 수락, 실제 검증 실패 시에만 사용자 확인.
>   경고를 클릭할 수 없던 원인: `alert.runModal()`이 노치 팝오버
>   (`.screenSaver` 레벨) 뒤에 가려진 채 이벤트 루프 독점 → ESC까지 무반응.
>   남은 프롬프트는 `alert.window.level=.screenSaver`로 상향.
> - **온보딩 미감지**: `AXIsProcessTrusted()` 1초 폴링만으로는 실행 중 허용을
>   놓칠 수 있어 `com.apple.accessibility.api` 분산 알림(0.2s 지연 재확인)
>   + `didBecomeActive` 병합. 설정 ON 표시에도 미감지되는 원인은 TCC가
>   ad-hoc 서명 CDHash에 바인딩되고 빌드마다 해시가 바뀌기 때문
>   (DerivedData `1ae09085…` ≠ ~/Applications `9646ba3f…`) —
>   현재 바이너리 기준 OFF→ON 재토글로 해결.
> - **랜딩 레이아웃**: 콘텐츠 실측(~368pt)이 360pt 창 초과로 하단 짤림 →
>   480×400으로 확장 + 권한 카드 우측 상태 배지
>   (`badge.granted`=허용됨/`badge.required`=필요함, ko/en).

## 1. 배경 (발견된 문제)

- `AppDelegate.requestAccessibilityPermission()`이 앱 실행 때마다
  `AXIsProcessTrustedWithOptions(prompt: true)`로 시스템 프롬프트를
  즉시 유발 → "실행할 때마다 손쉬운 사용 체크" 처리.
- macOS 26(Tahoe)에서 해당 프롬프트는 안정적이지 않음 → 표준은
  시스템 설정 딥링크.
- 아이콘: `WebIsland.xcassets/AppIcon` 배경이 완전 투명(알파 0)이라
  macOS 26 아이콘 규격(불투명 배경)에 어긋남. 콘텐츠 bbox 822×960.

## 2. 범위

- 포함: `AccessibilityService`(isTrusted/openSystemSettings/폴링),
  온보딩(랜딩) 창(OnboardingView+OnboardingWindowController),
  AppDelegate 자동 프롬프트 제거·온보딩 배선,
  `NotchWindowController.refreshMouseTracking()`,
  AppIcon 10종 흰색 불투명 배경 재생성,
  Localizable `onboarding.*`(ko/en), unit/smoke 통과 확인.
- 제외: 새 탭 안내 페이지 개편, V1 전체, full/E2E.

## 3. 설계

1. **AccessibilityService** (`Sources/Services/AccessibilityService.swift`)
   - `isTrusted`: `AXIsProcessTrusted()`
   - `openSystemSettings()`: `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`
     열고 실패 시 `E-MAC-PERM-0003`.
   - `checkEvery(1s)`: `Timer.publish` 폴링으로 허용 감지 콜백.
2. **OnboardingView** (`Sources/Views/OnboardingView.swift`)
   - 앱 아이콘 96pt(`AppIcon`, RoundedRectangle 마스크) + 타이틀 + 태그라인.
   - 권한 카드 `.regularMaterial` + `RoundedRectangle(12)`:
     SF Symbol `cursorarrow`, 상태별 문구, 다크/라이트 대응.
   - 버튼: "시스템 설정에서 허용"(`.borderedProminent`) + "나중에"(plain).
   - 허용 감지 시 체크 카드 전환 → "시작하기" 활성/자동 닫힘.
3. **OnboardingWindowController** (`Sources/Controllers/OnboardingWindowController.swift`)
   - 480×360 `.titled+.closable` NSWindow, center, `orderFrontRegardless`.
   - `onFinished` 콜백(시작/닫기) 시 `notchWindowController.refreshMouseTracking()`.
4. **AppDelegate**: `applicationDidFinishLaunching`에서 `requestAccessibilityPermission()` 삭제,
   권한 없으면 온보딩 표시. `AXIsProcessTrusted()`가 true면 온보딩 생략.
5. **NotchWindowController**: `refreshMouseTracking()` — monitor 제거 후 재설치.
6. **아이콘**: `AppIcon_1024.png`(보관 원본) 위에 흰색 불투명 배경 →
   10종 규격으로 리사이즈 저장. MenubarIcon은 템플릿 유지(변경 없음).

## 4. 에러코드

- `E-MAC-PERM-0003`: 시스템 설정 열기 실패 (신규).

## 5. 순서 (게이트 고정)

문서 작성 → 코드 구현 → unit/smoke → `./build_and_run.sh debug macos` 대응
build → 수동 실행(권한 없음→랜딩, 허용→전환) → swiftlint → DoD → bd close(T-010).

## 6. 브랜치·커밋

- 브랜치: `feat/macos-trust-tabs-download` (현행) 또는 별도 분기 검토.
- 커밋: `feat(macos): 손쉬운 사용 권한 온보딩 랜딩 창`
  + `chore(macos): AppIcon 불투명 배경 교정` (1커밋 1관심사).