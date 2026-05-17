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
    var manualConditionOverrideRawValue: String?

    @Relationship(deleteRule: .cascade) var checklistItems: [ChecklistItemRecord]

    var type: RoomType {
        get { RoomType(rawValue: typeRawValue) ?? .other }
        set { typeRawValue = newValue.rawValue }
    }

    var manualConditionOverride: EvidenceCondition? {
        get { manualConditionOverrideRawValue.flatMap(EvidenceCondition.init(rawValue:)) }
        set { manualConditionOverrideRawValue = newValue?.rawValue }
    }

    var aggregateCondition: EvidenceCondition {
        let conditions = checklistItems.flatMap { [$0.moveInCondition, $0.moveOutCondition] }
            .filter(\.contributesToAggregate)

        return conditions.max(by: { $0.aggregateSeverity < $1.aggregateSeverity }) ?? .notChecked
    }

    var displayCondition: EvidenceCondition {
        manualConditionOverride ?? aggregateCondition
    }

    init(
        id: UUID = UUID(),
        name: String,
        type: RoomType,
        sortOrder: Int,
        notes: String? = nil,
        manualConditionOverride: EvidenceCondition? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        checklistItems: [ChecklistItemRecord] = []
    ) {
        self.id = id
        self.name = name
        self.typeRawValue = type.rawValue
        self.notes = notes
        self.manualConditionOverrideRawValue = manualConditionOverride?.rawValue
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.checklistItems = checklistItems
    }
}
