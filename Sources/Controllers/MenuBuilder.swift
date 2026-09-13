import Cocoa

/// Main nib 없이 프로그래밍으로 구축하는 메뉴.
/// Edit 메뉴가 있어야 TextField에서 표준 단축키·우클릭 편집이 동작.
enum MenuBuilder {
    /// 설정 항목의 액션 타겟 (AppDelegate). 나머지는 firstResponder 체인.
    static func mainMenu(settingsTarget: AnyObject) -> NSMenu {
        let main = NSMenu()
        main.addItem(appMenuItem(settingsTarget: settingsTarget))
        main.addItem(editMenuItem())
        main.addItem(windowMenuItem())
        return main
    }

    private static func appMenuItem(settingsTarget: AnyObject) -> NSMenuItem {
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(
            title: NSLocalizedString("menu.about", comment: ""),
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        ))
        appMenu.addItem(.separator())
        let settings = NSMenuItem(
            title: NSLocalizedString("menu.settings", comment: ""),
            action: #selector(AppDelegate.openSettings),
            keyEquivalent: ","
        )
        settings.target = settingsTarget
        appMenu.addItem(settings)
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(
            title: NSLocalizedString("menu.quit", comment: ""),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        appItem.submenu = appMenu
        return appItem
    }

    private struct EditEntry {
        let title: String
        let action: Selector
        let key: String
        let modifiers: NSEvent.ModifierFlags
    }

    private static func editMenuItem() -> NSMenuItem {
        let editItem = NSMenuItem()
        let edit = NSMenu(title: "Edit")
        let editActions: [EditEntry] = [
            EditEntry(title: "Undo", action: Selector(("undo:")), key: "z", modifiers: .command),
            EditEntry(title: "Redo", action: Selector(("redo:")), key: "z", modifiers: [.command, .shift]),
            EditEntry(title: "Cut", action: #selector(NSText.cut(_:)), key: "x", modifiers: .command),
            EditEntry(title: "Copy", action: #selector(NSText.copy(_:)), key: "c", modifiers: .command),
            EditEntry(title: "Paste", action: #selector(NSText.paste(_:)), key: "v", modifiers: .command),
            EditEntry(title: "Select All", action: #selector(NSText.selectAll(_:)), key: "a", modifiers: .command)
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
        return editItem
    }

    private static func windowMenuItem() -> NSMenuItem {
        let windowItem = NSMenuItem()
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
        return windowItem
    }
}
