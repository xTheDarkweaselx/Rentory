//
//  ReminderNotificationScheduler.swift
//  Rentory
//
//  Created by Adam Ibrahim on 17/05/2026.
//

import Foundation
import UserNotifications

@MainActor
enum ReminderNotificationScheduler {
    private static let center = UNUserNotificationCenter.current()
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_GB")
        return calendar
    }()
    private static let notificationHourOfDay = 9

    static func notificationIdentifier(for reminderID: UUID) -> String {
        "rentory.reminder.\(reminderID.uuidString)"
    }

    static func scheduleOrCancel(for reminder: Reminder) async {
        cancel(for: reminder.id)

        guard let dueDate = reminder.dueDate, !reminder.isCompleted else { return }
        guard let fireDate = scheduledFireDate(for: dueDate), fireDate > .now else { return }

        let isAuthorized = await requestAuthorizationIfNeeded()
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        if let notes = reminder.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
            content.body = notes
        } else {
            content.body = "Rentory reminder due today."
        }
        content.sound = .default
        content.userInfo = ["reminderID": reminder.id.uuidString]

        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: reminder.id),
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    static func cancel(for reminderID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier(for: reminderID)])
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
