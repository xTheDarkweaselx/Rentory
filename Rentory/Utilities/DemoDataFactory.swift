//
//  DemoDataFactory.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import Foundation
import SwiftData

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if DEBUG
@MainActor
struct DemoDataFactory {
    private let fileStorageService: FileStorageService
    private let photoStorageService: PhotoStorageService
    private let deletionService: RentoryDataDeletionService

    init() {
        self.init(fileStorageService: FileStorageService())
    }

    init(fileStorageService: FileStorageService) {
        self.fileStorageService = fileStorageService
        self.photoStorageService = PhotoStorageService(fileStorageService: fileStorageService)
        self.deletionService = RentoryDataDeletionService(fileStorageService: fileStorageService)
    }

    @discardableResult
    func loadDemoRecord(context: ModelContext) throws -> PropertyPack {
        if let existingDemoRecord = try fetchDemoRecords(context: context).first {
            DemoModeSettings.demoPropertyIdentifier = existingDemoRecord.id
            return existingDemoRecord
        }

        let propertyPack = PropertyPack(
            nickname: DemoModeSettings.demoRecordName,
            townCity: DemoModeSettings.demoTownCity,
            postcode: DemoModeSettings.demoPostcode,
            tenancyStartDate: demoDate(year: 2026, month: 1, day: 10),
            tenancyEndDate: demoDate(year: 2026, month: 12, day: 10),
            notes: DemoModeSettings.demoRecordNote
        )

        propertyPack.rooms = try makeRooms()
        propertyPack.documents = try makeDocuments()
        propertyPack.timelineEvents = makeTimelineEvents()

        context.insert(propertyPack)
        try context.save()
        DemoModeSettings.demoPropertyIdentifier = propertyPack.id
        return propertyPack
    }

    func clearDemoData(context: ModelContext) throws {
        let demoRecords = try fetchDemoRecords(context: context)

        for propertyPack in demoRecords {
            try deletionService.deletePropertyPack(propertyPack, context: context)
        }

        DemoModeSettings.demoPropertyIdentifier = nil
    }

    private func fetchDemoRecords(context: ModelContext) throws -> [PropertyPack] {
        try context.fetch(FetchDescriptor<PropertyPack>())
            .filter(DemoModeSettings.matchesDemoRecord)
    }

    private func makeRooms() throws -> [RoomRecord] {
        let roomDefinitions: [(String, RoomType)] = [
            ("Kitchen", .kitchen),
            ("Living room", .livingRoom),
            ("Bedroom", .bedroom),
            ("Bathroom", .bathroom),
            ("Hallway", .hallway),
        ]

        let roomNotes = [
            "Condition checked during move-in.",
            "Small mark noted on the wall.",
            "Photo added for reference.",
            "No further notes added.",
            "Small mark noted on the wall.",
        ]

        return try roomDefinitions.enumerated().map { index, roomDefinition in
            let checklistItems = try makeChecklistItems(
                for: roomDefinition.1,
                roomName: roomDefinition.0,
                roomIndex: index
            )

            return RoomRecord(
                name: roomDefinition.0,
                type: roomDefinition.1,
                sortOrder: index,
                notes: roomNotes[index],
                checklistItems: checklistItems
            )
        }
    }

    private func makeChecklistItems(for roomType: RoomType, roomName: String, roomIndex: Int) throws -> [ChecklistItemRecord] {
        let titles = RoomTemplateService.defaultChecklistTitles(for: roomType)
        let moveInConditions: [EvidenceCondition] = [.good, .fair, .notChecked, .damaged, .notApplicable]
        let sampleNotes = [
            "Condition checked during move-in.",
            "Small mark noted on the wall.",
            "Photo added for reference.",
            "No further notes added.",
        ]

        return try titles.enumerated().map { itemIndex, title in
            let condition = moveInConditions[(roomIndex + itemIndex) % moveInConditions.count]
            let item = ChecklistItemRecord(
                title: title,
                sortOrder: itemIndex,
                moveInConditionRawValue: condition.rawValue,
                moveOutConditionRawValue: EvidenceCondition.notChecked.rawValue,
                moveInNotes: itemIndex < sampleNotes.count ? sampleNotes[itemIndex] : nil,
                moveOutNotes: nil,
                isFlagged: condition == .damaged
            )

            if itemIndex == 0 {
                item.photos = try makeSamplePhotos(for: roomName)
            }

            return item
        }
    }

    private func makeSamplePhotos(for roomName: String) throws -> [EvidencePhoto] {
        let samples: [(EvidencePhase, String, DemoPhotoColour)] = [
            (.moveIn, "\(roomName) sample photo", .softBlue),
            (.duringTenancy, "\(roomName) follow-up photo", .softGreen),
            (.moveOut, "\(roomName) move-out photo", .softSand),
        ]

        return try samples.enumerated().map { index, sample in
            let image = makeSampleImage(title: sample.1, subtitle: sample.0.rawValue, colour: sample.2)
            let fileName = try photoStorageService.savePhoto(image)

            return EvidencePhoto(
                localFileName: fileName,
                phase: sample.0,
                caption: sample.1,
                capturedAt: demoDate(year: 2026, month: 1, day: 10 + index),
                sortOrder: index
            )
        }
    }

