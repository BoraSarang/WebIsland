# PLAN v0.5 — Final 아이콘 교체 (3분 초안)

> 플랫폼: macos / 상태: 교체 진행 / 기준: `WebIsland_Selected_Icon_Final.zip`

## 1. 배경

- 기존 공식 아이콘(3D 섬+브라우저 창)을 플랫 야자섬 Final로 교체.
- zip 실측: `AppIcon.iconset/icon_512x512@2x.png` == `AppIcon_Light_1024.png` →
  선택본은 Light(흰 불투명 배경 + 검정섬). T-010 불투명 요구와 일치.
- 메뉴바: `Black/*` == `MenubarIcon_Template*` 동일 파일 확인 →
  Black 하나만 + `isTemplate=true`(코드·xcassets 이미 설정)로 라이트/다크 자동 대응.

## 2. 범위

- 포함: `AppIcon.appiconset` 10종(Light 계열),
  `MenubarIcon.imageset` 18/36(Black 다운스케일),
  원본 보관(`Assets/Icons/Final_*`), CHANGELOG.
- 제외: 코드 변경 없음(`isTemplate`·`template-rendering-intent` 유지),
  Dark/White/Transparent 변형 미적용.

## 3. 방법

- AppIcon: zip iconset 6종 복사 + 누락 4종(32·32@2x·256·256@2x)은
  `AppIcon_Light_1024.png`에서 `sips -z` 생성.
- Menubar: `Black/MenubarIcon_20.png` → 18, `Black/MenubarIcon_32.png` → 36
  (`sips -z`, 다운스케일이라 깨끗). `Contents.json` 손대지 않음.
- 게이트: `test macos unit` + `build macos` + 재시작 후 Dock·메뉴바 육안.

## 4. 브랜치·커밋

- 브랜치: `feat/macos-trust-tabs-download` (현행)
- 커밋: `feat(macos): Final 아이콘 교체 (Dock Light + 메뉴바 Black 템플릿)`
