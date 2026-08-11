//
//  AccessibilityManager.swift
//  NotificationCounter
//
//  Created by Deni Bacic on 10. 8. 2026.
//

import Foundation
import AppKit
import ApplicationServices

enum AccessibilityManager {

    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    static func requestPermission() -> Bool {

        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary

        return AXIsProcessTrustedWithOptions(options)
    }

    static func openPermissionSettings() {

        guard let settingsURL = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else {
            return
        }

        NSWorkspace.shared.open(settingsURL)
    }
}