    private func makeDocuments() throws -> [DocumentRecord] {
        let documents: [(String, DocumentType)] = [
            ("Sample tenancy agreement", .tenancyAgreement),
            ("Sample check-in inventory", .checkInInventory),
            ("Sample cleaning receipt", .cleaningReceipt),
            ("Sample meter reading", .meterReading),
        ]

        return try documents.enumerated().map { index, document in
            let fileName = try fileStorageService.saveDocumentData(
                makeSampleDocumentData(title: document.0),
                fileExtension: "txt"
            )

            return DocumentRecord(
                displayName: document.0,
                type: document.1,
                localFileName: fileName,
                notes: "Sample document for testing and screenshots.",
                documentDate: demoDate(year: 2026, month: 1, day: 12 + index)
            )
        }
    }

    private func makeTimelineEvents() -> [TimelineEvent] {
        let events: [(String, TimelineEventType, String)] = [
            ("Move-in", .moveIn, "Move-in date added for the sample record."),
            ("Inventory reviewed", .inventoryReviewed, "Inventory checked against the sample record."),
            ("Issue noticed", .issueNoticed, "Small mark noted in the kitchen for reference."),
            ("Repair requested", .repairRequested, "Repair request logged as part of the sample timeline."),
            ("Repair completed", .repairCompleted, "Repair completion noted for the sample record."),
            ("Move-out", .moveOut, "Move-out date added for the sample record."),
        ]

        return events.enumerated().map { index, event in
            TimelineEvent(
                title: event.0,
                type: event.1,
                eventDate: demoDate(year: 2026, month: 1, day: 10 + index * 12),
                notes: event.2
            )
        }
    }

    private func makeSampleDocumentData(title: String) -> Data {
        let text = [
            "Sample document",
            "",
            title,
            "",
            "This file contains fake content for testing, screenshots and App Review.",
            "It does not contain a real address, name, agreement or deposit reference.",
        ].joined(separator: "\n")

        return Data(text.utf8)
    }

    private func demoDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.year = year
        components.month = month
        components.day = day
        return components.date ?? .now
    }
}

private enum DemoPhotoColour {
    case softBlue
    case softGreen
    case softSand

    var cgColor: CGColor {
        switch self {
        case .softBlue:
            return CGColor(red: 0.80, green: 0.89, blue: 0.98, alpha: 1)
        case .softGreen:
            return CGColor(red: 0.82, green: 0.94, blue: 0.88, alpha: 1)
        case .softSand:
            return CGColor(red: 0.95, green: 0.90, blue: 0.80, alpha: 1)
        }
    }
}

#if canImport(UIKit)
private func makeSampleImage(title: String, subtitle: String, colour: DemoPhotoColour) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1600, height: 1200))
    return renderer.image { context in
        let bounds = CGRect(origin: .zero, size: CGSize(width: 1600, height: 1200))
        let cgContext = context.cgContext
        cgContext.setFillColor(colour.cgColor)
        cgContext.fill(bounds)

        let innerRect = bounds.insetBy(dx: 70, dy: 70)
        let path = UIBezierPath(roundedRect: innerRect, cornerRadius: 48)
        UIColor.white.withAlphaComponent(0.72).setFill()
        path.fill()

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 82, weight: .semibold),
            .foregroundColor: UIColor.black.withAlphaComponent(0.82),
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 44, weight: .regular),
            .foregroundColor: UIColor.black.withAlphaComponent(0.64),
        ]

        title.draw(in: CGRect(x: 130, y: 380, width: 1340, height: 120), withAttributes: titleAttributes)
        subtitle.draw(in: CGRect(x: 130, y: 520, width: 1340, height: 80), withAttributes: subtitleAttributes)
    }
}
#elseif canImport(AppKit)
private func makeSampleImage(title: String, subtitle: String, colour: DemoPhotoColour) -> UIImage {
    let size = NSSize(width: 1600, height: 1200)
    let image = NSImage(size: size)
    image.lockFocus()
    defer { image.unlockFocus() }

    let bounds = NSRect(origin: .zero, size: size)
    NSGraphicsContext.current?.cgContext.setFillColor(colour.cgColor)
    NSGraphicsContext.current?.cgContext.fill(bounds)

    let innerRect = bounds.insetBy(dx: 70, dy: 70)
    let panel = NSBezierPath(roundedRect: innerRect, xRadius: 48, yRadius: 48)
    NSColor.white.withAlphaComponent(0.72).setFill()
    panel.fill()

    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 82, weight: .semibold),
        .foregroundColor: NSColor.black.withAlphaComponent(0.82),
    ]
    let subtitleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 44, weight: .regular),
        .foregroundColor: NSColor.black.withAlphaComponent(0.64),
    ]

    title.draw(in: NSRect(x: 130, y: 620, width: 1340, height: 120), withAttributes: titleAttributes)
    subtitle.draw(in: NSRect(x: 130, y: 520, width: 1340, height: 80), withAttributes: subtitleAttributes)

    return image
}
#endif
#endif
