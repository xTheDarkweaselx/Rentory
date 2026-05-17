//
//  ActionItem.swift
//  Rentory
//
//  Created by Adam Ibrahim on 17/05/2026.
//

import Foundation
import SwiftData

@Model
final class ActionItem {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String?
    var dueDate: Date?
    var completedAt: Date?
    var kindRawValue: String = ActionKind.custom.rawValue
    var priorityRawValue: String = ActionPriority.normal.rawValue
    var createdAt: Date = Date.now
    var linkedRoomID: UUID?
    var linkedChecklistItemID: UUID?
    var linkedDocumentID: UUID?
    var linkedTimelineEventID: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        completedAt: Date? = nil,
        kind: ActionKind = .custom,
        priority: ActionPriority = .normal,
        createdAt: Date = .now,
        linkedRoomID: UUID? = nil,
        linkedChecklistItemID: UUID? = nil,
        linkedDocumentID: UUID? = nil,
        linkedTimelineEventID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.completedAt = completedAt
        self.kindRawValue = kind.rawValue
        self.priorityRawValue = priority.rawValue
        self.createdAt = createdAt
        self.linkedRoomID = linkedRoomID
        self.linkedChecklistItemID = linkedChecklistItemID
        self.linkedDocumentID = linkedDocumentID
        self.linkedTimelineEventID = linkedTimelineEventID
    }
}

extension ActionItem {
    var kind: ActionKind {
        get { ActionKind(rawValue: kindRawValue) ?? .custom }
        set { kindRawValue = newValue.rawValue }
    }

    var priority: ActionPriority {
        get { ActionPriority(rawValue: priorityRawValue) ?? .normal }
        set { priorityRawValue = newValue.rawValue }
    }

    var isCompleted: Bool {
        completedAt != nil
    }
}
