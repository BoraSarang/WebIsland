import Cocoa
import SwiftUI

final class DetachedPanelController {
    var window: NSWindow!
    
    init() {
        DebugLogger.feature("DetachedPanel", "플로팅 윈도우 초기화")
        let saved = UserDefaults.standard.string(forKey: "detachedFrame")
            .flatMap { NSRectFromString($0) }
            ?? NSRect(x: 600, y: 400, width: 400, height: 500)

        window = PanelWindow(
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
        
        let hosting = NSHostingView(rootView: DetachedBrowserView())
        hosting.sizingOptions = []
        hosting.frame = NSRect(origin: .zero, size: saved.size)
        hosting.autoresizingMask = [.width, .height]
        window.contentView = hosting
        window.setFrame(saved, display: false)
    }
    
    func show() { window.orderFrontRegardless() }
    func hide() { window.orderOut(nil) }
}
