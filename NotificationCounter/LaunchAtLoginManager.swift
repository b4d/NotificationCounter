//
//  LaunchAtLoginManager.swift
//  NotificationCounter
//
//  Created by Deni Bacic on 10. 8. 2026.
//

import Foundation
import ServiceManagement

enum LaunchAtLoginManager {

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static var statusMessage: String? {
        switch SMAppService.mainApp.status {
        case .enabled, .notRegistered:
            nil
        case .requiresApproval:
            "Launch at Login requires approval in System Settings."
        case .notFound:
            "Launch at Login is unavailable for this app."
        @unknown default:
            "Launch at Login status is unavailable."
        }
    }

    static func setEnabled(_ isEnabled: Bool) throws {

        if isEnabled {
            guard SMAppService.mainApp.status != .enabled else {
                return
            }

            try SMAppService.mainApp.register()
        } else {
            guard SMAppService.mainApp.status != .notRegistered else {
                return
            }

            try SMAppService.mainApp.unregister()
        }
    }
}
