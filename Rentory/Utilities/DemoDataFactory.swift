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

@MainActor
struct DemoDataFactory {
    enum SampleDataStyle {
        case singleRecord
        case fullSampleSet
    }

    struct LoadProgress: Equatable {
        let completedRecords: Int
        let totalRecords: Int
        let stageDescription: String

        var fractionCompleted: Double {
            guard totalRecords > 0 else { return 0 }
            return Double(completedRecords) / Double(totalRecords)
        }
    }

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
        let records = try loadSampleData(context: context, style: .singleRecord)
        if let firstRecord = records.first {
            return firstRecord
        }
        return try makePrimaryRecord()
    }

    @discardableResult
    func loadSampleData(context: ModelContext, style: SampleDataStyle) throws -> [PropertyPack] {
        var existingDemoRecords = try fetchDemoRecords(context: context)
        if !existingDemoRecords.isEmpty {
            let needsFullSampleRefresh = style == .fullSampleSet && existingDemoRecords.count < sampleRecordMakers(for: .fullSampleSet).count
            if !needsFullSampleRefresh {
                DemoModeSettings.demoPropertyIdentifier = existingDemoRecords.first?.id
                return existingDemoRecords
            }

            try clearDemoData(context: context)
            existingDemoRecords = []
        }

        let records = try sampleRecordMakers(for: style).map { try $0() }

        for record in records {
            context.insert(record)
        }

        try context.save()
        DemoModeSettings.demoPropertyIdentifier = records.first?.id
        return records
    }

    @discardableResult
    func loadSampleData(
        context: ModelContext,
        style: SampleDataStyle,
        progress: @escaping @MainActor (LoadProgress) -> Void
    ) async throws -> [PropertyPack] {
        let makers = sampleRecordMakers(for: style)
        var loadedRecords: [PropertyPack] = []

        progress(LoadProgress(completedRecords: 0, totalRecords: makers.count, stageDescription: "Checking for existing example records."))
        await Task.yield()

        do {
            var existingDemoRecords = try fetchDemoRecords(context: context)
            if !existingDemoRecords.isEmpty {
                let needsFullSampleRefresh = style == .fullSampleSet && existingDemoRecords.count < sampleRecordMakers(for: .fullSampleSet).count
                if !needsFullSampleRefresh {
                    DemoModeSettings.demoPropertyIdentifier = existingDemoRecords.first?.id
                    progress(LoadProgress(completedRecords: existingDemoRecords.count, totalRecords: existingDemoRecords.count, stageDescription: "Example records are already ready."))
                    return existingDemoRecords
                }

                progress(LoadProgress(completedRecords: 0, totalRecords: makers.count, stageDescription: "Refreshing the existing example records."))
                try clearDemoData(context: context)
                existingDemoRecords = []
                _ = existingDemoRecords
                await Task.yield()
            }

            for (index, maker) in makers.enumerated() {
                try Task.checkCancellation()
                let stage = "Creating \(sampleRecordNames(for: style)[index])."
                progress(LoadProgress(completedRecords: index, totalRecords: makers.count, stageDescription: stage))
                await Task.yield()

                let record = try maker()
                context.insert(record)
                try context.save()
                loadedRecords.append(record)

                if DemoModeSettings.demoPropertyIdentifier == nil {
                    DemoModeSettings.demoPropertyIdentifier = record.id
                }

                progress(LoadProgress(completedRecords: index + 1, totalRecords: makers.count, stageDescription: "Saved \(record.nickname)."))
                await Task.yield()
            }

            return loadedRecords
        } catch is CancellationError {
            try? clearDemoData(context: context)
            throw CancellationError()
        } catch {
            try? clearDemoData(context: context)
            throw error
        }
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

    private func sampleRecordMakers(for style: SampleDataStyle) -> [() throws -> PropertyPack] {
        switch style {
        case .singleRecord:
            return [makePrimaryRecord]
        case .fullSampleSet:
            return [
                makePrimaryRecord,
                makeSharedHomeRecord,
                makeFamilyHouseRecord,
                makeApartmentRecord,
                makeGarageRecord,
                makeAnnexRecord,
                makeStudioRecord,
                makeArchivedRecord,
            ]
        }
    }

    private func sampleRecordNames(for style: SampleDataStyle) -> [String] {
        switch style {
        case .singleRecord:
            return ["the main example record"]
        case .fullSampleSet:
            return [
                "the main example record",
                "the shared flat example",
                "the family house example",
                "the apartment example",
                "the storage garage example",
                "the garden annex example",
                "the compact rented space example",
                "the previous tenancy example",
            ]
        }
    }

    private func makePrimaryRecord() throws -> PropertyPack {
        try makePropertyRecord(
            nickname: DemoModeSettings.demoRecordName,
            recordType: .house,
            isFavourite: true,
            addressLine1: "14 Sample Street",
            townCity: DemoModeSettings.demoTownCity,
            postcode: DemoModeSettings.demoPostcode,
            tenancyStartDate: demoDate(year: 2026, month: 1, day: 10),
            tenancyEndDate: demoDate(year: 2026, month: 12, day: 10),
            landlordOrAgentName: "Sample Lettings",
            landlordOrAgentEmail: "hello@samplelettings.test",
            depositSchemeName: "Sample Deposit Scheme",
            depositReference: "SAMPLE-4582",
            notes: [
                DemoModeSettings.demoMarker,
                DemoModeSettings.demoRecordNote,
                "Includes rooms, photos, documents and timeline events for testing.",
            ].joined(separator: "\n\n"),
            roomDefinitions: [
                ("Kitchen", .kitchen),
                ("Living room", .livingRoom),
                ("Bedroom", .bedroom),
                ("Bathroom", .bathroom),
                ("Hallway", .hallway),
                ("Garden", .garden),
            ],
            documentDefinitions: [
                ("Sample tenancy agreement", .tenancyAgreement),
                ("Sample deposit certificate", .depositCertificate),
                ("Sample check-in inventory", .checkInInventory),
                ("Sample cleaning receipt", .cleaningReceipt),
                ("Sample meter reading", .meterReading),
                ("Sample message screenshot", .messageScreenshot),
            ],
            timelineDefinitions: [
                ("Move-in", .moveIn, "Move-in date added for the sample record."),
                ("Inventory reviewed", .inventoryReviewed, "Inventory checked against the sample record."),
                ("Issue noticed", .issueNoticed, "A small mark was noted in the kitchen for reference."),
                ("Issue reported", .issueReported, "The issue was reported to the letting agent."),
                ("Repair requested", .repairRequested, "A repair request was logged as part of the sample timeline."),
                ("Repair completed", .repairCompleted, "The repair was marked as completed."),
                ("Inspection", .inspection, "A mid-tenancy inspection was noted for reference."),
                ("Move-out", .moveOut, "Move-out date added for the sample record."),
            ]
        )
    }

    private func makeSharedHomeRecord() throws -> PropertyPack {
        try makePropertyRecord(
            nickname: "Shared flat sample",
            recordType: .flat,
            isFavourite: true,
            buildingName: "Example Terrace",
            spaceIdentifier: "Flat 2B",
            floorLevel: "2",
            addressLine1: "8 Example Terrace",
            townCity: "Riverford",
            postcode: "EF3 4GH",
            tenancyStartDate: demoDate(year: 2025, month: 9, day: 2),
            tenancyEndDate: nil,
            landlordOrAgentName: "North Street Homes",
            landlordOrAgentEmail: "team@northstreethomes.test",
            depositSchemeName: "Shared Home Deposit Scheme",
            depositReference: "SHARED-1042",
            notes: [
                DemoModeSettings.demoMarker,
                "This shared home sample shows an active tenancy with ongoing notes and fewer rooms.",
            ].joined(separator: "\n\n"),
            roomDefinitions: [
                ("Bedroom", .bedroom),
                ("Kitchen", .kitchen),
                ("Bathroom", .bathroom),
                ("Hallway", .hallway),
            ],
            documentDefinitions: [
                ("Shared home agreement", .tenancyAgreement),
                ("Sample rent payment record", .rentPaymentRecord),
                ("Sample repair receipt", .repairReceipt),
            ],
            timelineDefinitions: [
                ("Move-in", .moveIn, "Move-in added for the shared home sample."),
                ("Issue noticed", .issueNoticed, "A loose cupboard handle was noted."),
                ("Repair requested", .repairRequested, "A repair request was sent for the shared kitchen."),
                ("Cleaning completed", .cleaningCompleted, "A shared-area clean was recorded."),
            ]
        )
    }

    private func makeArchivedRecord() throws -> PropertyPack {
        let record = try makePropertyRecord(
            nickname: "Previous student flat",
            recordType: .flat,
            buildingName: "College Mews",
            spaceIdentifier: "Flat 4",
            floorLevel: "1",
            addressLine1: "2 College Mews",
            townCity: "Oakford",
            postcode: "JK5 6LM",
            tenancyStartDate: demoDate(year: 2024, month: 9, day: 1),
            tenancyEndDate: demoDate(year: 2025, month: 6, day: 30),
            landlordOrAgentName: "Campus Homes",
            landlordOrAgentEmail: "support@campushomes.test",
            depositSchemeName: "Student Deposit Scheme",
            depositReference: "STUDENT-8891",
            notes: [
                DemoModeSettings.demoMarker,
                "This sample record is archived to show how an earlier rented home can still be kept for reference.",
            ].joined(separator: "\n\n"),
            roomDefinitions: [
                ("Bedroom", .bedroom),
                ("Ensuite", .ensuite),
                ("Kitchen", .kitchen),
            ],
            documentDefinitions: [
                ("Sample check-out report", .checkOutReport),
                ("Sample deposit discussion", .other),
            ],
            timelineDefinitions: [
                ("Move-in", .moveIn, "Move-in added for the archived sample."),
                ("Inspection", .inspection, "An inspection note was added during the tenancy."),
                ("Deposit discussion", .depositDiscussion, "Deposit conversations were tracked before move-out."),
                ("Move-out", .moveOut, "Move-out added for the archived sample."),
            ]
        )
        record.isArchived = true
        return record
    }

    private func makeFamilyHouseRecord() throws -> PropertyPack {
        try makePropertyRecord(
            nickname: "Family house sample",
            recordType: .house,
            addressLine1: "22 Orchard Lane",
            townCity: "Westbridge",
            postcode: "MN7 8PQ",
            tenancyStartDate: demoDate(year: 2025, month: 2, day: 14),
            tenancyEndDate: demoDate(year: 2027, month: 2, day: 13),
            landlordOrAgentName: "Oak & Key Lettings",
            landlordOrAgentEmail: "homes@oakandkey.test",
            depositSchemeName: "Home Deposit Protection",
            depositReference: "HOUSE-6630",
            notes: [
                DemoModeSettings.demoMarker,
                "This house sample shows a fuller family-style rented home with more rooms, more paperwork and a longer timeline.",
            ].joined(separator: "\n\n"),
            roomDefinitions: [
                ("Living room", .livingRoom),
                ("Kitchen", .kitchen),
                ("Bedroom 1", .bedroom),
                ("Bedroom 2", .bedroom),
                ("Bathroom", .bathroom),
                ("Utility", .utility),
                ("Garden", .garden),
                ("Garage", .garage),
            ],
            documentDefinitions: [
                ("House tenancy agreement", .tenancyAgreement),
                ("House deposit certificate", .depositCertificate),
                ("House check-in inventory", .checkInInventory),
                ("House rent payment record", .rentPaymentRecord),
                ("House repair receipt", .repairReceipt),
                ("House message screenshot", .messageScreenshot),
                ("House meter reading", .meterReading),
            ],
            timelineDefinitions: [
                ("Move-in", .moveIn, "Move-in added for the family house sample."),
                ("Inventory reviewed", .inventoryReviewed, "The inventory was reviewed at the start of the tenancy."),
                ("Issue noticed", .issueNoticed, "A mark on the hallway wall was noted."),
                ("Issue reported", .issueReported, "The hallway mark was reported to the letting agent."),
                ("Repair requested", .repairRequested, "A repair request was logged for a loose utility-room shelf."),
                ("Repair completed", .repairCompleted, "The utility-room repair was completed."),
                ("Inspection", .inspection, "A routine inspection was noted."),
                ("Cleaning completed", .cleaningCompleted, "A full clean was logged before a family visit."),
                ("Deposit discussion", .depositDiscussion, "A deposit query was noted for later reference."),
            ]
        )
    }

    private func makeApartmentRecord() throws -> PropertyPack {
        try makePropertyRecord(
            nickname: "Apartment sample",
            recordType: .apartment,
            buildingName: "Canal Point",
            spaceIdentifier: "Apartment 18",
            floorLevel: "5",
            addressLine1: "18 Canal Point",
            townCity: "Eastbank",
            postcode: "AP1 8RT",
            tenancyStartDate: demoDate(year: 2026, month: 3, day: 1),
            tenancyEndDate: nil,
            landlordOrAgentName: "Canal Living",
            landlordOrAgentEmail: "hello@canalliving.test",
            depositSchemeName: "Apartment Deposit Scheme",
            depositReference: "APT-1805",
            notes: [
                DemoModeSettings.demoMarker,
                "This apartment sample includes block, apartment and floor details so the type-specific fields are visible.",
            ].joined(separator: "\n\n"),
            roomDefinitions: [
                ("Open-plan living area", .livingRoom),
                ("Kitchen", .kitchen),
                ("Bedroom", .bedroom),
                ("Bathroom", .bathroom),
                ("Balcony", .garden),
            ],
            documentDefinitions: [
                ("Apartment tenancy agreement", .tenancyAgreement),
                ("Apartment check-in inventory", .checkInInventory),
                ("Apartment meter reading", .meterReading),
            ],
            timelineDefinitions: [
                ("Move-in", .moveIn, "Move-in added for the apartment sample."),
                ("Inventory reviewed", .inventoryReviewed, "Inventory checked for the apartment sample."),
                ("Inspection", .inspection, "Building inspection access was noted."),
            ]
        )
    }

    private func makeGarageRecord() throws -> PropertyPack {
        try makePropertyRecord(
            nickname: "Storage garage sample",
            recordType: .garage,
            spaceIdentifier: "Garage 12",
            accessDetails: "Key fob for the main gate, manual lock on the garage door.",
            addressLine1: "Rear of 6 Station Yard",
            townCity: "Northmere",
            postcode: "GA2 4GE",
            tenancyStartDate: demoDate(year: 2026, month: 2, day: 5),
            tenancyEndDate: nil,
            landlordOrAgentName: "Station Yard Storage",
            landlordOrAgentEmail: "storage@stationyard.test",
            depositSchemeName: nil,
            depositReference: nil,
            notes: [
                DemoModeSettings.demoMarker,
                "This storage garage sample shows how Rentory can track a rented garage or parking space.",
            ].joined(separator: "\n\n"),
            roomDefinitions: [
                ("Garage space", .garage),
                ("Access area", .other),
            ],
            documentDefinitions: [
                ("Garage rental agreement", .tenancyAgreement),
                ("Garage access note", .other),
            ],
            timelineDefinitions: [
                ("Move-in", .moveIn, "Keys and access were received."),
                ("Issue noticed", .issueNoticed, "Small dent noted on the garage door."),
                ("Issue reported", .issueReported, "Garage door dent reported for the record."),
            ]
        )
    }

    private func makeAnnexRecord() throws -> PropertyPack {
        try makePropertyRecord(
            nickname: "Garden annex sample",
            recordType: .annex,
            isFavourite: true,
            mainPropertyName: "Rose House",
            accessDetails: "Side gate access with shared bins near the main house.",
            addressLine1: "Rose House Annex",
            townCity: "Meadowford",
            postcode: "AN6 2EX",
            tenancyStartDate: demoDate(year: 2025, month: 7, day: 20),
            tenancyEndDate: nil,
            landlordOrAgentName: "Private landlord sample",
            landlordOrAgentEmail: "rosehouse@landlord.test",
            depositSchemeName: "Annex Deposit Protection",
            depositReference: "ANNEX-9204",
            notes: [
                DemoModeSettings.demoMarker,
                "This annex sample shows the main house and shared access fields.",
            ].joined(separator: "\n\n"),
            roomDefinitions: [
                ("Living area", .livingRoom),
                ("Kitchenette", .kitchen),
                ("Bedroom", .bedroom),
                ("Shower room", .bathroom),
            ],
            documentDefinitions: [
                ("Annex agreement", .tenancyAgreement),
                ("Annex inventory", .checkInInventory),
                ("Shared access note", .other),
            ],
            timelineDefinitions: [
                ("Move-in", .moveIn, "Move-in added for the annex sample."),
                ("Cleaning completed", .cleaningCompleted, "Annex clean was logged."),
                ("Deposit discussion", .depositDiscussion, "Deposit note added for the annex."),
            ]
        )
    }

    private func makeStudioRecord() throws -> PropertyPack {
        try makePropertyRecord(
            nickname: "Other rented space sample",
            recordType: .other,
            buildingName: "Market Court",
            spaceIdentifier: "Studio room",
            accessDetails: "Shared entrance, private internal door and separate meter cupboard.",
            addressLine1: "4 Market Court",
            townCity: "Southmere",
            postcode: "RS2 3TU",
            tenancyStartDate: demoDate(year: 2026, month: 4, day: 3),
            tenancyEndDate: nil,
            landlordOrAgentName: "City Rooms",
            landlordOrAgentEmail: "support@cityrooms.test",
            depositSchemeName: "Studio Deposit Cover",
            depositReference: "STUDIO-1450",
            notes: [
                DemoModeSettings.demoMarker,
                "This compact sample helps show how Rentory can still work well for a smaller rented home.",
            ].joined(separator: "\n\n"),
            roomDefinitions: [
                ("Living / sleeping area", .other),
                ("Kitchen", .kitchen),
                ("Bathroom", .bathroom),
            ],
            documentDefinitions: [
                ("Studio agreement", .tenancyAgreement),
                ("Studio check-in inventory", .checkInInventory),
                ("Studio cleaning receipt", .cleaningReceipt),
            ],
            timelineDefinitions: [
                ("Move-in", .moveIn, "Move-in added for the studio sample."),
                ("Issue noticed", .issueNoticed, "A scuff near the window was noted."),
                ("Inspection", .inspection, "A short inspection visit was recorded."),
            ]
        )
    }

    private func makeLodgerRoomRecord() throws -> PropertyPack {
        try makePropertyRecord(
            nickname: "Lodger room sample",
            addressLine1: "11 Cedar Road",
            townCity: "Highfield",
            postcode: "VW4 5XY",
            tenancyStartDate: demoDate(year: 2025, month: 11, day: 8),
            tenancyEndDate: nil,
            landlordOrAgentName: "Private landlord sample",
            landlordOrAgentEmail: "host@privatelandlord.test",
            depositSchemeName: "Room Deposit Cover",
            depositReference: "ROOM-3201",
            notes: [
                DemoModeSettings.demoMarker,
                "This lodger-room sample shows a simpler setup with one main room, shared spaces and lighter paperwork.",
            ].joined(separator: "\n\n"),
            roomDefinitions: [
                ("Bedroom", .bedroom),
                ("Bathroom", .bathroom),
                ("Kitchen", .kitchen),
            ],
            documentDefinitions: [
                ("Room agreement", .tenancyAgreement),
                ("Room inventory note", .checkInInventory),
                ("Utility reading note", .meterReading),
            ],
            timelineDefinitions: [
                ("Move-in", .moveIn, "Move-in added for the lodger-room sample."),
                ("Issue noticed", .issueNoticed, "A small scratch on the desk was noted."),
                ("Cleaning completed", .cleaningCompleted, "A room clean was logged for reference."),
            ]
        )
    }

    private func makePropertyRecord(
        nickname: String,
        recordType: PropertyRecordType = .house,
        isFavourite: Bool = false,
        buildingName: String? = nil,
        spaceIdentifier: String? = nil,
        floorLevel: String? = nil,
        mainPropertyName: String? = nil,
        accessDetails: String? = nil,
        addressLine1: String,
        townCity: String,
        postcode: String,
        tenancyStartDate: Date?,
        tenancyEndDate: Date?,
        landlordOrAgentName: String?,
        landlordOrAgentEmail: String?,
        depositSchemeName: String?,
        depositReference: String?,
        notes: String,
        roomDefinitions: [(String, RoomType)],
        documentDefinitions: [(String, DocumentType)],
        timelineDefinitions: [(String, TimelineEventType, String)]
    ) throws -> PropertyPack {
        let propertyPack = PropertyPack(
            nickname: nickname,
            recordType: recordType,
            isFavourite: isFavourite,
            addressLine1: addressLine1,
            townCity: townCity,
            postcode: postcode,
            buildingName: buildingName,
            spaceIdentifier: spaceIdentifier,
            floorLevel: floorLevel,
            mainPropertyName: mainPropertyName,
            accessDetails: accessDetails,
            tenancyStartDate: tenancyStartDate,
            tenancyEndDate: tenancyEndDate,
            landlordOrAgentName: landlordOrAgentName,
            landlordOrAgentEmail: landlordOrAgentEmail,
            depositSchemeName: depositSchemeName,
            depositReference: depositReference,
            notes: notes
        )

        propertyPack.rooms = try makeRooms(roomDefinitions: roomDefinitions)
        propertyPack.documents = try makeDocuments(definitions: documentDefinitions)
        propertyPack.timelineEvents = makeTimelineEvents(definitions: timelineDefinitions)
        return propertyPack
    }

    private func makeRooms(roomDefinitions: [(String, RoomType)]) throws -> [RoomRecord] {
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
                notes: roomNotes[index % roomNotes.count],
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

            if itemIndex < 2 {
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

    private func makeDocuments(definitions: [(String, DocumentType)]) throws -> [DocumentRecord] {
        try definitions.enumerated().map { index, document in
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

    private func makeTimelineEvents(definitions: [(String, TimelineEventType, String)]) -> [TimelineEvent] {
        definitions.enumerated().map { index, event in
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
    let imageSize = CGSize(width: 1600, height: 1200)
    let renderer = UIGraphicsImageRenderer(size: imageSize)
    return renderer.image { context in
        let bounds = CGRect(origin: .zero, size: imageSize)
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
