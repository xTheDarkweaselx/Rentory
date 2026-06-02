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
    func loadSampleData(
        context: ModelContext,
        profile: RentoryUserProfile = .renter,
        style: SampleDataStyle
    ) throws -> [PropertyPack] {
        var existingDemoRecords = try fetchDemoRecords(context: context, profile: profile)
        if !existingDemoRecords.isEmpty {
            let needsFullSampleRefresh = style == .fullSampleSet && existingDemoRecords.count < sampleRecordMakers(for: .fullSampleSet, profile: profile).count
            if !needsFullSampleRefresh {
                DemoModeSettings.demoPropertyIdentifier = existingDemoRecords.first?.id
                return existingDemoRecords
            }

            try clearDemoData(context: context, profile: profile)
            existingDemoRecords = []
        }

        let records = try sampleRecordMakers(for: style, profile: profile).map { try $0() }

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
        profile: RentoryUserProfile = .renter,
        style: SampleDataStyle,
        progress: @escaping @MainActor (LoadProgress) -> Void
    ) async throws -> [PropertyPack] {
        let makers = sampleRecordMakers(for: style, profile: profile)
        var loadedRecords: [PropertyPack] = []

        progress(LoadProgress(completedRecords: 0, totalRecords: makers.count, stageDescription: "Checking for existing example records."))
        await Task.yield()

        do {
            var existingDemoRecords = try fetchDemoRecords(context: context, profile: profile)
            if !existingDemoRecords.isEmpty {
                let needsFullSampleRefresh = style == .fullSampleSet && existingDemoRecords.count < sampleRecordMakers(for: .fullSampleSet, profile: profile).count
                if !needsFullSampleRefresh {
                    DemoModeSettings.demoPropertyIdentifier = existingDemoRecords.first?.id
                    progress(LoadProgress(completedRecords: existingDemoRecords.count, totalRecords: existingDemoRecords.count, stageDescription: "Example records are already ready."))
                    return existingDemoRecords
                }

                progress(LoadProgress(completedRecords: 0, totalRecords: makers.count, stageDescription: "Refreshing the existing example records."))
                try clearDemoData(context: context, profile: profile)
                existingDemoRecords = []
                _ = existingDemoRecords
                await Task.yield()
            }

            for (index, maker) in makers.enumerated() {
                try Task.checkCancellation()
                let stage = "Creating \(sampleRecordNames(for: style, profile: profile)[index])."
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
            // Best-effort rollback — discard the optional result of
            // `try?` explicitly so we don't trip the
            // "Result of 'try?' is unused" warning now that
            // clearDemoData returns Int.
            _ = try? clearDemoData(context: context, profile: profile)
            throw CancellationError()
        } catch {
            _ = try? clearDemoData(context: context, profile: profile)
            throw error
        }
    }

    /// Deletes every demo record matching the saved-on-device demo
    /// marker. When `profile` is non-nil the deletion is restricted to
    /// records on that profile; when nil (the default) it sweeps every
    /// profile. Returns the count of records actually deleted so the
    /// caller can surface a real "Cleared N records" message rather
    /// than the silent "Sample data cleared" success the old void-
    /// returning shape allowed when zero records matched.
    @discardableResult
    func clearDemoData(context: ModelContext, profile: RentoryUserProfile? = nil) throws -> Int {
        let demoRecords = try fetchDemoRecords(context: context, profile: profile)

        // Per-record try-catch: one record failing to delete must
        // not abort the sweep — otherwise a single problem record
        // would leave every subsequent demo record stranded and
        // the user would see "still doesn't work" even though
        // most records could have been cleared.
        var deletedCount = 0
        for propertyPack in demoRecords {
            do {
                try deletionService.deletePropertyPack(propertyPack, context: context)
                deletedCount += 1
            } catch {
                // Swallow and continue. The caller's success
                // message will report the actual deleted count.
                continue
            }
        }

        if profile == nil {
            DemoModeSettings.demoPropertyIdentifier = nil
        } else if let stored = DemoModeSettings.demoPropertyIdentifier,
                  demoRecords.contains(where: { $0.id == stored }) {
            DemoModeSettings.demoPropertyIdentifier = nil
        }

        return deletedCount
    }

    func sampleRecordCount(for style: SampleDataStyle, profile: RentoryUserProfile) -> Int {
        sampleRecordMakers(for: style, profile: profile).count
    }

    private func fetchDemoRecords(context: ModelContext, profile: RentoryUserProfile? = nil) throws -> [PropertyPack] {
        let allDemoRecords = try context.fetch(FetchDescriptor<PropertyPack>())
            .filter(DemoModeSettings.matchesDemoRecord)
        guard let profile else { return allDemoRecords }
        return allDemoRecords.filter { $0.profileRawValue == profile.rawValue }
    }

    private func sampleRecordMakers(for style: SampleDataStyle, profile: RentoryUserProfile) -> [() throws -> PropertyPack] {
        switch (profile, style) {
        case (.renter, .singleRecord):
            return [makeSharedHomeRecord]
        case (.renter, .fullSampleSet):
            return [
                makeSharedHomeRecord,
                makeFamilyHouseRecord,
                makeApartmentRecord,
                makeGarageRecord,
                makeAnnexRecord,
                makeStudioRecord,
                makeArchivedRecord,
            ]
        case (.landlord, .singleRecord):
            return [makeLandlordMainHouseRecord]
        case (.landlord, .fullSampleSet):
            return [
                makeLandlordMainHouseRecord,
                makeLandlordCityFlatRecord,
                makeLandlordFamilyHouseRecord,
                makeLandlordStudioBetweenTenantsRecord,
                makeLandlordGardenAnnexRecord,
                makeLandlordArchivedRecord,
            ]
        }
    }

    private func sampleRecordNames(for style: SampleDataStyle, profile: RentoryUserProfile) -> [String] {
        switch (profile, style) {
        case (.renter, .singleRecord):
            return ["the shared flat example"]
        case (.renter, .fullSampleSet):
            return [
                "the shared flat example",
                "the family house example",
                "the apartment example",
                "the storage garage example",
                "the garden annex example",
                "the compact rented space example",
                "the previous tenancy example",
            ]
        case (.landlord, .singleRecord):
            return ["the main rental house example"]
        case (.landlord, .fullSampleSet):
            return [
                "the main rental house example",
                "the city flat rental example",
                "the family rental house example",
                "the studio between tenants example",
                "the garden annex rental example",
                "the previous rental example",
            ]
        }
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

    private func makeLandlordMainHouseRecord() throws -> PropertyPack {
        let tenancyStart = demoDate(year: 2026, month: 1, day: 15)
        let tenancyEnd = demoDate(year: 2027, month: 1, day: 14)

        return try makePropertyRecord(
            nickname: "42 Linden Avenue",
            recordType: .house,
            profile: .landlord,
            isFavourite: true,
            addressLine1: "42 Linden Avenue",
            townCity: "Sampletown",
            postcode: "AB1 2CD",
            tenancyStartDate: tenancyStart,
            tenancyEndDate: tenancyEnd,
            landlordOrAgentName: "Self-managed",
            landlordOrAgentEmail: "me@samplelandlord.test",
            depositSchemeName: "MyDeposits",
            depositReference: "MYD-7341",
            notes: [
                DemoModeSettings.demoMarker,
                "Three-bed semi let to a joint tenancy. Compliance, deposit and rent tracked here.",
            ].joined(separator: "\n\n"),
            roomDefinitions: [
                ("Living room", .livingRoom),
                ("Kitchen", .kitchen),
                ("Main bedroom", .bedroom),
                ("Second bedroom", .bedroom),
                ("Bathroom", .bathroom),
                ("Garden", .garden),
            ],
            documentDefinitions: [
                ("Tenancy agreement – Jan 2026", .tenancyAgreement),
                ("Gas safety certificate", .other),
                ("Electrical safety report (EICR)", .other),
                ("Energy performance certificate (EPC)", .other),
                ("Deposit protection certificate", .depositCertificate),
                ("Inventory and condition report", .checkInInventory),
            ],
            timelineDefinitions: [
                ("Tenancy signed", .moveIn, "Joint AST signed and counter-signed. Keys handed over at 14:00."),
                ("Inventory walkthrough", .inventoryReviewed, "Walked the property with both tenants. Carpets, walls and appliances logged with photos."),
                ("Gas safety check", .inspection, "Annual gas safety inspection passed. Certificate filed."),
                ("Mid-tenancy inspection booked", .inspection, "Booked the rolling 6-month visit for July."),
            ],
            tenancyDefinitions: [
                TenancyDefinition(
                    startDate: tenancyStart,
                    endDate: tenancyEnd,
                    status: .active,
                    tenancyType: .assuredShorthold,
                    depositAmount: 1500,
                    depositSchemeName: "MyDeposits",
                    depositReference: "MYD-7341",
                    rentAmount: 1200,
                    rentFrequency: .monthly,
                    notes: "12-month AST, joint tenancy. Rent due 1st of the month.",
                    mode: .comprehensive,
                    tenants: [
                        ("Aisha N.", "aisha.n@example.test", "07000 000001"),
                        ("James P.", "james.p@example.test", "07000 000002"),
                    ]
                ),
            ],
            reminderDefinitions: [
                ReminderDefinition(
                    title: "Gas safety renewal",
                    kind: .gasSafety,
                    dueDate: demoDate(year: 2026, month: 11, day: 10),
                    priority: .normal,
                    notes: "Book the annual check before the current certificate lapses."
                ),
                ReminderDefinition(
                    title: "EICR renewal",
                    kind: .electricalSafety,
                    dueDate: demoDate(year: 2029, month: 6, day: 1),
                    priority: .low,
                    notes: "Electrical Installation Condition Report — every 5 years."
                ),
                ReminderDefinition(
                    title: "EPC renewal",
                    kind: .energyPerformance,
                    dueDate: demoDate(year: 2028, month: 4, day: 1),
                    priority: .low,
                    notes: "EPC is valid for 10 years; renew before the next listing."
                ),
                ReminderDefinition(
                    title: "Mid-tenancy inspection",
                    kind: .periodicInspection,
                    dueDate: demoDate(year: 2026, month: 7, day: 15),
                    priority: .normal,
                    notes: "Visit booked. Give 24h written notice to tenants beforehand."
                ),
                ReminderDefinition(
                    title: "Tenancy renewal conversation",
                    kind: .tenancyRenewal,
                    dueDate: demoDate(year: 2026, month: 11, day: 15),
                    priority: .high,
                    notes: "Speak to both tenants about renewal two months before the end date."
                ),
            ]
        )
    }

    private func makeLandlordCityFlatRecord() throws -> PropertyPack {
        let tenancyStart = demoDate(year: 2025, month: 6, day: 20)
        let tenancyEnd = demoDate(year: 2026, month: 6, day: 19)

        return try makePropertyRecord(
            nickname: "City flat rental sample",
            recordType: .flat,
            profile: .landlord,
            buildingName: "Central Court",
            spaceIdentifier: "Flat 5C",
            floorLevel: "5",
            addressLine1: "10 Central Court",
            townCity: "Riverford",
            postcode: "RV3 4DE",
            tenancyStartDate: tenancyStart,
            tenancyEndDate: tenancyEnd,
            landlordOrAgentName: "Sample Lettings Ltd",
            landlordOrAgentEmail: "team@samplelettings.test",
            depositSchemeName: "Custodial sample scheme",
            depositReference: "CST-2208",
            notes: [
                DemoModeSettings.demoMarker,
                "City flat sample with a tenancy ending soon — shows renewal nudges and an EICR that has slipped past its renewal date.",
            ].joined(separator: "\n\n"),
            roomDefinitions: [
                ("Open-plan living", .livingRoom),
                ("Kitchen", .kitchen),
                ("Bedroom", .bedroom),
                ("Bathroom", .bathroom),
            ],
            documentDefinitions: [
                ("Tenancy agreement", .tenancyAgreement),
                ("Gas safety certificate", .other),
                ("Deposit protection certificate", .depositCertificate),
            ],
            timelineDefinitions: [
                ("Tenancy signed", .moveIn, "Tenancy signed for the city flat sample."),
                ("Inventory reviewed", .inventoryReviewed, "Inventory completed remotely."),
                ("Repair requested", .repairRequested, "Tenant reported a slow-draining shower."),
            ],
            tenancyDefinitions: [
                TenancyDefinition(
                    startDate: tenancyStart,
                    endDate: tenancyEnd,
                    status: .active,
                    tenancyType: .assuredShorthold,
                    depositAmount: 1100,
                    depositSchemeName: "Custodial sample scheme",
                    depositReference: "CST-2208",
                    rentAmount: 950,
                    rentFrequency: .monthly,
                    notes: "Single-tenant tenancy. Renewal conversation due now.",
                    mode: .standard,
                    tenants: [
                        ("Sample Tenant C", "tenant-c@example.test", "07000 000003"),
                    ]
                ),
            ],
            reminderDefinitions: [
                ReminderDefinition(
                    title: "Tenancy renewal due",
                    kind: .tenancyRenewal,
                    dueDate: demoDate(year: 2026, month: 5, day: 25),
                    priority: .high,
                    notes: "Tenancy ends in 4 weeks — open renewal conversation."
                ),
                ReminderDefinition(
                    title: "EICR renewal overdue",
                    kind: .electricalSafety,
                    dueDate: demoDate(year: 2026, month: 4, day: 30),
                    priority: .high,
                    notes: "EICR renewal slipped — schedule the inspection."
                ),
                ReminderDefinition(
                    title: "Gas safety renewal",
                    kind: .gasSafety,
                    dueDate: demoDate(year: 2026, month: 12, day: 5),
                    priority: .normal,
                    notes: "Annual gas safety check renewal."
                ),
                ReminderDefinition(
                    title: "EPC renewal",
                    kind: .energyPerformance,
                    dueDate: demoDate(year: 2030, month: 1, day: 1),
                    priority: .low,
                    notes: "Energy Performance Certificate still valid."
                ),
            ]
        )
    }

    private func makeLandlordFamilyHouseRecord() throws -> PropertyPack {
        let tenancyStart = demoDate(year: 2024, month: 7, day: 1)
        let tenancyEnd = demoDate(year: 2027, month: 6, day: 30)

        return try makePropertyRecord(
            nickname: "Family rental house sample",
            recordType: .house,
            profile: .landlord,
            isFavourite: true,
            addressLine1: "33 Oakwood Drive",
            townCity: "Westbridge",
            postcode: "WB5 9HJ",
            tenancyStartDate: tenancyStart,
            tenancyEndDate: tenancyEnd,
            landlordOrAgentName: "Family Lettings Co",
            landlordOrAgentEmail: "lets@familylettings.test",
            depositSchemeName: "Custodial sample scheme",
            depositReference: "CST-1187",
            notes: [
                DemoModeSettings.demoMarker,
                "Long-running family tenancy. Shows how a multi-year rental looks with all compliance up to date.",
            ].joined(separator: "\n\n"),
            roomDefinitions: [
                ("Living room", .livingRoom),
                ("Kitchen", .kitchen),
                ("Bedroom 1", .bedroom),
                ("Bedroom 2", .bedroom),
                ("Bedroom 3", .bedroom),
                ("Bathroom", .bathroom),
                ("Utility", .utility),
                ("Garden", .garden),
                ("Garage", .garage),
            ],
            documentDefinitions: [
                ("Tenancy agreement", .tenancyAgreement),
                ("Tenancy renewal addendum", .tenancyAgreement),
                ("Gas safety certificate", .other),
                ("Electrical safety report (EICR)", .other),
                ("Energy performance certificate (EPC)", .other),
                ("Deposit protection certificate", .depositCertificate),
                ("Annual inspection notes", .other),
            ],
            timelineDefinitions: [
                ("Tenancy signed", .moveIn, "Original tenancy signed for the family house sample."),
                ("Inventory reviewed", .inventoryReviewed, "Detailed inventory completed."),
                ("Renewal signed", .moveIn, "Tenancy renewed for a further fixed term."),
                ("Inspection completed", .inspection, "Annual inspection completed with no concerns."),
                ("Repair completed", .repairCompleted, "Boiler service completed by approved engineer."),
            ],
            tenancyDefinitions: [
                TenancyDefinition(
                    startDate: tenancyStart,
                    endDate: tenancyEnd,
                    status: .active,
                    tenancyType: .assuredShorthold,
                    depositAmount: 2200,
                    depositSchemeName: "Custodial sample scheme",
                    depositReference: "CST-1187",
                    rentAmount: 1850,
                    rentFrequency: .monthly,
                    notes: "Three-year fixed-term family tenancy.",
                    mode: .comprehensive,
                    tenants: [
                        ("Sample Tenant D", "tenant-d@example.test", "07000 000004"),
                        ("Sample Tenant E", "tenant-e@example.test", "07000 000005"),
                        ("Sample Tenant F", "tenant-f@example.test", nil),
                    ]
                ),
            ],
            reminderDefinitions: [
                ReminderDefinition(
                    title: "Gas safety renewal",
                    kind: .gasSafety,
                    dueDate: demoDate(year: 2027, month: 2, day: 14),
                    priority: .normal,
                    notes: "Annual gas safety check renewal."
                ),
                ReminderDefinition(
                    title: "Annual inspection",
                    kind: .periodicInspection,
                    dueDate: demoDate(year: 2026, month: 10, day: 5),
                    priority: .normal,
                    notes: "Annual mid-tenancy inspection."
                ),
                ReminderDefinition(
                    title: "Tenancy renewal review",
                    kind: .tenancyRenewal,
                    dueDate: demoDate(year: 2027, month: 4, day: 30),
                    priority: .normal,
                    notes: "Renewal conversation due 2 months before tenancy end."
                ),
            ]
        )
    }

    private func makeLandlordStudioBetweenTenantsRecord() throws -> PropertyPack {
        let lastTenancyStart = demoDate(year: 2025, month: 5, day: 1)
        let lastTenancyEnd = demoDate(year: 2026, month: 4, day: 30)
        let nextTenancyStart = demoDate(year: 2026, month: 6, day: 15)

        return try makePropertyRecord(
            nickname: "Studio between tenants sample",
            recordType: .apartment,
            profile: .landlord,
            buildingName: "Riverside Lofts",
            spaceIdentifier: "Studio 3",
            floorLevel: "1",
            addressLine1: "8 Riverside Lofts",
            townCity: "Eastbank",
            postcode: "EB2 6KL",
            tenancyStartDate: nextTenancyStart,
            tenancyEndDate: nil,
            landlordOrAgentName: "Sample Lettings Ltd",
            landlordOrAgentEmail: "team@samplelettings.test",
            depositSchemeName: nil,
            depositReference: nil,
            notes: [
                DemoModeSettings.demoMarker,
                "Property between tenancies. Shows ended + upcoming tenancies side by side, and the prep work that happens between lets.",
            ].joined(separator: "\n\n"),
            roomDefinitions: [
                ("Living / sleeping", .other),
                ("Kitchen", .kitchen),
                ("Bathroom", .bathroom),
            ],
            documentDefinitions: [
                ("Previous tenancy agreement", .tenancyAgreement),
                ("Check-out report", .checkOutReport),
                ("Cleaning receipt", .cleaningReceipt),
            ],
            timelineDefinitions: [
                ("Previous tenancy ended", .moveOut, "Previous tenant moved out and keys returned."),
                ("Cleaning completed", .cleaningCompleted, "Full clean done before re-letting."),
                ("Repair completed", .repairCompleted, "Touch-up paint and replacement bulbs."),
                ("New tenancy booked", .moveIn, "Upcoming tenancy confirmed for next month."),
            ],
            tenancyDefinitions: [
                TenancyDefinition(
                    startDate: lastTenancyStart,
                    endDate: lastTenancyEnd,
                    status: .ended,
                    tenancyType: .assuredShorthold,
                    depositAmount: 850,
                    depositSchemeName: "Custodial sample scheme",
                    depositReference: "CST-9904",
                    rentAmount: 720,
                    rentFrequency: .monthly,
                    notes: "Previous 12-month tenancy. Deposit returned in full.",
                    mode: .standard,
                    tenants: [
                        ("Sample Previous Tenant", "previous-tenant@example.test", nil),
                    ]
                ),
                TenancyDefinition(
                    startDate: nextTenancyStart,
                    endDate: demoDate(year: 2027, month: 6, day: 14),
                    status: .upcoming,
                    tenancyType: .assuredShorthold,
                    depositAmount: 900,
                    depositSchemeName: "Custodial sample scheme",
                    depositReference: "CST-1042",
                    rentAmount: 780,
                    rentFrequency: .monthly,
                    notes: "Upcoming tenancy starts next month.",
                    mode: .standard,
                    tenants: [
                        ("Sample Incoming Tenant", "incoming-tenant@example.test", "07000 000006"),
                    ]
                ),
            ],
            reminderDefinitions: [
                ReminderDefinition(
                    title: "Gas safety check before re-letting",
                    kind: .gasSafety,
                    dueDate: demoDate(year: 2026, month: 6, day: 1),
                    priority: .high,
                    notes: "Annual gas safety check before new tenancy starts."
                ),
                ReminderDefinition(
                    title: "Inventory walkthrough",
                    kind: .periodicInspection,
                    dueDate: demoDate(year: 2026, month: 6, day: 10),
                    priority: .normal,
                    notes: "Inventory and condition walkthrough on move-in day."
                ),
                ReminderDefinition(
                    title: "EICR renewal",
                    kind: .electricalSafety,
                    dueDate: demoDate(year: 2028, month: 7, day: 1),
                    priority: .low,
                    notes: "EICR still valid for several years."
                ),
            ]
        )
    }

    private func makeLandlordGardenAnnexRecord() throws -> PropertyPack {
        let tenancyStart = demoDate(year: 2026, month: 2, day: 1)
        let tenancyEnd = demoDate(year: 2026, month: 12, day: 31)

        return try makePropertyRecord(
            nickname: "Garden annex rental sample",
            recordType: .annex,
            profile: .landlord,
            mainPropertyName: "Rose House",
            accessDetails: "Side gate, separate entrance, shared bins.",
            addressLine1: "Rose House Annex",
            townCity: "Meadowford",
            postcode: "MF7 8NP",
            tenancyStartDate: tenancyStart,
            tenancyEndDate: tenancyEnd,
            landlordOrAgentName: "Sample Private Landlord",
            landlordOrAgentEmail: "rosehouse@samplelandlord.test",
            depositSchemeName: "MyDeposits sample scheme",
            depositReference: "MYD-4520",
            notes: [
                DemoModeSettings.demoMarker,
                "Compact annex with student tenants. Shows how a smaller landlord property looks alongside the full house samples.",
            ].joined(separator: "\n\n"),
            roomDefinitions: [
                ("Living area", .livingRoom),
                ("Kitchenette", .kitchen),
                ("Bedroom", .bedroom),
                ("Shower room", .bathroom),
            ],
            documentDefinitions: [
                ("Annex tenancy agreement", .tenancyAgreement),
                ("Gas safety certificate", .other),
                ("Energy performance certificate (EPC)", .other),
                ("Inventory", .checkInInventory),
            ],
            timelineDefinitions: [
                ("Tenancy signed", .moveIn, "Tenancy signed for the annex sample."),
                ("Inventory reviewed", .inventoryReviewed, "Compact inventory completed."),
                ("Inspection completed", .inspection, "Mid-tenancy inspection completed."),
            ],
            tenancyDefinitions: [
                TenancyDefinition(
                    startDate: tenancyStart,
                    endDate: tenancyEnd,
                    status: .active,
                    tenancyType: .fixedTerm,
                    depositAmount: 650,
                    depositSchemeName: "MyDeposits sample scheme",
                    depositReference: "MYD-4520",
                    rentAmount: 580,
                    rentFrequency: .monthly,
                    notes: "Joint tenancy with two student tenants.",
                    mode: .comprehensive,
                    tenants: [
                        ("Sample Student Tenant 1", "student-1@example.test", "07000 000007"),
                        ("Sample Student Tenant 2", "student-2@example.test", "07000 000008"),
                    ]
                ),
            ],
            reminderDefinitions: [
                ReminderDefinition(
                    title: "Mid-tenancy inspection",
                    kind: .periodicInspection,
                    dueDate: demoDate(year: 2026, month: 8, day: 1),
                    priority: .normal,
                    notes: "Inspection visit booked with the tenants."
                ),
                ReminderDefinition(
                    title: "Gas safety renewal",
                    kind: .gasSafety,
                    dueDate: demoDate(year: 2027, month: 1, day: 20),
                    priority: .normal,
                    notes: "Annual gas safety check renewal."
                ),
                ReminderDefinition(
                    title: "Tenancy renewal review",
                    kind: .tenancyRenewal,
                    dueDate: demoDate(year: 2026, month: 10, day: 31),
                    priority: .normal,
                    notes: "Decide on renewal terms two months before end date."
                ),
            ]
        )
    }

    private func makeLandlordArchivedRecord() throws -> PropertyPack {
        let tenancyStart = demoDate(year: 2024, month: 9, day: 1)
        let tenancyEnd = demoDate(year: 2025, month: 8, day: 31)

        let record = try makePropertyRecord(
            nickname: "Previous student let sample",
            recordType: .flat,
            profile: .landlord,
            buildingName: "College Mews",
            spaceIdentifier: "Flat 4",
            floorLevel: "1",
            addressLine1: "2 College Mews",
            townCity: "Oakford",
            postcode: "OK5 6LM",
            tenancyStartDate: tenancyStart,
            tenancyEndDate: tenancyEnd,
            landlordOrAgentName: "Sample Lettings Ltd",
            landlordOrAgentEmail: "team@samplelettings.test",
            depositSchemeName: "Custodial sample scheme",
            depositReference: "CST-7740",
            notes: [
                DemoModeSettings.demoMarker,
                "Archived rental from a previous year. Shows how a finished tenancy can be kept on file for reference without cluttering the active list.",
            ].joined(separator: "\n\n"),
            roomDefinitions: [
                ("Living room", .livingRoom),
                ("Kitchen", .kitchen),
                ("Bedroom", .bedroom),
                ("Bathroom", .bathroom),
            ],
            documentDefinitions: [
                ("Previous tenancy agreement", .tenancyAgreement),
                ("Check-out report", .checkOutReport),
                ("Deposit return note", .other),
            ],
            timelineDefinitions: [
                ("Tenancy signed", .moveIn, "Tenancy signed for the archived sample."),
                ("Inspection completed", .inspection, "Mid-tenancy inspection completed."),
                ("Tenancy ended", .moveOut, "Property handed back at the end of the term."),
                ("Deposit returned", .depositDiscussion, "Deposit returned in full after the check-out report."),
            ],
            tenancyDefinitions: [
                TenancyDefinition(
                    startDate: tenancyStart,
                    endDate: tenancyEnd,
                    status: .ended,
                    tenancyType: .fixedTerm,
                    depositAmount: 900,
                    depositSchemeName: "Custodial sample scheme",
                    depositReference: "CST-7740",
                    rentAmount: 780,
                    rentFrequency: .monthly,
                    notes: "Completed academic-year tenancy with three student tenants.",
                    mode: .comprehensive,
                    tenants: [
                        ("Sample Past Tenant 1", "past-1@example.test", nil),
                        ("Sample Past Tenant 2", "past-2@example.test", nil),
                        ("Sample Past Tenant 3", "past-3@example.test", nil),
                    ]
                ),
            ]
        )
        record.isArchived = true
        return record
    }

    private func makePropertyRecord(
        nickname: String,
        recordType: PropertyRecordType = .house,
        profile: RentoryUserProfile = .renter,
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
        timelineDefinitions: [(String, TimelineEventType, String)],
        tenancyDefinitions: [TenancyDefinition] = [],
        reminderDefinitions: [ReminderDefinition] = []
    ) throws -> PropertyPack {
        let propertyPack = PropertyPack(
            nickname: nickname,
            recordType: recordType,
            profile: profile,
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
        propertyPack.tenancies = makeTenancies(definitions: tenancyDefinitions)
        propertyPack.reminders = makeReminders(definitions: reminderDefinitions)
        return propertyPack
    }

    private func makeTenancies(definitions: [TenancyDefinition]) -> [Tenancy] {
        definitions.map { definition in
            let tenancy = Tenancy(
                startDate: definition.startDate,
                endDate: definition.endDate,
                status: definition.status,
                tenancyType: definition.tenancyType,
                depositAmount: definition.depositAmount,
                depositSchemeName: definition.depositSchemeName,
                depositReference: definition.depositReference,
                rentAmount: definition.rentAmount,
                rentFrequency: definition.rentFrequency,
                notes: definition.notes,
                mode: definition.mode
            )

            tenancy.tenants = definition.tenants.enumerated().map { index, tenant in
                Tenant(
                    name: tenant.name,
                    email: tenant.email,
                    phone: tenant.phone,
                    sortOrder: index
                )
            }
            return tenancy
        }
    }

    private func makeReminders(definitions: [ReminderDefinition]) -> [Reminder] {
        definitions.map { definition in
            Reminder(
                title: definition.title,
                notes: definition.notes,
                dueDate: definition.dueDate,
                kind: definition.kind,
                priority: definition.priority
            )
        }
    }

    private func makeRooms(roomDefinitions: [(String, RoomType)]) throws -> [RoomRecord] {
        // Short, specific notes rotated across rooms so screenshots
        // read like real notes a tenant would jot down on the day,
        // rather than placeholder copy. Kept conversational on purpose.
        let roomNotes = [
            "Walked through with the agent on move-in day.",
            "Faint scuff above the skirting — photo added.",
            "All sockets working; tested with phone charger.",
            "Carpet edge slightly lifted near the doorway.",
            "Window catch a little stiff but functional.",
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
        // Specific, believable notes that vary by item. Reads like a
        // person genuinely walking through the property at check-in.
        let sampleNotes = [
            "Looked over on move-in day — happy with this one.",
            "Small chip on the corner, photographed for the record.",
            "Hairline crack in the grout — not urgent, noted.",
            "Hinge a little loose. Tightened by hand for now.",
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
                item.photos = try makeSamplePhotos(for: roomName, roomType: roomType)
            }

            return item
        }
    }

    /// Builds three demo photos per checklist item — move-in, during,
    /// move-out — preferring marketing-quality bundled photos via
    /// `DemoPhotoLibrary` and falling back to the synthetic colour-
    /// block placeholder when no bundled asset exists yet for the
    /// derived slot. This lets the codebase ship even when only some
    /// (or none) of the demo photos have been curated.
    private func makeSamplePhotos(for roomName: String, roomType: RoomType) throws -> [EvidencePhoto] {
        let phases: [(phase: EvidencePhase, caption: String, fallback: DemoPhotoColour)] = [
            (.moveIn, "\(roomName) move-in", .softBlue),
            (.duringTenancy, "\(roomName) during tenancy", .softGreen),
            (.moveOut, "\(roomName) move-out", .softSand),
        ]

        return try phases.enumerated().map { index, sample in
            let image = resolveDemoImage(roomType: roomType, phase: sample.phase, caption: sample.caption, fallback: sample.fallback)
            let fileName = try photoStorageService.savePhoto(image)

            return EvidencePhoto(
                localFileName: fileName,
                phase: sample.phase,
                caption: sample.caption,
                capturedAt: demoDate(year: 2026, month: 1, day: 10 + index),
                sortOrder: index
            )
        }
    }

    /// Resolves the platform image to persist for a given demo slot.
    /// Looks up a bundled asset via `DemoPhotoLibrary`; if nothing is
    /// installed for that (room, phase) pair, falls through to the
    /// existing synthetic placeholder so the factory keeps working.
    private func resolveDemoImage(
        roomType: RoomType,
        phase: EvidencePhase,
        caption: String,
        fallback: DemoPhotoColour
    ) -> DemoPlatformImage {
        if let slot = DemoPhotoSlot.slot(for: roomType, phase: phase),
           let bundled = DemoPhotoLibrary.image(for: slot) {
            return bundled
        }
        return makeSampleImage(title: caption, subtitle: phase.rawValue, colour: fallback)
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
                notes: "Sample document for exploring Rentory.",
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
            "This file contains sample content for exploring Rentory.",
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

private struct TenancyDefinition {
    let startDate: Date
    let endDate: Date?
    let status: TenancyStatus
    let tenancyType: TenancyType
    let depositAmount: Double?
    let depositSchemeName: String?
    let depositReference: String?
    let rentAmount: Double?
    let rentFrequency: RentFrequency?
    let notes: String?
    let mode: TenancyMode
    let tenants: [(name: String, email: String?, phone: String?)]
}

private struct ReminderDefinition {
    let title: String
    let kind: ReminderKind
    let dueDate: Date?
    let priority: ReminderPriority
    let notes: String?
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
