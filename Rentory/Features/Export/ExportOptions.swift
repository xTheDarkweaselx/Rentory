//
//  ExportOptions.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

struct ExportOptions: Codable, Equatable, Sendable {
    var includePropertyName: Bool
    var includeTownOrPostcode: Bool
    var includeFullAddress: Bool
    var includeTenancyDates: Bool
    var includeLandlordOrAgentDetails: Bool
    var includeDepositDetails: Bool
    var includeRooms: Bool
    var includeChecklistNotes: Bool
    var includePhotos: Bool
    var includeDocumentsList: Bool
    var includeTimeline: Bool
    var includeTenancies: Bool
    var includeReminders: Bool
    var reportType: ReportType

    init(
        includePropertyName: Bool = true,
        includeTownOrPostcode: Bool = true,
        includeFullAddress: Bool = false,
        includeTenancyDates: Bool = true,
        includeLandlordOrAgentDetails: Bool = false,
        includeDepositDetails: Bool = false,
        includeRooms: Bool = true,
        includeChecklistNotes: Bool = true,
        includePhotos: Bool = true,
        includeDocumentsList: Bool = true,
        includeTimeline: Bool = true,
        includeTenancies: Bool = true,
        includeReminders: Bool = true,
        reportType: ReportType = .fullRecord
    ) {
        self.includePropertyName = includePropertyName
        self.includeTownOrPostcode = includeTownOrPostcode
        self.includeFullAddress = includeFullAddress
        self.includeTenancyDates = includeTenancyDates
        self.includeLandlordOrAgentDetails = includeLandlordOrAgentDetails
        self.includeDepositDetails = includeDepositDetails
        self.includeRooms = includeRooms
        self.includeChecklistNotes = includeChecklistNotes
        self.includePhotos = includePhotos
        self.includeDocumentsList = includeDocumentsList
        self.includeTimeline = includeTimeline
        self.includeTenancies = includeTenancies
        self.includeReminders = includeReminders
        self.reportType = reportType
    }
}

/// Shape of the generated report. Mirrors how a property is documented
/// over a tenancy — a check-in (baseline at move-in), a check-out
/// (condition at the end, compared to move-in), or the full record with
/// both side by side.
enum ReportType: String, Codable, CaseIterable, Sendable, Identifiable {
    case checkIn = "Check-in"
    case checkOut = "Check-out"
    case fullRecord = "Full record"

    var id: String { rawValue }

    var title: String { rawValue }

    /// One-line description shown beneath the picker.
    var summary: String {
        switch self {
        case .checkIn:
            return "Condition at move-in — the baseline for the tenancy."
        case .checkOut:
            return "Condition at move-out, compared against move-in."
        case .fullRecord:
            return "Everything on file: move-in and move-out side by side."
        }
    }

    /// Title printed on the report's cover page.
    var coverTitle: String {
        switch self {
        case .checkIn: return "Check-in report"
        case .checkOut: return "Check-out report"
        case .fullRecord: return "Rentory report"
        }
    }

    /// The report type that best fits a property's current stage — used as
    /// the initial selection so the common case (documenting the stage
    /// you're in) needs no extra tap. The user can still switch to any type.
    static func suggested(for stage: TenancyStage) -> ReportType {
        switch stage {
        case .moveIn: return .checkIn
        case .living: return .fullRecord
        case .moveOut: return .checkOut
        }
    }
}
