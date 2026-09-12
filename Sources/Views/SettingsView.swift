import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @AppStorage("showInDock") var showInDock: Bool = false
    @AppStorage("windowMode") var windowMode: String = WindowMode.attached.rawValue
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    
    var body: some View {
        Form {
            Section(NSLocalizedString("settings.general", comment: "")) {
                Toggle(NSLocalizedString("settings.launchAtLogin", comment: ""), isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        LoginItemService.isEnabled = enabled
                    }
                Toggle(NSLocalizedString("settings.showInDock", comment: ""), isOn: $showInDock)
                    .help(NSLocalizedString("settings.showInDock.help", comment: ""))
                    .onChange(of: showInDock) { _, _ in
                        (NSApp.delegate as? AppDelegate)?.applyDockVisibility()
                    }
            }
            Section(NSLocalizedString("settings.hotkey", comment: "")) {
                KeyboardShortcuts.Recorder(for: .togglePanel)
            }
            Section(NSLocalizedString("settings.windowMode", comment: "")) {
                Picker(
                    NSLocalizedString("settings.windowMode", comment: ""),
                    selection: $windowMode
                ) {
                    Text(NSLocalizedString("settings.windowMode.attached", comment: ""))
                        .tag(WindowMode.attached.rawValue)
                    Text(NSLocalizedString("settings.windowMode.detached", comment: ""))
                        .tag(WindowMode.detached.rawValue)
                }.pickerStyle(.radioGroup)
                Text(windowModeDesc)
                    .font(.caption).foregroundColor(.secondary)
            }
            Section {
                Text(NSLocalizedString("settings.language.note", comment: ""))
                    .font(.caption2).foregroundColor(.secondary)
            }
        }.padding(20).frame(width: 480, height: 360)
    }

    private var windowModeDesc: String {
        let key = windowMode == WindowMode.attached.rawValue
            ? "settings.windowMode.attached.desc"
            : "settings.windowMode.detached.desc"
        return NSLocalizedString(key, comment: "")
    }
}
