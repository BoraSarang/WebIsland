# Web Island 메뉴바 앱 가이드

## 메뉴바 앱인가?
네, 완전한 LSUIElement 메뉴바 앱입니다.

- **메뉴바**: 항상 표시. 아이콘은 섬 + 야자수 미니멀 템플릿 (다크/라이트 자동 대응)
- **Dock**: 설정으로 토글 가능
  - 기본: Dock 숨김 (LSUIElement = true, activationPolicy = .accessory)
  - 설정에서 "Dock에 표시" 켜면: .regular로 전환되어 Dock에 나타남

## 메뉴바 클릭 동작
- **왼쪽 클릭**: Web Island 브라우저 패널 토글 (노치 확장)
- **오른쪽 클릭 or Control+클릭**: 컨텍스트 메뉴
  - 설정...
  - Dock에 표시 / Dock에서 가리기 (토글)
  - Web Island 정보
  - 종료

## Dock 토글 구현
```swift
@AppStorage("showInDock") var showInDock = false

func applyDockVisibility() {
  if showInDock {
    NSApp.setActivationPolicy(.regular) // Dock 표시
  } else {
    NSApp.setActivationPolicy(.accessory) // 메뉴바만
  }
}
```

- UserDefaults에 저장되어 재부팅 후에도 유지
- setActivationPolicy 호출 시 Dock 아이콘이 즉시 나타나고 사라짐

## 메뉴바 아이콘
- Assets/Icons/MenubarIcon.png - 템플릿 이미지 (isTemplate = true)
- 16x16, @2x는 32x32
- 검정 단색 실루엣, 배경 투명

## 설정 화면 (SettingsView)
- 로그인 시 자동 실행
- Dock에 표시 토글
- 윈도우 모드: Attached / Detached

## About
- NSApp.orderFrontStandardAboutPanel 사용
