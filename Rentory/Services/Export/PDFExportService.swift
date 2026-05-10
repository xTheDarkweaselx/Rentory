//
//  PDFExportService.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

struct PDFExportService {
    private let fileStorageService: FileStorageService
    private let reportBuilder: PDFReportBuilder

    init(
        fileStorageService: FileStorageService = FileStorageService(),
        reportBuilder: PDFReportBuilder = PDFReportBuilder()
    ) {
        self.fileStorageService = fileStorageService
        self.reportBuilder = reportBuilder
    }

    func createReport(for propertyPack: PropertyPack, options: ExportOptions) throws -> URL {
        try createReport(for: PDFReportSnapshot(propertyPack: propertyPack), options: options)
    }

    func createReport(for snapshot: PDFReportSnapshot, options: ExportOptions) throws -> URL {
        do {
            try? fileStorageService.cleanupOldTemporaryExports()
            let data = try reportBuilder.buildReportData(for: snapshot, options: options)
            return try fileStorageService.saveTemporaryExportData(
                data,
                preferredFileName: "rentory-report-\(UUID().uuidString.lowercased()).pdf"
            )
        } catch let error as PDFExportError {
            throw error
        } catch let error as FileStorageError {
            switch error {
            case .unableToWriteFile, .unableToCreateFolder:
                throw PDFExportError.unableToSaveReport
            default:
                throw PDFExportError.unableToCreateReport
            }
        } catch {
            throw PDFExportError.unableToCreateReport
        }
    }
}

struct PDFReportSnapshot: Sendable {
    let nickname: String
    let addressLine1: String?
    let addressLine2: String?
    let townCity: String?
    let postcode: String?
    let tenancyStartDate: Date?
    let tenancyEndDate: Date?
    let landlordOrAgentName: String?
    let landlordOrAgentEmail: String?
    let depositSchemeName: String?
    let depositReference: String?
    let rooms: [PDFReportRoomSnapshot]
    let documents: [PDFReportDocumentSnapshot]
    let timelineEvents: [PDFReportTimelineEventSnapshot]

    @MainActor
    init(propertyPack: PropertyPack) {
        nickname = propertyPack.nickname
        addressLine1 = propertyPack.addressLine1
        addressLine2 = propertyPack.addressLine2
        townCity = propertyPack.townCity
        postcode = propertyPack.postcode
        tenancyStartDate = propertyPack.tenancyStartDate
        tenancyEndDate = propertyPack.tenancyEndDate
        landlordOrAgentName = propertyPack.landlordOrAgentName
        landlordOrAgentEmail = propertyPack.landlordOrAgentEmail
        depositSchemeName = propertyPack.depositSchemeName
        depositReference = propertyPack.depositReference
        rooms = propertyPack.rooms.map(PDFReportRoomSnapshot.init(room:))
        documents = propertyPack.documents.map(PDFReportDocumentSnapshot.init(document:))
        timelineEvents = propertyPack.timelineEvents.map(PDFReportTimelineEventSnapshot.init(event:))
    }
}

struct PDFReportRoomSnapshot: Sendable {
    let name: String
    let sortOrder: Int
    let checklistItems: [PDFReportChecklistItemSnapshot]

    @MainActor
    init(room: RoomRecord) {
        name = room.name
        sortOrder = room.sortOrder
        checklistItems = room.checklistItems.map(PDFReportChecklistItemSnapshot.init(item:))
    }
}

struct PDFReportChecklistItemSnapshot: Sendable {
    let title: String
    let sortOrder: Int
    let moveInConditionRawValue: String
    let moveOutConditionRawValue: String
    let moveInNotes: String?
    let moveOutNotes: String?
    let photos: [PDFReportEvidencePhotoSnapshot]

    var moveInCondition: EvidenceCondition {
        EvidenceCondition(rawValue: moveInConditionRawValue) ?? .notChecked
    }

    var moveOutCondition: EvidenceCondition {
        EvidenceCondition(rawValue: moveOutConditionRawValue) ?? .notChecked
    }

    @MainActor
    init(item: ChecklistItemRecord) {
        title = item.title
        sortOrder = item.sortOrder
        moveInConditionRawValue = item.moveInConditionRawValue
        moveOutConditionRawValue = item.moveOutConditionRawValue
        moveInNotes = item.moveInNotes
        moveOutNotes = item.moveOutNotes
        photos = item.photos.map(PDFReportEvidencePhotoSnapshot.init(photo:))
    }
}

struct PDFReportEvidencePhotoSnapshot: Sendable {
    let localFileName: String
    let evidencePhaseRawValue: String
    let caption: String?
    let capturedAt: Date
    let includeInExport: Bool
    let sortOrder: Int

    var evidencePhase: EvidencePhase {
        EvidencePhase(rawValue: evidencePhaseRawValue) ?? .duringTenancy
    }

    @MainActor
    init(photo: EvidencePhoto) {
        localFileName = photo.localFileName
        evidencePhaseRawValue = photo.evidencePhaseRawValue
        caption = photo.caption
        capturedAt = photo.capturedAt
        includeInExport = photo.includeInExport
        sortOrder = photo.sortOrder
    }
}

struct PDFReportDocumentSnapshot: Sendable {
    let displayName: String
    let documentTypeRawValue: String
    let documentDate: Date?
    let addedAt: Date
    let includeInExport: Bool

    var documentType: DocumentType {
        DocumentType(rawValue: documentTypeRawValue) ?? .other
    }

    @MainActor
    init(document: DocumentRecord) {
        displayName = document.displayName
        documentTypeRawValue = document.documentTypeRawValue
        documentDate = document.documentDate
        addedAt = document.addedAt
        includeInExport = document.includeInExport
    }
}

struct PDFReportTimelineEventSnapshot: Sendable {
    let title: String
    let eventTypeRawValue: String
    let eventDate: Date
    let notes: String?
    let includeInExport: Bool

    var eventType: TimelineEventType {
        TimelineEventType(rawValue: eventTypeRawValue) ?? .other
    }

    @MainActor
    init(event: TimelineEvent) {
        title = event.title
        eventTypeRawValue = event.eventTypeRawValue
        eventDate = event.eventDate
        notes = event.notes
        includeInExport = event.includeInExport
    }
}
