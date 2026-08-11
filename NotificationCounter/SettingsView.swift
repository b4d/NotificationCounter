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

        VStack(alignment: .leading, spacing: 22) {
            SettingsHeaderView()

            SettingsSection(title: "General") {
                Toggle(
                    isOn: Binding(
                        get: {
                            counter.launchesAtLogin
                        },
                        set: { isEnabled in
                            counter.setLaunchesAtLogin(isEnabled)
                        }
                    )
                ) {
                    Label("Launch at Login", systemImage: "power")
                }

                Picker(
                    "Refresh Interval",
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
                .pickerStyle(.menu)

                if let launchAtLoginStatusMessage = counter.launchAtLoginStatusMessage {
                    Text(launchAtLoginStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            SettingsSection(title: "Permissions") {
                LabeledContent("Accessibility") {
                    Label(
                        counter.hasAccessibilityPermission ? "Enabled" : "Required",
                        systemImage: counter.hasAccessibilityPermission
                        ? "checkmark.circle.fill"
                        : "exclamationmark.triangle.fill"
                    )
                }

                Button {
                    counter.requestAccessibilityPermission()
                } label: {
                    Label("Open Accessibility Settings", systemImage: "gearshape.fill")
                }
            }

            SettingsSection(title: "About") {
                LabeledContent("Source", value: "Dock badges")
                LabeledContent("Version", value: appVersion)
            }
        }
        .padding(24)
        .frame(width: 480, height: 460, alignment: .topLeading)
    }

    private var appVersion: String {

        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String

        return version ?? "1.0"
    }
}

private struct SettingsHeaderView: View {

    var body: some View {

        HStack(spacing: 14) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Notification Counter")
                    .font(.title2.weight(.semibold))

                Text("Menu bar Dock badge counter")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct SettingsSection<Content: View>: View {

    let title: String
    @ViewBuilder let content: Content

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                content
            }
        }
    }
}

#Preview {
    SettingsView(counter: NotificationCounterModel())
}
