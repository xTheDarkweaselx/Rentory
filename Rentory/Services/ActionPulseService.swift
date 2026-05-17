//
//  ActionPulseService.swift
//  Rentory
//
//  Created by Adam Ibrahim on 17/05/2026.
//

import Foundation

struct ActionPulseResult {
    let overdueCount: Int
    let dueSoonCount: Int
    let totalOpenCount: Int
    let upcomingItems: [ActionItemSnapshot]
    let statusTitle: String
    let shortMessage: String
}

struct ActionItemSnapshot: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let dueDate: Date?
    let completedAt: Date?
    let kindRawValue: String
    let priorityRawValue: String
    let urgency: ActionUrgency

    var kind: ActionKind {
        ActionKind(rawValue: kindRawValue) ?? .custom
    }

    var priority: ActionPriority {
        ActionPriority(rawValue: priorityRawValue) ?? .normal
    }
}

enum ActionUrgency: String, Sendable, Hashable {
    case overdue
    case dueSoon
    case upcoming
    case undated
    case completed
}

enum ActionPulseService {
    static let dueSoonWindow: TimeInterval = 7 * 24 * 60 * 60
    static let maxUpcomingItems = 5

    static func pulse(for propertyPack: PropertyPack, on referenceDate: Date = .now) -> ActionPulseResult {
        let openActions = propertyPack.actions.filter { !$0.isCompleted }
        let dueSoonCutoff = referenceDate.addingTimeInterval(dueSoonWindow)

        let overdue = openActions.filter { action in
            guard let dueDate = action.dueDate else { return false }
            return dueDate < referenceDate
        }
        let dueSoon = openActions.filter { action in
            guard let dueDate = action.dueDate else { return false }
            return dueDate >= referenceDate && dueDate <= dueSoonCutoff
        }

        let sortedOverdue = overdue.sorted { lhs, rhs in
            (lhs.dueDate ?? .distantPast) < (rhs.dueDate ?? .distantPast)
        }
        let sortedDueSoon = dueSoon.sorted { lhs, rhs in
            (lhs.dueDate ?? .distantFuture) < (rhs.dueDate ?? .distantFuture)
        }

        let topActions = (sortedOverdue + sortedDueSoon).prefix(maxUpcomingItems)
        let snapshots = topActions.map { action in
            makeSnapshot(action, on: referenceDate)
        }

        let statusTitle: String
        let shortMessage: String

        if overdue.count > 0 {
            statusTitle = overdue.count == 1 ? "1 overdue" : "\(overdue.count) overdue"
            shortMessage = "Take a look as soon as you can."
        } else if dueSoon.count > 0 {
            statusTitle = dueSoon.count == 1 ? "1 due this week" : "\(dueSoon.count) due this week"
            shortMessage = "Stay on top of these in the next 7 days."
        } else if openActions.isEmpty {
            statusTitle = "Nothing due"
            shortMessage = "No outstanding actions yet."
        } else {
            statusTitle = "Nothing due"
            shortMessage = "Nothing overdue or due this week."
        }

        return ActionPulseResult(
            overdueCount: overdue.count,
            dueSoonCount: dueSoon.count,
            totalOpenCount: openActions.count,
            upcomingItems: snapshots,
            statusTitle: statusTitle,
            shortMessage: shortMessage
        )
    }

    static func urgency(for action: ActionItem, on referenceDate: Date = .now) -> ActionUrgency {
        if action.isCompleted { return .completed }
        guard let dueDate = action.dueDate else { return .undated }
        if dueDate < referenceDate { return .overdue }
        if dueDate <= referenceDate.addingTimeInterval(dueSoonWindow) { return .dueSoon }
        return .upcoming
    }

    private static func makeSnapshot(_ action: ActionItem, on referenceDate: Date) -> ActionItemSnapshot {
        ActionItemSnapshot(
            id: action.id,
            title: action.title,
            dueDate: action.dueDate,
            completedAt: action.completedAt,
            kindRawValue: action.kindRawValue,
            priorityRawValue: action.priorityRawValue,
            urgency: urgency(for: action, on: referenceDate)
        )
    }
}
