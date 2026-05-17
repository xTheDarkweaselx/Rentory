//
//  ItemComment.swift
//  Rentory
//
//  Created by Adam Ibrahim on 17/05/2026.
//

import Foundation
import SwiftData

@Model
final class ItemComment {
    var id: UUID = UUID()
    var body: String = ""
    var createdAt: Date = Date.now
    var evidencePhaseRawValue: String?
    var sortOrder: Int = 0

    init(
        id: UUID = UUID(),
        body: String,
        phase: EvidencePhase? = nil,
        createdAt: Date = .now,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.body = body
        self.evidencePhaseRawValue = phase?.rawValue
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}

extension ItemComment {
    var evidencePhase: EvidencePhase? {
        get { evidencePhaseRawValue.flatMap(EvidencePhase.init(rawValue:)) }
        set { evidencePhaseRawValue = newValue?.rawValue }
    }
}
