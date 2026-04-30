//
//  RoomRecord.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation
import SwiftData

@Model
final class RoomRecord {
    var id: UUID
    var name: String
    var typeRawValue: String
    var notes: String?
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade) var checklistItems: [ChecklistItemRecord]

    var type: RoomType {
        get { RoomType(rawValue: typeRawValue) ?? .other }
        set { typeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        type: RoomType,
        sortOrder: Int,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        checklistItems: [ChecklistItemRecord] = []
    ) {
        self.id = id
        self.name = name
        self.typeRawValue = type.rawValue
        self.notes = notes
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.checklistItems = checklistItems
    }
}
