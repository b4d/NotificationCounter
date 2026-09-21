//
//  DockAutoHideManager.swift
//  NotificationCounter
//
//  Created by Deni Bacic on 12. 8. 2026.
//

import Foundation
import AppKit

nonisolated enum DockAutoHideManager {

    private static let dockBundleIdentifier = "com.apple.dock"
    private static let autoHideKey = "autohide"

    enum DockAutoHideError: LocalizedError {
        case preferenceWriteFailed
        case dockRestartFailed

        var errorDescription: String? {
            switch self {
            case .preferenceWriteFailed:
                "Could not update Dock auto-hide preference."
            case .dockRestartFailed:
                "Could not restart Dock."
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

        if let boolValue = value as? Bool {
            return boolValue
        }

        if let numberValue = value as? NSNumber {
            return numberValue.boolValue
        }

        return false
    }

    static func setEnabled(_ isEnabled: Bool) async throws {

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

        try await restartDock()
    }

    private static func restartDock() async throws {

        let terminationStatus = try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Int32, Error>) in

            do {
                try Process.run(
                    URL(fileURLWithPath: "/usr/bin/killall"),
                    arguments: ["Dock"]
                ) { process in
                    continuation.resume(returning: process.terminationStatus)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }

        guard terminationStatus == 0 else {
            throw DockAutoHideError.dockRestartFailed
        }
    }
}
