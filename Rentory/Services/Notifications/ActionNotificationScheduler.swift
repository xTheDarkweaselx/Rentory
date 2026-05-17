//
//  ActionNotificationScheduler.swift
//  Rentory
//
//  Created by Adam Ibrahim on 17/05/2026.
//

import Foundation
import UserNotifications

@MainActor
enum ActionNotificationScheduler {
    private static let center = UNUserNotificationCenter.current()
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_GB")
        return calendar
    }()
    private static let notificationHourOfDay = 9

    static func notificationIdentifier(for actionID: UUID) -> String {
        "rentory.action.\(actionID.uuidString)"
    }

    static func scheduleOrCancel(for action: ActionItem) async {
        cancel(for: action.id)

        guard let dueDate = action.dueDate, !action.isCompleted else { return }
        guard let fireDate = scheduledFireDate(for: dueDate), fireDate > .now else { return }

        let isAuthorized = await requestAuthorizationIfNeeded()
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = action.title
        if let notes = action.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
            content.body = notes
        } else {
            content.body = "Rentory action due today."
        }
        content.sound = .default
        content.userInfo = ["actionID": action.id.uuidString]

        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: action.id),
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    static func cancel(for actionID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier(for: actionID)])
    }

    private static func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    private static func scheduledFireDate(for dueDate: Date) -> Date? {
        var components = calendar.dateComponents([.year, .month, .day], from: dueDate)
        components.hour = notificationHourOfDay
        components.minute = 0
        return calendar.date(from: components)
    }
}
