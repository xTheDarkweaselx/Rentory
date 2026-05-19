//
//  RentoryPerformanceTests.swift
//  RentoryTests
//
//  XCTest performance baselines for the hot paths flagged in the release
//  plan (Quality & Stability tier). These are guard-rails, not assertions —
//  Xcode records a baseline on first run and flags regressions on later runs.
//  Each test seeds an in-memory store / temporary file storage and measures
//  the operation under test, so they're hermetic and quick to re-run.
//

import Foundation
import SwiftData
import XCTest

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@testable import Rentory

@MainActor
final class RentoryPerformanceTests: XCTestCase {
    func test_perf_fetchAndScopeOneHundredPropertyPacks() throws {
        let context = try Self.makeModelContext()

        for index in 0..<100 {
            let pack = PropertyPack(
                nickname: "Property \(index)",
                recordType: .house,
                profile: index.isMultiple(of: 2) ? .renter : .landlord,
                townCity: "Town \(index % 10)",
                postcode: "PC\(index)",
                tenancyStartDate: Date(timeIntervalSince1970: TimeInterval(index * 86_400)),
                tenancyEndDate: nil,
                notes: "Notes for property \(index)"
            )
            context.insert(pack)
        }
        try context.save()

        measure {
            let descriptor = FetchDescriptor<PropertyPack>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
            let all = (try? context.fetch(descriptor)) ?? []
            let renterScoped = all.filter { $0.profileRawValue == RentoryUserProfile.renter.rawValue }
            XCTAssertEqual(renterScoped.count, 50)
        }
    }

    func test_perf_searchableTextBuildForFiftyPropertiesWithRooms() throws {
        let context = try Self.makeModelContext()

        for index in 0..<50 {
            let items = (0..<6).map { itemIndex in
                ChecklistItemRecord(
                    title: "Item \(itemIndex)",
                    sortOrder: itemIndex,
                    moveInConditionRawValue: EvidenceCondition.good.rawValue,
                    moveOutConditionRawValue: EvidenceCondition.notChecked.rawValue
                )
            }
            let rooms = (0..<5).map { roomIndex in
                RoomRecord(
                    name: "Room \(roomIndex)",
                    type: .other,
                    sortOrder: roomIndex,
                    notes: "Room \(roomIndex) notes",
                    checklistItems: items
                )
            }
            let pack = PropertyPack(
                nickname: "Property \(index)",
                addressLine1: "Address line for \(index)",
                townCity: "Town",
                postcode: "PC\(index)",
                notes: "Searchable notes",
                rooms: rooms
            )
            context.insert(pack)
        }
        try context.save()

        let descriptor = FetchDescriptor<PropertyPack>()
        let all = try context.fetch(descriptor)

        measure {
            for pack in all {
                _ = pack.searchableText
            }
        }
    }

    func test_perf_pdfGenerationForHeavyProperty() throws {
        let builder = PDFReportBuilder()
        var rooms: [RoomRecord] = []
        for roomIndex in 0..<15 {
            let items = (0..<6).map { itemIndex in
                ChecklistItemRecord(
                    title: "Item \(itemIndex) in room \(roomIndex)",
                    sortOrder: itemIndex,
                    moveInConditionRawValue: EvidenceCondition.good.rawValue,
                    moveOutConditionRawValue: EvidenceCondition.notChecked.rawValue,
                    moveInNotes: "Move-in notes for item \(itemIndex)",
                    moveOutNotes: nil
                )
            }
            rooms.append(
                RoomRecord(name: "Room \(roomIndex)", type: .other, sortOrder: roomIndex, checklistItems: items)
            )
        }
        let documents = (0..<10).map { documentIndex in
            DocumentRecord(
                displayName: "Document \(documentIndex)",
                type: .other,
                localFileName: "doc-\(documentIndex).pdf",
                documentDate: Date(timeIntervalSince1970: TimeInterval(documentIndex * 86_400))
            )
        }
        let events = (0..<20).map { eventIndex in
            TimelineEvent(
                title: "Event \(eventIndex)",
                type: .inspection,
                eventDate: Date(timeIntervalSince1970: TimeInterval(eventIndex * 86_400)),
                notes: "Notes for event \(eventIndex)"
            )
        }
        let pack = PropertyPack(
            nickname: "Heavy property",
            rooms: rooms,
            documents: documents,
            timelineEvents: events
        )

        measure {
            _ = try? builder.buildReportData(for: pack, options: ExportOptions())
        }
    }

    func test_perf_backupCreationForFiftyPropertyPacks() throws {
        let storage = Self.makeFileStorage()
        let context = try Self.makeModelContext()
        let backupService = RentoryBackupService(
            fileStorageService: storage,
            deletionService: RentoryDataDeletionService(fileStorageService: storage)
        )

        for index in 0..<50 {
            let pack = PropertyPack(
                nickname: "Property \(index)",
                townCity: "Town \(index)",
                notes: "Property notes \(index)"
            )
            let room = RoomRecord(
                name: "Room",
                type: .other,
                sortOrder: 0,
                checklistItems: [
                    ChecklistItemRecord(title: "Hob", sortOrder: 0)
                ]
            )
            pack.rooms = [room]
            context.insert(pack)
        }
        try context.save()

        measure {
            do {
                let url = try backupService.createBackup(context: context)
                try? FileManager.default.removeItem(at: url)
            } catch {
                XCTFail("createBackup threw \(error)")
            }
        }
    }

    func test_perf_pdfReportSnapshotBuildForLargeProperty() throws {
        let context = try Self.makeModelContext()
        let rooms = (0..<20).map { roomIndex in
            let items = (0..<8).map { itemIndex in
                ChecklistItemRecord(
                    title: "Item \(itemIndex)",
                    sortOrder: itemIndex,
                    moveInConditionRawValue: EvidenceCondition.good.rawValue,
                    moveOutConditionRawValue: EvidenceCondition.notChecked.rawValue
                )
            }
            return RoomRecord(name: "Room \(roomIndex)", type: .other, sortOrder: roomIndex, checklistItems: items)
        }
        let pack = PropertyPack(nickname: "Large", rooms: rooms)
        context.insert(pack)
        try context.save()

        measure {
            _ = PDFReportSnapshot(propertyPack: pack)
        }
    }

    // MARK: - Helpers

    private static func makeModelContext() throws -> ModelContext {
        let schema = Schema([
            PropertyPack.self,
            RoomRecord.self,
            ChecklistItemRecord.self,
            EvidencePhoto.self,
            DocumentRecord.self,
            TimelineEvent.self,
            Reminder.self,
            ItemComment.self,
            Tenancy.self,
            Tenant.self,
            RentPayment.self,
            PropertyExpense.self,
        ])
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)]
        )
        return ModelContext(container)
    }

    private static func makeFileStorage() -> FileStorageService {
        let baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RentoryPerfTests-\(UUID().uuidString)", isDirectory: true)
        return FileStorageService(baseDirectoryURL: baseURL)
    }
}
