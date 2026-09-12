import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @AppStorage("showInDock") var showInDock: Bool = false
    @AppStorage("windowMode") var windowMode: String = WindowMode.attached.rawValue
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false

    var body: some View {
        Form {
            Section {
                Toggle(NSLocalizedString("settings.launchAtLogin", comment: ""), isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        LoginItemService.isEnabled = enabled
                    }
                Toggle(NSLocalizedString("settings.showInDock", comment: ""), isOn: $showInDock)
                    .onChange(of: showInDock) { _, _ in
                        (NSApp.delegate as? AppDelegate)?.applyDockVisibility()
                    }
            } header: {
                Text(NSLocalizedString("settings.general", comment: ""))
            } footer: {
                Text(NSLocalizedString("settings.showInDock.help", comment: ""))
            }

            Section {
                LabeledContent(NSLocalizedString("settings.hotkey.toggle", comment: "")) {
                    KeyboardShortcuts.Recorder(for: .togglePanel)
                }
            } header: {
                Text(NSLocalizedString("settings.hotkey", comment: ""))
            }

            Section {
                Picker(selection: $windowMode) {
                    Text(NSLocalizedString("settings.windowMode.attached", comment: ""))
                        .tag(WindowMode.attached.rawValue)
                    Text(NSLocalizedString("settings.windowMode.detached", comment: ""))
                        .tag(WindowMode.detached.rawValue)
                } label: {
                    EmptyView()
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
                .onChange(of: windowMode) { _, _ in
                    NotificationCenter.default.post(name: .wiWindowModeChanged, object: nil)
                }
            } header: {
                Text(NSLocalizedString("settings.windowMode", comment: ""))
            } footer: {
                Text(windowModeDesc)
            }

            Section {
                Text(NSLocalizedString("settings.language.note", comment: ""))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 8)
        .frame(width: 480, height: 420)
    }

    private var windowModeDesc: String {
        let key = windowMode == WindowMode.attached.rawValue
            ? "settings.windowMode.attached.desc"
            : "settings.windowMode.detached.desc"
        return NSLocalizedString(key, comment: "")
    }
}
