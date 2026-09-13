import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettingsKeys.showInDock) var showInDock: Bool = false
    @AppStorage(AppSettingsKeys.windowMode) var windowMode: String = WindowMode.attached.rawValue
    @AppStorage(AppSettingsKeys.launchAtLogin) var launchAtLogin: Bool = false

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

    struct AppInfo {
        var name: String
        var version: String
        var build: String
    }

    static let repositoryURL = URL(string: "https://github.com/BoraSarang/WebIsland")!

    /// 버전·빌드는 번들 Info.plist에서 읽음 (키 누락 시 폴백).
    static func appInfo(bundle: Bundle = .main) -> AppInfo {
        appInfo(from: bundle.infoDictionary ?? [:])
    }

    /// 푸터 표시용 고정 이름. 번들의 CFBundleName은 Finder 정합용
    /// "WebIsland"이므로 표시 이름은 분리한다.
    static let displayName = "Web Island"

    static func appInfo(from info: [String: Any]) -> AppInfo {
        AppInfo(
            name: displayName,
            version: (info["CFBundleShortVersionString"] as? String) ?? "—",
            build: (info["CFBundleVersion"] as? String) ?? "—"
        )
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
