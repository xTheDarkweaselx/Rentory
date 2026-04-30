//
//  ChecklistItemRecord.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation
import SwiftData

@Model
final class ChecklistItemRecord {
    var id: UUID
    var title: String
    var category: String?
    var moveInConditionRawValue: String
    var moveOutConditionRawValue: String
    var moveInNotes: String?
    var moveOutNotes: String?
    var isFlagged: Bool
    var sortOrder: Int
    var updatedAt: Date

    @Relationship(deleteRule: .cascade) var photos: [EvidencePhoto]

    var moveInCondition: EvidenceCondition {
        get { EvidenceCondition(rawValue: moveInConditionRawValue) ?? .notChecked }
        set { moveInConditionRawValue = newValue.rawValue }
    }

    var moveOutCondition: EvidenceCondition {
        get { EvidenceCondition(rawValue: moveOutConditionRawValue) ?? .notChecked }
        set { moveOutConditionRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        sortOrder: Int,
        category: String? = nil,
        moveInConditionRawValue: String = EvidenceCondition.notChecked.rawValue,
        moveOutConditionRawValue: String = EvidenceCondition.notChecked.rawValue,
        moveInNotes: String? = nil,
        moveOutNotes: String? = nil,
        isFlagged: Bool = false,
        updatedAt: Date = .now,
        photos: [EvidencePhoto] = []
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.moveInConditionRawValue = moveInConditionRawValue
        self.moveOutConditionRawValue = moveOutConditionRawValue
        self.moveInNotes = moveInNotes
        self.moveOutNotes = moveOutNotes
        self.isFlagged = isFlagged
        self.sortOrder = sortOrder
        self.updatedAt = updatedAt
        self.photos = photos
    }
}
