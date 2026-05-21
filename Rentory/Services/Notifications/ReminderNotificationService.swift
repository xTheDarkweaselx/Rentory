//
//  ReminderNotificationService.swift
//  Rentory
//
//  Schedules local notifications for reminders with due dates. The service
//  fully re-syncs whenever a reminder is saved, completed, or deleted — it's
//  easier to be correct by always reconciling than to track diffs.
//
//  Local-only: uses UNUserNotificationCenter exclusively. No remote
//  notifications, no analytics. The local-first contract documented in
//  RentoryApp.swift is preserved.
//

import Combine
import Foundation
import SwiftData
import UserNotifications

@MainActor
final class ReminderNotificationService: ObservableObject {
    static let isEnabledStorageKey = "rentory.reminderNotificationsEnabled"

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center: UNUserNotificationCenter
    private let userDefaults: UserDefaults
    private let calendar: Calendar
    private let identifierPrefix = "rentory.reminder."

    init(
        center: UNUserNotificationCenter = .current(),
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.center = center
        self.userDefaults = userDefaults
        self.calendar = calendar
    }

    var isEnabledByUser: Bool {
        get { userDefaults.bool(forKey: Self.isEnabledStorageKey) }
        set { userDefaults.set(newValue, forKey: Self.isEnabledStorageKey) }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    /// Cancels every previously scheduled Rentory reminder notification and
    /// schedules a new one for each uncompleted reminder with a future due
    /// date. Cheap to call — it's the same operation as a targeted update
    /// minus the bookkeeping. Safe to call from main actor contexts; the
    /// underlying UN calls are async-friendly.
    func reschedule(context: ModelContext) async {
        await refreshAuthorizationStatus()

        let shouldSchedule = isEnabledByUser && (authorizationStatus == .authorized || authorizationStatus == .provisional)

        await cancelAll()

        guard shouldSchedule else { return }

        let reminders = (try? context.fetch(FetchDescriptor<Reminder>())) ?? []
        let scheduleableReminders = reminders.filter { reminder in
            reminder.completedAt == nil && reminder.dueDate != nil
        }

        for reminder in scheduleableReminders {
            await schedule(reminder)
        }
    }

    func cancelAll() async {
        let pending = await center.pendingNotificationRequests()
        let ours = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }
        guard !ours.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ours)
    }

    func cancel(reminderID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier(for: reminderID)])
    }

    /// Computes the trigger date for a reminder.
    ///
    /// Preferred firing time is 9 AM on the due date in the user's current
    /// calendar. If the user creates a reminder due today after 9 AM has
    /// already passed, we still schedule it — one minute from now — so the
    /// user doesn't silently lose today's notification. Reminders whose due
    /// date is genuinely in the past (yesterday or earlier) are not
    /// scheduled (a notification for a past date would be confusing).
    func triggerDate(for reminder: Reminder) -> Date? {
        guard let dueDate = reminder.dueDate else { return nil }

        var components = calendar.dateComponents([.year, .month, .day], from: dueDate)
        components.hour = 9
        components.minute = 0
        components.second = 0

        guard let preferredFiringDate = calendar.date(from: components) else { return nil }

        if preferredFiringDate > .now {
            return preferredFiringDate
        }

        let todayStart = calendar.startOfDay(for: .now)
        let dueDateStart = calendar.startOfDay(for: dueDate)
        if dueDateStart >= todayStart {
            return Date.now.addingTimeInterval(60)
        }

        return nil
    }

    private func schedule(_ reminder: Reminder) async {
        guard let firingDate = triggerDate(for: reminder) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Rentory reminder"
        content.body = reminder.title
        content.sound = .default
        content.userInfo = ["reminderID": reminder.id.uuidString]

        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: firingDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier(for: reminder.id),
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    private func identifier(for reminderID: UUID) -> String {
        identifierPrefix + reminderID.uuidString
    }
}
