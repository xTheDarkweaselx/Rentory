//
//  TimelineEvent.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation
import SwiftData

@Model
final class TimelineEvent {
    var id: UUID
    var title: String
    var eventTypeRawValue: String
    var eventDate: Date
    var notes: String?
    var createdAt: Date
    var includeInExport: Bool

    var eventType: TimelineEventType {
        get { TimelineEventType(rawValue: eventTypeRawValue) ?? .other }
        set { eventTypeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        type: TimelineEventType,
        eventDate: Date,
        notes: String? = nil,
        createdAt: Date = .now,
        includeInExport: Bool = true
    ) {
        self.id = id
        self.title = title
        self.eventTypeRawValue = type.rawValue
        self.eventDate = eventDate
        self.notes = notes
        self.createdAt = createdAt
        self.includeInExport = includeInExport
    }
}
