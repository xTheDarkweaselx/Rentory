//
//  ReminderService.swift
//  Rentory
//
//  Created by Adam Ibrahim on 17/05/2026.
//

import Foundation

struct ReminderOverview {
    let overdueCount: Int
    let dueSoonCount: Int
    let totalOpenCount: Int
    let upcomingItems: [ReminderSnapshot]
    let statusTitle: String
    let shortMessage: String
}

struct ReminderSnapshot: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let dueDate: Date?
    let completedAt: Date?
    let kindRawValue: String
    let priorityRawValue: String
    let urgency: ReminderUrgency

    var kind: ReminderKind {
        ReminderKind(rawValue: kindRawValue) ?? .custom
    }

    var priority: ReminderPriority {
        ReminderPriority(rawValue: priorityRawValue) ?? .normal
    }
}

enum ReminderUrgency: String, Sendable, Hashable {
    case overdue
    case dueSoon
    case upcoming
    case undated
    case completed
}

enum ReminderService {
    static let dueSoonWindow: TimeInterval = 7 * 24 * 60 * 60
    static let maxUpcomingItems = 5

    static func overview(for propertyPack: PropertyPack, on referenceDate: Date = .now) -> ReminderOverview {
        let openReminders = propertyPack.reminders.filter { !$0.isCompleted }
        let dueSoonCutoff = referenceDate.addingTimeInterval(dueSoonWindow)

        let overdue = openReminders.filter { reminder in
            guard let dueDate = reminder.dueDate else { return false }
            return dueDate < referenceDate
        }
        let dueSoon = openReminders.filter { reminder in
            guard let dueDate = reminder.dueDate else { return false }
            return dueDate >= referenceDate && dueDate <= dueSoonCutoff
        }

        let sortedOverdue = overdue.sorted { lhs, rhs in
            (lhs.dueDate ?? .distantPast) < (rhs.dueDate ?? .distantPast)
        }
        let sortedDueSoon = dueSoon.sorted { lhs, rhs in
            (lhs.dueDate ?? .distantFuture) < (rhs.dueDate ?? .distantFuture)
        }

        let topReminders = (sortedOverdue + sortedDueSoon).prefix(maxUpcomingItems)
        let snapshots = topReminders.map { reminder in
            makeSnapshot(reminder, on: referenceDate)
        }

        let statusTitle: String
        let shortMessage: String

        if overdue.count > 0 {
            statusTitle = overdue.count == 1 ? "1 overdue" : "\(overdue.count) overdue"
            shortMessage = "Take a look as soon as you can."
        } else if dueSoon.count > 0 {
            statusTitle = dueSoon.count == 1 ? "1 due this week" : "\(dueSoon.count) due this week"
            shortMessage = "Stay on top of these in the next 7 days."
        } else if openReminders.isEmpty {
            statusTitle = "Nothing due"
            shortMessage = "No outstanding reminders yet."
        } else {
            statusTitle = "Nothing due"
            shortMessage = "Nothing overdue or due this week."
        }

        return ReminderOverview(
            overdueCount: overdue.count,
            dueSoonCount: dueSoon.count,
            totalOpenCount: openReminders.count,
            upcomingItems: snapshots,
            statusTitle: statusTitle,
            shortMessage: shortMessage
        )
    }

    static func urgency(for reminder: Reminder, on referenceDate: Date = .now) -> ReminderUrgency {
        if reminder.isCompleted { return .completed }
        guard let dueDate = reminder.dueDate else { return .undated }
        if dueDate < referenceDate { return .overdue }
        if dueDate <= referenceDate.addingTimeInterval(dueSoonWindow) { return .dueSoon }
        return .upcoming
    }

    private static func makeSnapshot(_ reminder: Reminder, on referenceDate: Date) -> ReminderSnapshot {
        ReminderSnapshot(
            id: reminder.id,
            title: reminder.title,
            dueDate: reminder.dueDate,
            completedAt: reminder.completedAt,
            kindRawValue: reminder.kindRawValue,
            priorityRawValue: reminder.priorityRawValue,
            urgency: urgency(for: reminder, on: referenceDate)
        )
    }
}
