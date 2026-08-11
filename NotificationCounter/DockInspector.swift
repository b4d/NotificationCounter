//
//  DockInspector.swift
//  NotificationCounter
//
//  Created by Deni Bacic on 10. 8. 2026.
//

import Foundation
import AppKit
import ApplicationServices

enum DockInspector {

    struct BadgeItem: Identifiable, Equatable {
        let appName: String
        let count: Int
        let statusText: String

        var id: String {
            "\(appName)-\(count)-\(statusText)"
        }
    }

    enum InspectionError: LocalizedError {
        case accessibilityPermissionMissing
        case dockProcessNotFound

        var errorDescription: String? {
            switch self {
            case .accessibilityPermissionMissing:
                "Accessibility permission is required to read Dock badges."
            case .dockProcessNotFound:
                "Dock process was not found."
            }
        }
    }

    static func badgeItems() throws -> [BadgeItem] {

        guard AccessibilityManager.isTrusted else {
            throw InspectionError.accessibilityPermissionMissing
        }

        guard let dock = NSRunningApplication
            .runningApplications(withBundleIdentifier: "com.apple.dock")
            .first else {
            throw InspectionError.dockProcessNotFound
        }

        let dockElement = AXUIElementCreateApplication(
            dock.processIdentifier
        )

        var badges: [BadgeItem] = []
        var seenItems = Set<String>()

        collectBadgeItems(
            dockElement,
            depth: 0,
            maxDepth: 4,
            badges: &badges,
            seenItems: &seenItems
        )

        return badges.sorted { firstItem, secondItem in

            if firstItem.count != secondItem.count {
                return firstItem.count > secondItem.count
            }

            return firstItem.appName.localizedCaseInsensitiveCompare(secondItem.appName) == .orderedAscending
        }
    }

    static func totalBadgeCount() throws -> Int {

        try badgeItems().reduce(0) { total, item in
            total + item.count
        }
    }

    private static func collectBadgeItems(
        _ element: AXUIElement,
        depth: Int,
        maxDepth: Int,
        badges: inout [BadgeItem],
        seenItems: inout Set<String>
    ) {

        guard depth <= maxDepth else {
            return
        }

        if isApplicationDockItem(element) {

            if let badge = badgeItem(from: element),
               seenItems.insert(badge.id).inserted {
                badges.append(badge)
            }

            return
        }

        for child in children(of: element) {
            collectBadgeItems(
                child,
                depth: depth + 1,
                maxDepth: maxDepth,
                badges: &badges,
                seenItems: &seenItems
            )
        }
    }

    private static func isApplicationDockItem(_ element: AXUIElement) -> Bool {

        attributeString(
            element,
            attribute: kAXSubroleAttribute
        ) == "AXApplicationDockItem"
    }

    private static func badgeItem(from element: AXUIElement) -> BadgeItem? {

        for candidate in badgeAttributeCandidates {
            guard let statusText = attributeString(
                element,
                attribute: candidate.name
            ),
            let count = parseBadgeCount(
                from: statusText,
                allowsBareNumber: candidate.allowsBareNumber
            ) else {
                continue
            }

            return BadgeItem(
                appName: appName(from: element),
                count: count,
                statusText: statusText
            )
        }

        return nil
    }

    private static func appName(from element: AXUIElement) -> String {

        attributeString(
            element,
            attribute: kAXTitleAttribute
        ) ?? "Unknown App"
    }

    private static func children(of element: AXUIElement) -> [AXUIElement] {

        guard let children = attributeValue(
            element,
            attribute: kAXChildrenAttribute
        ) as? [AXUIElement] else {
            return []
        }

        return children
    }

    private static func attributeString(
        _ element: AXUIElement,
        attribute: String
    ) -> String? {

        guard let value = attributeValue(
            element,
            attribute: attribute
        ) else {
            return nil
        }

        if let string = value as? String {
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let attributedString = value as? NSAttributedString {
            return attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let number = value as? NSNumber {
            return number.stringValue
        }

        return nil
    }

    private static func attributeValue(
        _ element: AXUIElement,
        attribute: String
    ) -> CFTypeRef? {

        var value: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(
            element,
            attribute as CFString,
            &value
        )

        guard result == .success else {
            return nil
        }

        return value
    }

    private static func parseBadgeCount(
        from text: String,
        allowsBareNumber: Bool
    ) -> Int? {

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            return nil
        }

        let lowercasedText = trimmedText.lowercased()
        let emptyBadgePhrases = [
            "no unread",
            "no new",
            "no notifications",
            "none"
        ]

        guard !emptyBadgePhrases.contains(where: lowercasedText.contains) else {
            return nil
        }

        if allowsBareNumber,
           let count = firstInteger(
            in: trimmedText,
            matching: #"^\s*([0-9][0-9,]*)(?:\+)?\s*$"#
           ) {
            return count
        }

        let countBeforeBadgeWordPattern = #"([0-9][0-9,]*)(?:\+)?\s*(?:new|unread|notifications?|messages?|mails?|alerts?|badges?)"#
        let badgeWordBeforeCountPattern = #"(?:new|unread|notifications?|messages?|mails?|alerts?|badges?)\D+([0-9][0-9,]*)(?:\+)?"#

        return firstInteger(
            in: trimmedText,
            matching: countBeforeBadgeWordPattern
        ) ?? firstInteger(
            in: trimmedText,
            matching: badgeWordBeforeCountPattern
        )
    }

    private static func firstInteger(
        in text: String,
        matching pattern: String
    ) -> Int? {

        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else {
            return nil
        }

        let fullRange = NSRange(
            text.startIndex..<text.endIndex,
            in: text
        )

        guard
            let match = regex.firstMatch(
                in: text,
                range: fullRange
            ),
            match.numberOfRanges > 1,
            let range = Range(match.range(at: 1), in: text)
        else {
            return nil
        }

        let countText = text[range].replacingOccurrences(
            of: ",",
            with: ""
        )

        guard let count = Int(countText), count > 0 else {
            return nil
        }

        return count
    }
}

private struct BadgeAttributeCandidate {
    let name: String
    let allowsBareNumber: Bool
}

private let badgeAttributeCandidates = [
    BadgeAttributeCandidate(
        name: "AXStatusLabel",
        allowsBareNumber: true
    ),
    BadgeAttributeCandidate(
        name: "AXBadgeValue",
        allowsBareNumber: true
    ),
    BadgeAttributeCandidate(
        name: kAXValueAttribute,
        allowsBareNumber: true
    ),
    BadgeAttributeCandidate(
        name: kAXDescriptionAttribute,
        allowsBareNumber: false
    ),
    BadgeAttributeCandidate(
        name: kAXHelpAttribute,
        allowsBareNumber: false
    ),
    BadgeAttributeCandidate(
        name: kAXTitleAttribute,
        allowsBareNumber: false
    )
]
