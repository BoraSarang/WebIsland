# Web Island PRD

## 1. Problem
- 자주 보는 사이트 3~5개 (GitHub, Notion, Linear, ChatGPT)를 매번 크롬 탭에서 찾는게 번거로움
- MenubarX는 무겁고, 일반 메뉴바 브라우저는 노치를 활용하지 못함
- 노치 영역은 죽은 공간

## 2. Solution
노치 자체가 브라우저가 된다. 호버하면 펼쳐지고 클릭하면 브라우저가 자라난다.

## 3. Target User
- MacBook M1/M2/M3 노치 있는 맥 유저
- 개발자, 디자이너, 생산성 앱 좋아하는 유저

## 4. Features

### MVP (2주)
- 메뉴바 아이콘 + 노치 오버레이 윈도우
- 노치 프레임 감지 (auxiliaryTopLeftArea)
- Hover -> 420px 확장, 파비콘 탭 5개
- Click -> Attached 브라우저 패널 400x480 (WKWebView 1개)
- 탭 = 사이트 1개, +로 추가/삭제
- Favicon fetching (link[rel=icon] -> /favicon.ico -> Google S2 -> 첫글자 아바타)
- Shared cookie storage (로그인 유지)
- 마지막 탭 기억

### V1 (1달)
- Attached / Detached 모드 설정 (UserDefaults)
- Detached 모드: 드래그 이동, 위치 저장, isMovableByWindowBackground
- 단축키: Cmd+1~5 탭 전환, Cmd+W 닫기, Global hotkey (Cmd+Shift+W)
- 로딩 프로그레스바 2px
- 뒤로/앞으로, 새로고침, 주소창 (도메인만 표시, 클릭시 전체 URL 편집)
- Launch at Login
- Pin 고정, 우클릭 메뉴 (이름 변경, 고정, 삭제)

### V2
- 워크스페이스
- 광고 차단 (WKContentRuleList)
- UserAgent 전환
- Picture-in-Picture 스타일 미니 모드

## 5. UI Spec
- Panel Radius: 20px (Attached 모드는 24px로 노치와 Seamless)
- Material: .hudWindow, blendingMode .behindWindow
- Shadow: 0 8 32 rgba(0,0,0,0.18)
- Animation: spring(response: 0.35, damping: 0.75)
- Tab: 32px 높이, favicon 16px, 활성 탭 pill 배경 #E8E8E8
- Omnibox: 32px, lock icon + domain
- Favicon fallback: 첫글자 + 해시 그라데이션 아바타

## 6. Non-Goals
- 풀 브라우저 기능 (확장 프로그램 등)
- App Store 배포 (초기엔 DMG + Notarization)

## 7. Success Metric
- 노치 호버 -> 브라우저 오픈까지 300ms 이내
- 메모리 300MB 이하 (WKWebView 3개 풀)
