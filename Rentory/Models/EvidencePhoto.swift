//
//  EvidencePhoto.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation
import SwiftData

@Model
final class EvidencePhoto {
    var id: UUID
    // Store a generated local file name only. Never store an absolute path or original photo library name.
    var localFileName: String
    var caption: String?
    var evidencePhaseRawValue: String
    var capturedAt: Date
    var includeInExport: Bool
    var sortOrder: Int

    var evidencePhase: EvidencePhase {
        get { EvidencePhase(rawValue: evidencePhaseRawValue) ?? .duringTenancy }
        set { evidencePhaseRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        localFileName: String,
        phase: EvidencePhase,
        caption: String? = nil,
        capturedAt: Date = .now,
        includeInExport: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.localFileName = localFileName
        self.caption = caption
        self.evidencePhaseRawValue = phase.rawValue
        self.capturedAt = capturedAt
        self.includeInExport = includeInExport
        self.sortOrder = sortOrder
    }
}
