# AI에게 Web Island 구현 요청하는 프롬프트

아래 프롬프트를 Cursor, Claude Code, Codex 등에 그대로 붙여넣으세요.

---

당신은 macOS Swift 전문가입니다. "Web Island"라는 macOS 메뉴바 앱을 만들어야 합니다.

## 프로젝트 개요
- 앱 이름: Web Island
- 컨셉: MacBook 노치에 마우스를 가져가면 노치가 좌우로 180px->420px로 펼쳐지고, 클릭하면 노치 아래에 브라우저 패널이 Seamless하게 (gap 0) 자라나는 브라우저. 탭 1개 = 사이트 1개 고정. MenubarX의 미니 버전 + Boring Notch 스타일.
- 두 가지 윈도우 모드 설정으로 제공:
  1) Attached (기본): 노치 확장 pill + 브라우저 패널이 하나의 윈도우, 하나의 모양으로 붙어있음. Boring Notch처럼 보여야 함.
  2) Detached: 노치 윈도우(탭 스트립)와 브라우저 윈도우(플로팅)가 분리되어, 브라우저를 드래그로 이동 가능. 위치 저장.

## 필수 구현 사항

### 1. 노치 감지
- NSScreen.auxiliaryTopLeftArea, auxiliaryTopRightArea로 notchRect 계산
- hasNotch로 분기, 없으면 메뉴바 아이콘 폴백

### 2. 윈도우
- NotchWindow: NSWindow, styleMask .borderless, isOpaque false, backgroundColor .clear, level .screenSaver (메뉴바 위에), hasShadow false (내부 뷰에서 그림자)
- Attached 모드: 하나의 윈도우에 SwiftUI Path로 합쳐진 모양 (top pill 420x40 + bottom panel 400x480, cornerRadius 20~24, shadow 0 8 32, material .hudWindow)
- Detached 모드: NotchWindow (420x40) + DetachedPanel (400x500, isMovableByWindowBackground true, frame 저장)

### 3. 마우스 호버
- NSEvent.addGlobalMonitorForEvents(.mouseMoved)로 글로벌 추적, Accessibility 권한 체크
- 노치 주변 20px inset에 마우스 들어오면 expand, 패널 밖으로 나가면 collapse (0.3초 딜레이)
- Throttle 60fps

### 4. 탭 시스템
- Model: WebTab { id, url, customTitle, order, isPinned }
- SwiftData로 저장
- UI: TabBarView - 파비콘 16px, 활성 탭 pill, + 버튼, 우클릭 메뉴 (이름변경, 고정, 삭제), 드래그로 순서 변경
- WKWebView 풀: 최대 3개만 메모리에, 나머지는 URL만 저장

### 5. Favicon + 아바타 폴백
- 순서: JS link[rel*="icon"] -> /favicon.ico -> Google S2 API -> 첫글자 아바타 (해시 그라데이션)
- NSCache + 디스크 캐시 7일
- 아바타: Canvas에 첫글자, 예: C = ChatGPT

### 6. 브라우저 패널
- ToolbarView: 뒤로/앞으로, 새로고침, Omnibox (평소엔 domain만, 클릭시 전체 URL 편집 모드, lock icon)
- WebContainerView: WKWebView Representable, progress bar 2px 상단
- Shared WKWebsiteDataStore.default

### 7. 설정
- WindowMode enum (attached, detached) @AppStorage
- Detached frame 저장
- Launch at Login, Global hotkey Cmd+Shift+W

### 8. 디자인
- Attached Seamless: gap 0, arrow 없음, 하나의 연속된 모양. 하드웨어 노치는 검정 배경으로 덮어서 사라진 것처럼 보이게
- Detached: 브라우저 패널은 일반 플로팅 윈도우, 드래그 핸들은 툴바 영역
- 애니메이션: spring(response: 0.35, dampingFraction: 0.75)

### 9. 프로젝트 구조
- AppDelegate.swift
- Controllers/NotchWindowController.swift
- Controllers/DetachedPanelController.swift
- Models/WebTab.swift
- Services/FaviconService.swift, TabManager.swift
- Views/NotchIdleView, NotchHoverView, BrowserPanelView, TabBarView, ToolbarView, WebContainerView
- Utils/AvatarGenerator, NotchDetector

## 산출물
- Xcode 프로젝트 (LSUIElement true)
- AppIcon 1024px 포함 (Assets/Icons/AppIcon_1024.png 참고 - 노치 + 브라우저 + 섬 컨셉)
- Mockup HTML 3개 참고

## 참고 목업
- Mockups/ 폴더에 interactive HTML 있음 - hover, expand, attached/detached 동작 확인

지금 바로 코드 스켈레톤부터 만들고 빌드 가능하게 해줘.

---

## 추가 요구사항
- SwiftUI + AppKit 하이브리드
- macOS 13+ 타겟
- 메모리 300MB 이하 유지
