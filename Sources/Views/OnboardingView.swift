import AppKit
import Combine
import SwiftUI

/// 온보딩(랜딩) 뷰. 손쉬운 사용 권한 상태를 실시간 감지해 안내한다.
/// 권한이 허용되고 나면 "시작하기"로 전환된다.
struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var trusted = AccessibilityService.isTrusted
    @State private var brokenURL = false

    private static let monitor = AccessibilityService.pollTrusted()

    var body: some View {
        VStack(spacing: 0) {
            appHeader
            Spacer().frame(height: 28)
            permissionCard
            Spacer().frame(height: 24)
            actionButtons
            Spacer().frame(height: 8)
            secondaryHint
        }
        .frame(width: 480, height: 400)
        .background(Color(nsColor: .windowBackgroundColor))
        .onReceive(Self.monitor) { granted in
            trusted = granted
            if granted {
                DebugLogger.info("손쉬운 사용 권한 허용 감지")
            }
        }
    }

    // MARK: - 헤더: 아이콘 + 이름 + 태그라인

    private var appHeader: some View {
        VStack(spacing: 10) {
            if let icon = NSImage(named: "AppIcon") {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
            }
            Text(NSLocalizedString("app.name", comment: ""))
                .font(.system(size: 22, weight: .semibold))
            Text(NSLocalizedString("app.tagline", comment: ""))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 36)
    }

    // MARK: - 권한 카드

    private var permissionCard: some View {
        HStack(spacing: 14) {
            Image(systemName: trusted ? "checkmark.seal.fill" : "cursorarrow")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(trusted ? Color.green : Color.accentColor)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 5) {
                Text(NSLocalizedString(
                    trusted ? "onboarding.status.granted" : "onboarding.status.required",
                    comment: ""
                ))
                .font(.system(size: 13, weight: .semibold))
                Text(NSLocalizedString(
                    trusted ? "onboarding.status.granted.desc" : "onboarding.status.required.desc",
                    comment: ""
                ))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(NSLocalizedString(
                trusted ? "onboarding.status.badge.granted" : "onboarding.status.badge.required",
                comment: ""
            ))
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(trusted ? Color.green : Color.orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background((trusted ? Color.green : Color.orange).opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(trusted ? Color.green.opacity(0.4) : Color(nsColor: .separatorColor).opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 40)
    }

    // MARK: - 버튼

    @ViewBuilder
    private var actionButtons: some View {
        if trusted {
            Button(NSLocalizedString("onboarding.start", comment: "")) {
                onFinish()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)
        } else {
            HStack(spacing: 12) {
                Button(NSLocalizedString("onboarding.skip", comment: "")) {
                    onFinish()
                }
                .keyboardShortcut(.cancelAction)

                Button(NSLocalizedString("onboarding.openSettings", comment: "")) {
                    if !AccessibilityService.openSystemSettings() {
                        brokenURL = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .help(NSLocalizedString("onboarding.openSettings.help", comment: ""))
            }
            .controlSize(.large)
        }
    }

    private var secondaryHint: some View {
        Group {
            if brokenURL {
                Text(NSLocalizedString("onboarding.settingsOpenFailed", comment: ""))
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            } else {
                Text(NSLocalizedString("onboarding.hint", comment: ""))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
