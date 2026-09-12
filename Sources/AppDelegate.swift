import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var notchWindowController: NotchWindowController!
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // LSUIElement true -> no dock icon
        setupStatusItem()
        notchWindowController = NotchWindowController()
        notchWindowController.show()
        
        requestAccessibilityPermission()
    }
    
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Web Island")
            button.action = #selector(togglePanel)
            button.target = self
        }
        // Fallback for non-notch Macs
    }
    
    @objc func togglePanel() {
        notchWindowController.toggle()
    }
    
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
