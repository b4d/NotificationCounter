//
//  SettingsView.swift
//  NotificationCounter
//
//  Created by Deni Bacic on 10. 8. 2026.
//

import SwiftUI
import AppKit

struct SettingsView: View {

    let counter: NotificationCounterModel

    var body: some View {

        VStack(spacing: 0) {
            SettingsHeaderView()
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)

            Divider()

            VStack(alignment: .leading, spacing: 18) {
                SettingsSection(
                    title: "General",
                    systemImage: "slider.horizontal.3"
                ) {
                    SettingsRow(
                        title: "Launch at Login",
                        subtitle: "Start NotificationCounter when you sign in.",
                        systemImage: "power"
                    ) {
                        Toggle(
                            "",
                            isOn: Binding(
                                get: {
                                    counter.launchesAtLogin
                                },
                                set: { isEnabled in
                                    counter.setLaunchesAtLogin(isEnabled)
                                }
                            )
                        )
                        .labelsHidden()
                    }

                    SettingsDivider()

                    SettingsRow(
                        title: "Refresh Interval",
                        subtitle: "How often Dock badge counts are refreshed.",
                        systemImage: "arrow.clockwise"
                    ) {
                        Picker(
                            "",
                            selection: Binding(
                                get: {
                                    counter.refreshInterval
                                },
                                set: { refreshInterval in
                                    counter.setRefreshInterval(refreshInterval)
                                }
                            )
                        ) {
                            ForEach(RefreshInterval.allCases) { refreshInterval in
                                Text(refreshInterval.title)
                                    .tag(refreshInterval)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 132)
                    }

                    if let launchAtLoginStatusMessage = counter.launchAtLoginStatusMessage {
                        SettingsDivider()

                        SettingsMessageRow(
                            message: launchAtLoginStatusMessage,
                            systemImage: "exclamationmark.triangle"
                        )
                    }
                }

                SettingsSection(
                    title: "Permissions",
                    systemImage: "hand.raised"
                ) {
                    SettingsRow(
                        title: "Accessibility",
                        subtitle: "Required to read Dock badge state.",
                        systemImage: "hand.raised.circle"
                    ) {
                        SettingsStatusLabel(
                            title: counter.hasAccessibilityPermission ? "Enabled" : "Required",
                            systemImage: counter.hasAccessibilityPermission
                            ? "checkmark.circle.fill"
                            : "exclamationmark.triangle.fill",
                            color: counter.hasAccessibilityPermission ? .green : .orange
                        )
                    }

                    SettingsDivider()

                    SettingsRow(
                        title: "System Settings",
                        subtitle: "Open Accessibility permissions.",
                        systemImage: "gearshape"
                    ) {
                        Button("Open") {
                            counter.requestAccessibilityPermission()
                        }
                    }
                }

                SettingsSection(
                    title: "About",
                    systemImage: "info.circle"
                ) {
                    SettingsValueRow(
                        title: "Source",
                        value: "Dock badges",
                        systemImage: "dock.rectangle"
                    )

                    SettingsDivider()

                    SettingsValueRow(
                        title: "Version",
                        value: appVersion,
                        systemImage: "number"
                    )

                    if let projectWebsiteURL {
                        SettingsDivider()

                        SettingsRow(
                            title: "Website",
                            subtitle: "Project page and source code.",
                            systemImage: "link"
                        ) {
                            Link(
                                "GitHub",
                                destination: projectWebsiteURL
                            )
                        }
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 520, height: 620, alignment: .top)
    }

    private var appVersion: String {

        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String

        return version ?? "1.0"
    }

    private var projectWebsiteURL: URL? {
        URL(string: "https://github.com/b4d/NotificationCounter")
    }
}

private struct SettingsHeaderView: View {

    var body: some View {

        HStack(spacing: 16) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 72, height: 72)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text("Notification Counter")
                    .font(.title2.weight(.semibold))

                Text("Keep Dock badge counts visible in the menu bar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

private struct SettingsSection<Content: View>: View {

    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {

        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            VStack(spacing: 0) {
                content
            }
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        Color(nsColor: .separatorColor).opacity(0.35),
                        lineWidth: 1
                    )
            }
        }
    }
}

private struct SettingsRow<Accessory: View>: View {

    let title: String
    let subtitle: String?
    let systemImage: String
    @ViewBuilder let accessory: Accessory

    var body: some View {

        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 16)

            accessory
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private struct SettingsValueRow: View {

    let title: String
    let value: String
    let systemImage: String

    var body: some View {

        SettingsRow(
            title: title,
            subtitle: nil,
            systemImage: systemImage
        ) {
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SettingsMessageRow: View {

    let message: String
    let systemImage: String

    var body: some View {

        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.orange)
                .frame(width: 24)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }
}

private struct SettingsStatusLabel: View {

    let title: String
    let systemImage: String
    let color: Color

    var body: some View {

        Label(title, systemImage: systemImage)
            .foregroundStyle(color)
            .font(.callout.weight(.medium))
    }
}

private struct SettingsDivider: View {

    var body: some View {

        Divider()
            .padding(.leading, 48)
    }
}

#Preview {
    SettingsView(counter: NotificationCounterModel())
}
