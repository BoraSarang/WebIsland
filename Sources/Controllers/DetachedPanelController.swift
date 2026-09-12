import Cocoa
import SwiftUI

final class DetachedPanelController {
    var window: NSWindow!
    
    init() {
        DebugLogger.feature("DetachedPanel", "플로팅 윈도우 초기화")
        let saved = UserDefaults.standard.string(forKey: "detachedFrame")
            .flatMap { NSRectFromString($0) }
            ?? NSRect(x: 600, y: 400, width: 400, height: 500)

        window = NSWindow(
            contentRect: saved,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true
        window.collectionBehavior = [.canJoinAllSpaces]
        
        window.contentView = NSHostingView(rootView: DetachedBrowserView())
    }
    
    func show() { window.orderFrontRegardless() }
    func hide() { window.orderOut(nil) }
}
