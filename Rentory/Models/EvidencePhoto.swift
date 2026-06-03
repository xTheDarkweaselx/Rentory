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
    /// `true` when `capturedAt` is a real capture date — read from the
    /// photo's EXIF metadata, or stamped at the moment of an in-app
    /// camera capture. `false` when the date couldn't be determined and
    /// we fell back to the import time, so the UI and report can avoid
    /// presenting an invented date as if it were the capture date.
    /// Defaults to `false`; existing records migrate to `false` because
    /// their provenance is unknown.
    var captureDateIsConfirmed: Bool = false
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
        captureDateIsConfirmed: Bool = false,
        includeInExport: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.localFileName = localFileName
        self.caption = caption
        self.evidencePhaseRawValue = phase.rawValue
        self.capturedAt = capturedAt
        self.captureDateIsConfirmed = captureDateIsConfirmed
        self.includeInExport = includeInExport
        self.sortOrder = sortOrder
    }
}
