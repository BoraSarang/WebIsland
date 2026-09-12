# Web Island Architecture

## Window Architecture

### Single Window for Attached Mode (Seamless)
```
NotchWindow (NSWindow, level .screenSaver, background .clear)
  - RootView (SwiftUI)
    - CombinedShape (Path)
      - Top: Expanded Notch Pill (420x40) - covers hardware notch with black
      - Bottom: Browser Panel (400x480) - attached with 0 gap
      - Single shadow, single material
```

왜 1개 윈도우? Gap 0으로 Seamless하게 하려면 두 윈도우는 그림자/배경이 따로 놀아서 티가 남. Boring Notch도 1개 윈도우에 Path로 합쳐서 그림.

### Dual Window for Detached Mode
```
Window A: NotchWindow (420x40) - 항상 노치 위치, 탭 스트립
Window B: DetachedPanel (400x500, NSWindow, movable, level .floating)
  - Position saved in UserDefaults
  - isMovableByWindowBackground = true
```

## Notch Detection
```swift
extension NSScreen {
  var notchRect: NSRect? {
    let left = auxiliaryTopLeftArea
    let right = auxiliaryTopRightArea
    guard left.width > 0, right.minX > left.maxX else { return nil } // no notch
    return NSRect(x: left.maxX, y: left.minY, width: right.minX - left.maxX, height: left.height)
  }
  var hasNotch: Bool { notchRect != nil }
}
```

## Mouse Tracking
- Global monitor: NSEvent.addGlobalMonitorForEvents(.mouseMoved)
- Requires Accessibility permission: AXIsProcessTrusted()
- Throttle to 60fps, check if mouse in expandedNotchRect.insetBy(dx: -20, dy: -20)

## FaviconService
1. JS evaluate: document.querySelector('link[rel*="icon"]')?.href
2. URL: scheme+host + /favicon.ico
3. Google S2: https://www.google.com/s2/favicons?domain=host&sz=64
4. Fallback: generate avatar with first letter + hash gradient
- Cache: NSCache + FileManager (7 days)

## TabManager
- SwiftData @Model WebTab
- Only 3 WKWebViews in pool: active, prev, next
- Others: save URL only, load on demand
- Shared WKWebsiteDataStore.default for login persistence (V2에서 isolated 옵션)

## WindowMode Setting
```swift
enum WindowMode: String, Codable, CaseIterable {
  case attached
  case detached
}
@AppStorage("windowMode") var windowMode = WindowMode.attached
@AppStorage("detachedPanelFrame") var detachedFrame: Data?
```

## File Structure
- AppDelegate: setup status item, request permissions
- NotchWindowController: create screenSaver level window, observe screens, handle hover/expand
- DetachedPanelController: separate floating window, drag handling
- TabBarView: favicon tabs, + button, context menu
- ToolbarView: back/forward, omnibox, menu
- WebContainerView: WKWebView wrapper (UIViewRepresentable)
- FaviconService, TabManager, AvatarGenerator

## Permissions
- LSUIElement = true
- Accessibility: for global mouse monitor
- No sandbox? Need network, files for favicon cache
