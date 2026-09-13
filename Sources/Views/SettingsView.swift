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

            Section {
                VStack(spacing: 4) {
                    Text(Self.appInfo().name)
                        .font(.headline)
                    Text(Self.versionLine())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Link(
                        NSLocalizedString("settings.about.github", comment: ""),
                        destination: Self.repositoryURL
                    )
                    .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 8)
        .frame(width: 480, height: 460)
    }

    private var windowModeDesc: String {
        let key = windowMode == WindowMode.attached.rawValue
            ? "settings.windowMode.attached.desc"
            : "settings.windowMode.detached.desc"
        return NSLocalizedString(key, comment: "")
    }

    // MARK: - 앱 정보 푸터 (순수 함수, 단위 테스트 대상)

    static let repositoryURL = URL(string: "https://github.com/BoraSarang/WebIsland")!

    /// 번들 Info.plist에서 읽음 (하드코딩 없음). 키 누락 시 폴백.
    static func appInfo(bundle: Bundle = .main) -> (name: String, version: String, build: String) {
        appInfo(from: bundle.infoDictionary ?? [:])
    }

    static func appInfo(from info: [String: Any]) -> (name: String, version: String, build: String) {
        let name = (info["CFBundleName"] as? String) ?? "Web Island"
        let version = (info["CFBundleShortVersionString"] as? String) ?? "—"
        let build = (info["CFBundleVersion"] as? String) ?? "—"
        return (name, version, build)
    }

    static func versionLine(bundle: Bundle = .main) -> String {
        let info = appInfo(bundle: bundle)
        return String(
            format: NSLocalizedString("settings.about.version", comment: ""),
            info.version,
            info.build
        )
    }
}
