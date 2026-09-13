# PLAN v0.9 — 디스플레이 네임 현지화 (T-016)

> 플랫폼: macos / 상태: 완료 / 기준: `AGENTS/development/macos-localization.md`

## 1. 원인 (가이드 대조)

- `LSHasLocalizedDisplayName` 누락 → macOS가 `InfoPlist.strings` 무시 중.
- `CFBundleDisplayName "Web Island"` vs 번들 `WebIsland.app` 불일치 →
  Finder가 strings 시도조차 안 함.
- strings en/ko는 `DisplayName`+`Name` 둘 다 보유済み.

## 2. 범위

- `Info.plist`: `CFBundleDisplayName`·`CFBundleName` → `WebIsland`,
  `LSHasLocalizedDisplayName = true` 추가.
- `project.yml` properties 동일 반영 (xcodegen 정합성).
- strings 파일 무변경 (en `Web Island`·ko `웹 아일랜드` 유지).
- 부수: 설정 푸터 `AppInfo.name` 표시용 `Web Island` 고정 분리
  (번들값이 `WebIsland`로 바뀌므로, 기존 테스트 2건 그대로 통과).

## 3. 검증

- 빌드된 `Info.plist` 3개 키 + `ko.lproj/InfoPlist.strings` 포함 확인.
- `mdls -name kMDItemDisplayName` (현재 언어 기준).
- 기존 게이트 (lint·unit·build·e2e smoke).
- 시스템 언어 전환 후 Dock/Finder 표시는 수동 확인.

## 4. 게이트

- lint error 0 → unit → build → mdls/strings 검증 → e2e smoke → 1커밋·푸시·재시작.

## 5. 결과

- 빌드 산출물: `CFBundleDisplayName`·`CFBundleName` = `WebIsland`,
  `LSHasLocalizedDisplayName` = true, en/ko strings 포함.
- `mdls -name kMDItemDisplayName` = `웹 아일랜드` (한국어 환경).
- lint 0·unit 63건·BUILD SUCCEEDED·E2E smoke 4/4.
- 남은 수동 확인: 시스템 언어 영문 전환 시 Dock/Finder `Web Island` 표시.
