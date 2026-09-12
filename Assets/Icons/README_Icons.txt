Web Island / 웹 아일랜드 아이콘 세트

AppIcon.iconset/ - Xcode에 드래그하면 바로 적용됨
- icon_16x16.png ~ icon_512x512@2x.png 포함
- 터미널에서 icns 생성: iconutil -c icns AppIcon.iconset -o AppIcon.icns

AppIcon_1024.png - App Store 제출용 1024x1024
Menubar/ - 메뉴바 템플릿 아이콘 (isTemplate=true로 사용, 다크/라이트 자동 대응)

원본 투명 아이콘:
- AppIcon_1024.png: 노치 + 브라우저 + 섬 컨셉
- MenubarIcon.png: 섬 + 야자수 미니멀 실루엣

Xcode 적용:
1. Assets.xcassets > AppIcon에 AppIcon.iconset 드래그
2. MenubarIcon.png는 Resources에 넣고 NSImage(named: "MenubarIcon")로 로드, isTemplate=true 설정
