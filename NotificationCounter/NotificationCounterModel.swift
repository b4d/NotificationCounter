//
//  NotificationCounterModel.swift
//  NotificationCounter
//
//  Created by Deni Bacic on 10. 8. 2026.
//

import Foundation
import Observation

enum RefreshInterval: Int, CaseIterable, Identifiable {
    case fiveSeconds = 5
    case fifteenSeconds = 15
    case thirtySeconds = 30
    case sixtySeconds = 60

    var id: Int {
        rawValue
    }

    var title: String {
        switch self {
        case .fiveSeconds:
            "5 seconds"
        case .fifteenSeconds:
            "15 seconds"
        case .thirtySeconds:
            "30 seconds"
        case .sixtySeconds:
            "60 seconds"
        }
    }
}

@MainActor
@Observable
final class NotificationCounterModel {

    private static let refreshIntervalKey = "refreshIntervalSeconds"

    private(set) var totalCount = 0
    private(set) var dockBadgeItems: [DockInspector.BadgeItem] = []
    private(set) var hasAccessibilityPermission = AccessibilityManager.isTrusted
    private(set) var launchesAtLogin = LaunchAtLoginManager.isEnabled
    private(set) var launchAtLoginStatusMessage = LaunchAtLoginManager.statusMessage
    private(set) var refreshInterval: RefreshInterval
    private(set) var lastUpdated: Date?
    private(set) var lastErrorMessage: String?

    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {

        self.userDefaults = userDefaults

        let savedRefreshInterval = userDefaults.integer(
            forKey: Self.refreshIntervalKey
        )

        refreshInterval = RefreshInterval(
            rawValue: savedRefreshInterval
        ) ?? .fiveSeconds
    }

    func start() {

        guard refreshTask == nil else {
            return
        }

        refreshTask = Task { [weak self] in

            while !Task.isCancelled {

                await self?.refresh()

                do {
                    try await Task.sleep(
                        for: .seconds(self?.refreshInterval.rawValue ?? 5)
                    )
                } catch {
                    return
                }
            }
        }
    }

    func stop() {

        refreshTask?.cancel()
        refreshTask = nil
    }

    func requestAccessibilityPermission() {

        hasAccessibilityPermission = AccessibilityManager.requestPermission()
        AccessibilityManager.openPermissionSettings()

        Task { [weak self] in

            try? await Task.sleep(for: .seconds(1))
            await self?.refresh()
        }
    }

    func setLaunchesAtLogin(_ isEnabled: Bool) {

        do {
            try LaunchAtLoginManager.setEnabled(isEnabled)
            refreshLaunchAtLoginStatus()
        } catch {
            refreshLaunchAtLoginStatus()
            lastErrorMessage = error.localizedDescription
        }
    }

    func setRefreshInterval(_ refreshInterval: RefreshInterval) {

        guard self.refreshInterval != refreshInterval else {
            return
        }

        self.refreshInterval = refreshInterval
        userDefaults.set(
            refreshInterval.rawValue,
            forKey: Self.refreshIntervalKey
        )

        stop()
        start()
    }

    func refresh() async {

        refreshLaunchAtLoginStatus()
        hasAccessibilityPermission = AccessibilityManager.isTrusted

        guard hasAccessibilityPermission else {
            totalCount = 0
            dockBadgeItems = []
            lastUpdated = nil
            lastErrorMessage = nil
            return
        }

        do {
            let badgeItems = try DockInspector.badgeItems()

            dockBadgeItems = badgeItems
            totalCount = badgeItems.reduce(0) { total, item in
                total + item.count
            }
            lastUpdated = Date()
            lastErrorMessage = nil
        } catch {
            dockBadgeItems = []
            totalCount = 0
            lastUpdated = Date()
            lastErrorMessage = error.localizedDescription
        }
    }

    private func refreshLaunchAtLoginStatus() {

        launchesAtLogin = LaunchAtLoginManager.isEnabled
        launchAtLoginStatusMessage = LaunchAtLoginManager.statusMessage
    }
}
