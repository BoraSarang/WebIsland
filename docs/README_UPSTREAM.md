# Web Island - macOS Notch Browser

> 노치가 다이나믹 아일랜드가 되어 브라우저가 되는 메뉴바 앱

## 한줄 정의
Web Island는 MacBook 노치에 마우스를 가져가면 좌우로 펼쳐지고, 클릭하면 노치 아래에 미니 브라우저가 Seamless하게 자라나는 메뉴바 브라우저. 탭 1개 = 사이트 1개.

## 이름
**Web Island** - 노치 속의 섬, 웹의 섬

## 핵심 UX
1. **IDLE**: 노치 안에 현재 사이트 파비콘 작게 펄스
2. **HOVER**: 노치 180px -> 420px로 확장, 파비콘 탭 스트립 표시
3. **EXPANDED**: 노치에서 브라우저 패널이 하나의 덩어리로 자라남 (gap 0)
4. **DETACHED (설정)**: 브라우저 패널을 떼어서 자유 이동 가능

## 두 가지 윈도우 모드 (설정)
- **Attached (기본)**: 노치와 브라우저가 하나의 윈도우, 하나의 모양. Seamless.
- **Detached**: 노치(탭 스트립) + 브라우저(플로팅 윈도우) 분리. 브라우저 위치 기억.

## 기술 스택
- macOS 13+ Ventura, Swift 5.9, SwiftUI + AppKit Hybrid
- WKWebView Pool (활성 1개 + 캐시 2개)
- NSScreen.auxiliaryTopLeftArea로 노치 프레임 감지
- NSWindow.level = .screenSaver로 메뉴바 위에 오버레이
- Global mouse monitor로 호버 감지 (Accessibility 권한 필요)

## 프로젝트 구조
- Sources/Controllers: NotchWindowController, DetachedPanelController
- Sources/Models: WebTab
- Sources/Services: FaviconService, TabManager
- Sources/Views: Notch views, Browser views
- Assets/Icons: App Icon
- Mockups: Interactive HTML mockups
- docs/: PRD, Architecture, AI Prompt

## 빌드
Xcode 15+, SwiftPM or Xcode project. LSUIElement = true (Dock 아이콘 없음)

## 아이콘
Assets/Icons/AppIcon_1024.png - 투명 배경, 노치 + 브라우저 + 섬 컨셉

## Naming (로컬라이제이션)

- **English Official**: Web Island
  - Tagline: Your browser in the notch
  - Nickname: Iceland Web
  - Bundle: com.webisland.app

- **한국어 공식**: 웹 아일랜드
  - 부제: 노치 속 작은 브라우저
  - 별칭: 아이슬렌드 웹 (재미있는 별명, 검색 키워드로 유지)
  - Bundle Display Name은 시스템 언어에 따라 자동 전환

### Localization Files
- `Resources/en.lproj/InfoPlist.strings` -> Web Island
- `Resources/ko.lproj/InfoPlist.strings` -> 웹 아일랜드
- `Resources/en.lproj/Localizable.strings` / `ko.lproj/Localizable.strings` -> 메뉴, 설정 전부 현지화

Xcode에서 Localization 추가: Project > Info > Localizations > + Korean

메뉴바 툴팁 예시:
- EN: Web Island - Your browser in the notch
- KO: 웹 아일랜드 - 노치 속 작은 브라우저 (아이슬렌드 웹)
