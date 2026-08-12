//
//  DockAutoHideManager.swift
//  NotificationCounter
//
//  Created by Deni Bacic on 12. 8. 2026.
//

import Foundation
import AppKit

enum DockAutoHideManager {

    private static let dockBundleIdentifier = "com.apple.dock"
    private static let autoHideKey = "autohide"

    enum DockAutoHideError: LocalizedError {
        case preferenceWriteFailed

        var errorDescription: String? {
            switch self {
            case .preferenceWriteFailed:
                "Could not update Dock auto-hide preference."
            }
        }
    }

    static var isEnabled: Bool {

        guard let value = CFPreferencesCopyAppValue(
            autoHideKey as CFString,
            dockBundleIdentifier as CFString
        ) else {
            return false
        }

        return CFBooleanGetValue(value as! CFBoolean)
    }

    static func setEnabled(_ isEnabled: Bool) throws {

        let value = isEnabled ? kCFBooleanTrue : kCFBooleanFalse

        CFPreferencesSetAppValue(
            autoHideKey as CFString,
            value,
            dockBundleIdentifier as CFString
        )

        guard CFPreferencesAppSynchronize(
            dockBundleIdentifier as CFString
        ) else {
            throw DockAutoHideError.preferenceWriteFailed
        }

        restartDock()
    }

    private static func restartDock() {

        NSRunningApplication
            .runningApplications(
                withBundleIdentifier: dockBundleIdentifier
            )
            .forEach {
                $0.forceTerminate()
            }
    }
}
