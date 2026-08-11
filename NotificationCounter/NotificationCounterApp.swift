//
//  NotificationCounterApp.swift
//  NotificationCounter
//
//  Created by Deni Bacic on 10. 8. 2026.
//

import SwiftUI
import AppKit

@main
struct NotificationCounterApp: App {

    @State private var counter = NotificationCounterModel()

    var body: some Scene {

        MenuBarExtra {

            NotificationCounterMenu(counter: counter)

        } label: {

            NotificationCounterMenuLabel(counter: counter)
                .onAppear {
                    counter.start()
                }
        }
        .menuBarExtraStyle(.menu)

        Window("Settings", id: "settings") {
            SettingsView(counter: counter)
        }
        .defaultSize(width: 480, height: 480)
        .windowResizability(.contentSize)
    }
}

private struct NotificationCounterMenu: View {

    @Environment(\.openWindow) private var openWindow

    let counter: NotificationCounterModel

    var body: some View {

        if counter.hasAccessibilityPermission {

            Label(
                "Notification Counter: \(counter.totalCount)",
                systemImage: "bell.fill"
            )

            if counter.dockBadgeItems.isEmpty {
                Label("No active Dock badges", systemImage: "app.badge")
            } else {
                Divider()

                ForEach(counter.dockBadgeItems) { item in
                    Text("\(item.appName): \(item.count)")
                }
            }

            Divider()

            Button {
                Task {
                    await counter.refresh()
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }

            if let lastUpdated = counter.lastUpdated {
                Label(
                    "Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))",
                    systemImage: "clock"
                )
            }

            if let lastErrorMessage = counter.lastErrorMessage {
                Text(lastErrorMessage)
            }
        } else {

            Text("Accessibility permission required")

            Button {
                counter.requestAccessibilityPermission()
            } label: {
                Label("Open Accessibility Settings", systemImage: "gearshape.fill")
            }
        }

        Divider()

        Button {
            openSettings()
        } label: {
            Label("Settings...", systemImage: "gearshape")
        }

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit", systemImage: "power")
        }
    }

    private func openSettings() {

        openWindow(id: "settings")
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

private struct NotificationCounterMenuLabel: View {

    let counter: NotificationCounterModel

    var body: some View {

        HStack(spacing: 4) {

            Image(
                systemName: counter.hasAccessibilityPermission
                ? "bell.fill"
                : "bell.slash.fill"
            )

            Text("\(counter.totalCount)")
                .monospacedDigit()
        }
    }
}
