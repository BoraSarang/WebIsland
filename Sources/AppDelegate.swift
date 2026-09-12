import Cocoa
import KeyboardShortcuts
import SwiftUI

extension KeyboardShortcuts.Name {
    static let togglePanel = Self("togglePanel")
    static let debugPanel = Self("debugPanel")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var notchWindowController: NotchWindowController!
    var statusItem: NSStatusItem!
    var fallbackPopover: NSPopover?
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        DebugLogger.feature("App", "메뉴바 앱 시작")
        buildMainMenu()
        setupStatusItem()
        applyDockVisibility()
        syncLaunchAtLogin()
        setupHotKey()
        notchWindowController = NotchWindowController()
        notchWindowController.show()
        requestAccessibilityPermission()
    }

    // MARK: - Main Menu (편집 단축키 ⌘C/V/X/A/Z 동작용)

    /// Main nib 없이 동작하므로 프로그래밍 방식으로 구축.
    /// Edit 메뉴가 있어야 TextField에서 표준 단축키·우클릭 편집이 동작.
    func buildMainMenu() {
        let main = NSMenu()

        let appItem = NSMenuItem()
        main.addItem(appItem)
        let appMenu = NSMenu()
        let about = NSMenuItem(
            title: NSLocalizedString("menu.about", comment: ""),
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        appMenu.addItem(about)
        appMenu.addItem(.separator())
        let settings = NSMenuItem(
            title: NSLocalizedString("menu.settings", comment: ""),
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settings.target = self
        appMenu.addItem(settings)
        appMenu.addItem(.separator())
        let quit = NSMenuItem(
            title: NSLocalizedString("menu.quit", comment: ""),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenu.addItem(quit)
        appItem.submenu = appMenu

        let editItem = NSMenuItem()
        main.addItem(editItem)
        let edit = NSMenu(title: "Edit")
        struct EditEntry {
            let title: String
            let action: Selector
            let key: String
            let modifiers: NSEvent.ModifierFlags
        }
        let editActions: [EditEntry] = [
            EditEntry(title: "Undo", action: Selector(("undo:")), key: "z", modifiers: .command),
            EditEntry(title: "Redo", action: Selector(("redo:")), key: "z", modifiers: [.command, .shift]),
            EditEntry(title: "Cut", action: #selector(NSText.cut(_:)), key: "x", modifiers: .command),
            EditEntry(title: "Copy", action: #selector(NSText.copy(_:)), key: "c", modifiers: .command),
            EditEntry(title: "Paste", action: #selector(NSText.paste(_:)), key: "v", modifiers: .command),
            EditEntry(title: "Select All", action: #selector(NSText.selectAll(_:)), key: "a", modifiers: .command),
        ]
        for (index, entry) in editActions.enumerated() {
            if index == 2 {
                edit.addItem(.separator())
            }
            let item = NSMenuItem(
                title: entry.title, action: entry.action,
                keyEquivalent: entry.key
            )
            item.keyEquivalentModifierMask = entry.modifiers
            edit.addItem(item)
        }
        editItem.submenu = edit

        let windowItem = NSMenuItem()
        main.addItem(windowItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(
            withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)),
            keyEquivalent: "m"
        )
        windowMenu.addItem(
            withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)),
            keyEquivalent: "w"
        )
        windowItem.submenu = windowMenu

        NSApp.mainMenu = main
    }

    // MARK: - Status Item

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let icon = NSImage(named: "MenubarIcon") {
                icon.isTemplate = true
                button.image = icon
            } else {
                button.image = NSImage(
                    systemSymbolName: "globe",
                    accessibilityDescription: "Web Island"
                )
            }
            button.target = self
            button.action = #selector(statusClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc func statusClicked() {
        guard let event = NSApp.currentEvent else {
            togglePanel()
            return
        }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePanel()
        }
    }

    func showContextMenu() {
        let menu = NSMenu()
        let settings = NSMenuItem(
            title: NSLocalizedString("menu.settings", comment: ""),
            action: #selector(openSettings),
            keyEquivalent: ""
        )
        settings.target = self
        menu.addItem(settings)

        let dockTitle = NSLocalizedString(
            UserDefaults.standard.bool(forKey: "showInDock")
                ? "menu.hideInDock" : "menu.showInDock",
            comment: ""
        )
        let dock = NSMenuItem(title: dockTitle, action: #selector(toggleDock), keyEquivalent: "")
        dock.target = self
        menu.addItem(dock)
        menu.addItem(.separator())

        let about = NSMenuItem(
            title: NSLocalizedString("menu.about", comment: ""),
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(
            title: NSLocalizedString("menu.quit", comment: ""),
            action: #selector(quitApp),
            keyEquivalent: ""
        )
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    // MARK: - Panel Toggle + Non-Notch Fallback

    @objc func togglePanel() {
        if NSScreen.main?.hasNotch == true {
            DebugLogger.feature("Panel", "노치 패널 토글")
            notchWindowController.toggle()
        } else {
            DebugLogger.feature("Panel", "폴백 팝오버 토글 (노치 없음)")
            toggleFallbackPopover()
        }
    }

    func toggleFallbackPopover() {
        if let popover = fallbackPopover, popover.isShown {
            popover.performClose(nil)
            return
        }
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.contentViewController = NSHostingController(rootView: DetachedBrowserView())
        popover.show(
            relativeTo: statusItem.button?.bounds ?? .zero,
            of: statusItem.button ?? NSView(),
            preferredEdge: .minY
        )
        fallbackPopover = popover
    }

    // MARK: - Dock / Launch / HotKey

    func applyDockVisibility() {
        let show = UserDefaults.standard.bool(forKey: "showInDock")
        NSApp.setActivationPolicy(show ? .regular : .accessory)
        DebugLogger.info("Dock 표시: \(show)")
    }

    @objc func toggleDock() {
        let current = UserDefaults.standard.bool(forKey: "showInDock")
        UserDefaults.standard.set(!current, forKey: "showInDock")
        applyDockVisibility()
    }

    func syncLaunchAtLogin() {
        LoginItemService.isEnabled = UserDefaults.standard.bool(forKey: "launchAtLogin")
    }

    func setupHotKey() {
        if KeyboardShortcuts.getShortcut(for: .togglePanel) == nil {
            KeyboardShortcuts.setShortcut(.init(.w, modifiers: [.command, .shift]), for: .togglePanel)
        }
        KeyboardShortcuts.onKeyUp(for: .togglePanel) { [weak self] in
            DebugLogger.feature("HotKey", "전역 단축키 패널 토글")
            self?.togglePanel()
        }
        if KeyboardShortcuts.getShortcut(for: .debugPanel) == nil {
            KeyboardShortcuts.setShortcut(.init(.d, modifiers: [.command, .shift]), for: .debugPanel)
        }
        KeyboardShortcuts.onKeyUp(for: .debugPanel) {
            DebugPanelController.shared.toggle()
        }
    }

    // MARK: - Settings / About / Quit

    @objc func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 420),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = NSLocalizedString("menu.settings", comment: "")
            let hosting = NSHostingView(rootView: SettingsView())
            hosting.sizingOptions = []
            window.contentView = hosting
            window.setFrame(NSRect(x: 0, y: 0, width: 480, height: 420), display: false)
            window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Permissions

    func requestAccessibilityPermission() {
        if AXIsProcessTrusted() {
            return
        }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
        if !AXIsProcessTrusted() {
            DebugLogger.error(code: "E-MAC-PERM-0001", "손쉬운 사용 권한 미허용 — 호버 감지 제한")
        }
    }
}
