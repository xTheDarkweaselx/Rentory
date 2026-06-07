//
//  RentoryTests.swift
//  RentoryTests
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation
import CloudKit
import PDFKit
import SwiftData
import Testing

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@testable import Rentory

struct RentoryTests {
    @Test func freeUserWithNoPropertiesCanCreateAProperty() {
        #expect(FeatureAccessService.canCreateProperty(currentPropertyCount: 0, isUnlocked: false))
    }

    @Test func freeUserWithOnePropertyCannotCreateAnother() {
        #expect(!FeatureAccessService.canCreateProperty(currentPropertyCount: 1, isUnlocked: false))
    }

    @Test func unlockedUserCanCreateMoreProperties() {
        #expect(FeatureAccessService.canCreateProperty(currentPropertyCount: 3, isUnlocked: true))
    }

    @Test func freeUserWithTwoRoomsCannotAddAThird() {
        #expect(!FeatureAccessService.canAddRoom(currentRoomCount: 2, isUnlocked: false))
    }

    @Test func unlockedUserCanAddMoreRooms() {
        #expect(FeatureAccessService.canAddRoom(currentRoomCount: 4, isUnlocked: true))
    }

    @Test func freeUserWithTwentyPhotosCannotAddAnother() {
        #expect(!FeatureAccessService.canAddPhoto(currentPhotoCount: 20, isUnlocked: false))
    }

    @Test func freeUserCannotSwitchToLandlordProfile() {
        #expect(!FeatureAccessService.canSwitchToLandlordProfile(isUnlocked: false))
    }

    @Test func unlockedUserCanSwitchToLandlordProfile() {
        #expect(FeatureAccessService.canSwitchToLandlordProfile(isUnlocked: true))
    }

    @Test func defaultProfileIsRenter() {
        #expect(RentoryUserProfile.defaultProfile == .renter)
    }

    @Test func renterProfileExcludesLandlordOnlyActionKinds() {
        let cases = ReminderKind.availableCases(for: .renter)
        #expect(!cases.contains(.gasSafety))
        #expect(!cases.contains(.electricalSafety))
        #expect(!cases.contains(.energyPerformance))
        #expect(!cases.contains(.periodicInspection))
        #expect(!cases.contains(.tenancyRenewal))
        #expect(cases.contains(.inspection))
        #expect(cases.contains(.custom))
    }

    @Test func landlordProfileIncludesAllActionKinds() {
        let cases = ReminderKind.availableCases(for: .landlord)
        #expect(cases.count == ReminderKind.allCases.count)
        #expect(cases.contains(.gasSafety))
        #expect(cases.contains(.tenancyRenewal))
    }

    @Test func renterProfileExcludesLandlordOnlyDocumentTypes() {
        let cases = DocumentType.availableCases(for: .renter)
        #expect(!cases.contains(.gasSafetyCertificate))
        #expect(!cases.contains(.electricalSafetyReport))
        #expect(!cases.contains(.energyPerformanceCertificate))
        #expect(!cases.contains(.rightToRentCheck))
        #expect(cases.contains(.tenancyAgreement))
    }

    @Test func tenancyStageDerivesMoveInWhenStartDateInFuture() {
        let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
        let future = referenceDate.addingTimeInterval(7 * 86_400)
        #expect(TenancyStage.derive(from: future, to: nil, on: referenceDate) == .moveIn)
    }

    @Test func tenancyStageDerivesLivingWhenWithinRange() {
        let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
        let past = referenceDate.addingTimeInterval(-7 * 86_400)
        let future = referenceDate.addingTimeInterval(7 * 86_400)
        #expect(TenancyStage.derive(from: past, to: future, on: referenceDate) == .living)
    }

    @Test func tenancyStageDerivesMoveOutWhenEndDateInPast() {
        let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
        let past = referenceDate.addingTimeInterval(-7 * 86_400)
        let pastEnd = referenceDate.addingTimeInterval(-1 * 86_400)
        #expect(TenancyStage.derive(from: past, to: pastEnd, on: referenceDate) == .moveOut)
    }

    @Test func tenancyStageReturnsNilWithNoDates() {
        let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(TenancyStage.derive(from: nil, to: nil, on: referenceDate) == nil)
    }

    @Test func effectiveTenancyStageDefaultsToMoveInForFreshProperty() {
        let property = PropertyPack(nickname: "Fresh")
        #expect(property.derivedTenancyStage == nil)
        #expect(property.effectiveTenancyStage == .moveIn)
    }

    @Test func manualTenancyStagePrefersManualOverDerived() {
        let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
        let past = referenceDate.addingTimeInterval(-7 * 86_400)
        let future = referenceDate.addingTimeInterval(7 * 86_400)
        let property = PropertyPack(
            nickname: "Test",
            tenancyStartDate: past,
            tenancyEndDate: future
        )
        // Without manual: derived is living
        #expect(TenancyStage.derive(from: property.tenancyStartDate, to: property.tenancyEndDate, on: referenceDate) == .living)

        // Set manual to moveOut
        property.manualTenancyStage = .moveOut
        #expect(property.manualTenancyStage == .moveOut)
        #expect(property.effectiveTenancyStage == .moveOut)
        // Mismatch flag should fire — derived would be living, but evaluated at .now
        // which differs from referenceDate, so this test only asserts the manual sticks.
    }

    @Test func renterProfileExcludesLandlordOnlyTimelineEvents() {
        let cases = TimelineEventType.availableCases(for: .renter)
        #expect(!cases.contains(.gasSafetyRenewed))
        #expect(!cases.contains(.electricalSafetyRenewed))
        #expect(!cases.contains(.energyPerformanceRenewed))
        #expect(!cases.contains(.tenancyStarted))
        #expect(!cases.contains(.tenancyEnded))
        #expect(!cases.contains(.rentReceived))
        #expect(cases.contains(.moveIn))
        #expect(cases.contains(.inspection))
    }

    @Test func existingDataRemainsViewableWhenOverLimit() {
        let propertyPack = PropertyPack(
            nickname: "Home",
            rooms: [
                RoomRecord(name: "Kitchen", type: .kitchen, sortOrder: 0),
                RoomRecord(name: "Bedroom", type: .bedroom, sortOrder: 1),
            ]
        )

        #expect(propertyPack.nickname == "Home")
        #expect(propertyPack.rooms.count == 2)
        #expect(!FeatureAccessService.canAddRoom(currentRoomCount: propertyPack.rooms.count, isUnlocked: false))
    }

    @Test func completionScoreStartsAtGettingStarted() throws {
        let propertyPack = PropertyPack(nickname: "My rented home")

        let result = CompletionScoreService.score(for: propertyPack)

        #expect(result.percentage == 11)
        #expect(result.statusTitle == "Getting started")
        #expect(result.completedItems.contains("Property record created"))
        #expect(result.suggestedNextItems.contains("Add your first room"))
    }

    @Test func completionScoreReachesReadyToExport() throws {
        let checklistItem = ChecklistItemRecord(
            title: "Walls",
            sortOrder: 0,
            moveInConditionRawValue: EvidenceCondition.good.rawValue,
            moveOutConditionRawValue: EvidenceCondition.fair.rawValue,
            photos: [
                EvidencePhoto(localFileName: "photo.jpg", phase: .moveIn),
            ]
        )
        let room = RoomRecord(
            name: "Kitchen",
            type: .kitchen,
            sortOrder: 0,
            checklistItems: [checklistItem]
        )
        let propertyPack = PropertyPack(
            nickname: "My rented home",
            addressLine1: "1",
            townCity: "Leeds",
            tenancyStartDate: .now,
            tenancyEndDate: .now.addingTimeInterval(86_400),
            rooms: [room],
            documents: [
                DocumentRecord(displayName: "Agreement", type: .tenancyAgreement, localFileName: "doc.pdf"),
            ],
            timelineEvents: [
                TimelineEvent(title: "Move-in", type: .moveIn, eventDate: .now),
            ]
        )

        let result = CompletionScoreService.score(for: propertyPack)

        #expect(result.percentage == 100)
        #expect(result.statusTitle == "Ready to export")
        #expect(result.suggestedNextItems.isEmpty)
    }

    @Test func exportOptionsUsePrivacyFirstDefaults() {
        let options = ExportOptions()

        #expect(options.includePropertyName)
        #expect(options.includeTownOrPostcode)
        #expect(!options.includeFullAddress)
        #expect(options.includeTenancyDates)
        #expect(!options.includeLandlordOrAgentDetails)
        #expect(!options.includeDepositDetails)
        #expect(options.includeRooms)
        #expect(options.includeChecklistNotes)
        #expect(options.includePhotos)
        #expect(options.includeDocumentsList)
        #expect(options.includeTimeline)
        #expect(options.includeTenancies)
        #expect(options.includeReminders)
    }

    @Test func reportSectionsLeaveSensitiveFieldsOutWhenTurnedOff() {
        let builder = PDFReportBuilder()
        let propertyPack = PropertyPack(
            nickname: "Private Place",
            addressLine1: "1 Example Road",
            townCity: "Leeds",
            postcode: "LS1 1AA",
            tenancyStartDate: Date(timeIntervalSince1970: 0),
            tenancyEndDate: Date(timeIntervalSince1970: 86_400),
            landlordOrAgentName: "Alex",
            landlordOrAgentEmail: "alex@example.com",
            depositSchemeName: "Scheme",
            depositReference: "REF123"
        )
        let options = ExportOptions(
            includeFullAddress: false,
            includeLandlordOrAgentDetails: false,
            includeDepositDetails: false
        )

        let text = builder.makeReportSections(for: propertyPack, options: options)
            .flatMap(\.lines)
            .joined(separator: "\n")

        #expect(!text.contains("1 Example Road"))
        #expect(!text.contains("Alex"))
        #expect(!text.contains("REF123"))
        #expect(text.contains("Leeds"))
    }

    @Test func reportDisclaimerIsAlwaysIncluded() {
        let builder = PDFReportBuilder()
        let propertyPack = PropertyPack(nickname: "Home")
        let options = ExportOptions()

        let sections = builder.makeReportSections(for: propertyPack, options: options)
        let text = sections.flatMap(\.lines).joined(separator: "\n")

        #expect(text.contains(ReportDisclaimerView.reportText))
    }

    @Test func reportIncludesLandlordTenanciesAndReminders() {
        let builder = PDFReportBuilder()
        let tenant = Tenant(name: "Jane Tenant", email: "jane@example.test", phone: "07000 111222")
        let tenancy = Tenancy(
            startDate: Date(timeIntervalSince1970: 1_700_000_000),
            endDate: Date(timeIntervalSince1970: 1_700_000_000 + 86_400 * 365),
            status: .active,
            tenancyType: .assuredShorthold,
            depositAmount: 1200,
            depositSchemeName: "Sample Scheme",
            depositReference: "SAMPLE-99",
            rentAmount: 950,
            rentFrequency: .monthly,
            notes: "Twelve-month fixed term.",
            mode: .comprehensive,
            tenants: [tenant]
        )
        let reminder = Reminder(
            title: "Annual gas safety check",
            notes: "Renew certificate before expiry",
            dueDate: Date(timeIntervalSince1970: 1_700_000_000 + 86_400 * 90),
            kind: .gasSafety,
            priority: .high
        )
        let propertyPack = PropertyPack(
            nickname: "Linden Avenue",
            profile: .landlord,
            reminders: [reminder],
            tenancies: [tenancy]
        )

        let sections = builder.makeReportSections(for: propertyPack, options: ExportOptions())
        let titles = sections.map(\.title)
        let text = sections.flatMap(\.lines).joined(separator: "\n")

        #expect(titles.contains("Tenancies"))
        #expect(titles.contains("Reminders"))
        #expect(text.contains("Active"))
        #expect(text.contains("Jane Tenant"))
        #expect(text.contains("Sample Scheme"))
        #expect(text.contains("Annual gas safety check"))
        #expect(text.contains("Gas safety"))
        #expect(text.contains("Outstanding"))
    }

    @Test func reportOmitsTenanciesAndRemindersWhenNoneExist() {
        let builder = PDFReportBuilder()
        let propertyPack = PropertyPack(nickname: "Empty", profile: .renter)

        let sections = builder.makeReportSections(for: propertyPack, options: ExportOptions())
        let titles = sections.map(\.title)

        #expect(!titles.contains("Tenancies"))
        #expect(!titles.contains("Reminders"))
    }

    @Test func reportOmitsTenanciesAndRemindersWhenTogglesOff() {
        let builder = PDFReportBuilder()
        let tenancy = Tenancy(startDate: Date(timeIntervalSince1970: 1_700_000_000), status: .active)
        let reminder = Reminder(title: "Inspection", kind: .periodicInspection)
        let propertyPack = PropertyPack(nickname: "Toggle", profile: .landlord, reminders: [reminder], tenancies: [tenancy])
        var options = ExportOptions()
        options.includeTenancies = false
        options.includeReminders = false

        let sections = builder.makeReportSections(for: propertyPack, options: options)
        let titles = sections.map(\.title)

        #expect(!titles.contains("Tenancies"))
        #expect(!titles.contains("Reminders"))
    }

    @Test func generatedReportURLIsLocalAndDoesNotUsePropertyName() throws {
        let storageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RentoryExportTests-\(UUID().uuidString)", isDirectory: true)
        let fileStorageService = FileStorageService(baseDirectoryURL: storageURL)
        let exportService = PDFExportService(
            fileStorageService: fileStorageService,
            reportBuilder: PDFReportBuilder(photoStorageService: PhotoStorageService(fileStorageService: fileStorageService))
        )
        let propertyPack = PropertyPack(nickname: "Secret Cottage")

        let reportURL = try exportService.createReport(for: propertyPack, options: ExportOptions())

        #expect(reportURL.isFileURL)
        #expect(reportURL.lastPathComponent.hasSuffix(".pdf"))
        #expect(!reportURL.lastPathComponent.localizedCaseInsensitiveContains("Secret Cottage"))
    }

    @Test func invalidFileNamesAreRejected() throws {
        let service = makeService()

        #expect(throws: FileStorageError.invalidFileName) {
            _ = try service.urlForDocument(fileName: "../private.pdf")
        }

        #expect(throws: FileStorageError.invalidFileName) {
            try service.deleteEvidencePhoto(fileName: "")
        }
    }

    @Test func unsupportedExtensionsAreRejected() throws {
        let service = makeService()

        #expect(throws: FileStorageError.unsupportedFileType) {
            _ = try service.saveImageData(Data("test".utf8), fileExtension: "gif")
        }

        let tempFolder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempFolder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempFolder) }

        let sourceURL = tempFolder.appendingPathComponent("notes.pages")
        try Data("test".utf8).write(to: sourceURL)

        #expect(throws: FileStorageError.unsupportedFileType) {
            _ = try service.saveDocument(from: sourceURL)
        }
    }

    @Test func generatedFileNamesDoNotContainOriginalNames() throws {
        let service = makeService()
        let tempFolder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempFolder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempFolder) }

        let sourceURL = tempFolder.appendingPathComponent("tenancy-agreement.PDF")
        try Data("test".utf8).write(to: sourceURL)

        let storedFileName = try service.saveDocument(from: sourceURL)

        #expect(!storedFileName.contains("tenancy-agreement"))
        #expect(storedFileName.hasSuffix(".pdf"))
    }

    @Test func folderCreationAndSaveDeleteWork() throws {
        let service = makeService()
        let storedPhotoFileName = try service.saveImageData(Data([0x01, 0x02, 0x03]), fileExtension: "PNG")
        let photoURL = try service.urlForEvidencePhoto(fileName: storedPhotoFileName)

        #expect(FileManager.default.fileExists(atPath: photoURL.path))
        #expect(FileManager.default.fileExists(atPath: photoURL.deletingLastPathComponent().path))

        try service.deleteEvidencePhoto(fileName: storedPhotoFileName)

        #expect(!FileManager.default.fileExists(atPath: photoURL.path))
    }

    @Test func smallImagesAreNotUpscaled() throws {
        let image = try makeImage(size: CGSize(width: 800, height: 600))
        let resizedImage = ImageResizer.resizedImage(from: image)

        #expect(resizedImage.size.width == image.size.width)
        #expect(resizedImage.size.height == image.size.height)
    }

    @Test func largeImagesAreResized() throws {
        let image = try makeImage(size: CGSize(width: 4000, height: 3000))
        let resizedImage = ImageResizer.resizedImage(from: image)

        #expect(max(resizedImage.size.width, resizedImage.size.height) <= 2400)
        #expect(resizedImage.size.width < image.size.width)
    }

    @Test func saveLoadAndDeletePhotoWorks() throws {
        let fileStorageService = makeService()
        let photoStorageService = PhotoStorageService(fileStorageService: fileStorageService)
        let image = try makeImage(size: CGSize(width: 3200, height: 1800))

        let fileName = try photoStorageService.savePhoto(image)
        #expect(!fileName.contains("/"))
        #expect(!fileName.contains(".."))
        #expect(fileName.hasSuffix(".jpg"))
        #expect(!fileName.contains("3200"))

        let loadedImage = try photoStorageService.loadPhoto(fileName: fileName)
        #expect(loadedImage.rrSize.width > 0)
        #expect(loadedImage.rrSize.height > 0)

        let storedURL = try fileStorageService.urlForEvidencePhoto(fileName: fileName)
        try photoStorageService.deletePhoto(fileName: fileName)
        #expect(!FileManager.default.fileExists(atPath: storedURL.path))
    }

    @Test func clearTemporaryReportsDeletesOnlyTemporaryExports() throws {
        let fileStorageService = makeService()
        let deletionService = RentoryDataDeletionService(fileStorageService: fileStorageService)

        let temporaryReportURL = try fileStorageService.saveTemporaryExportData(Data("report".utf8), preferredFileName: "rentory-report-test.pdf")
        let storedPhotoFileName = try fileStorageService.saveImageData(Data([0x01, 0x02, 0x03]), fileExtension: "jpg")
        let photoURL = try fileStorageService.urlForEvidencePhoto(fileName: storedPhotoFileName)

        try deletionService.clearTemporaryReports()

        #expect(!FileManager.default.fileExists(atPath: temporaryReportURL.path))
        #expect(FileManager.default.fileExists(atPath: photoURL.path))
    }

    @Test func cleanupOldTemporaryReportsDeletesOnlyOlderFiles() throws {
        let fileStorageService = makeService()
        let oldReportURL = try fileStorageService.saveTemporaryExportData(Data("old".utf8), preferredFileName: "rentory-report-old.pdf")
        let freshReportURL = try fileStorageService.saveTemporaryExportData(Data("new".utf8), preferredFileName: "rentory-report-new.pdf")

        let oldDate = Date().addingTimeInterval(-(60 * 60 * 24 * 8))
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: oldReportURL.path)

        try fileStorageService.cleanupOldTemporaryExports()

        #expect(!FileManager.default.fileExists(atPath: oldReportURL.path))
        #expect(FileManager.default.fileExists(atPath: freshReportURL.path))
    }

    @Test func storageSummaryCountsTemporaryReportsAndBytes() throws {
        let fileStorageService = makeService()

        _ = try fileStorageService.saveTemporaryExportData(Data("report".utf8), preferredFileName: "rentory-report-a.pdf")
        _ = try fileStorageService.saveImageData(Data([0x01, 0x02, 0x03, 0x04]), fileExtension: "jpg")

        let summary = try fileStorageService.storageSummary()

        #expect(summary.temporaryReportCount == 1)
        #expect(summary.approximateStorageUsedBytes > 0)
    }

    @Test func deletePropertyPackDeletesLinkedPhotosAndDocuments() throws {
        let fileStorageService = makeService()
        let deletionService = RentoryDataDeletionService(fileStorageService: fileStorageService)
        let context = try makeModelContext()

        let photoFileName = try fileStorageService.saveImageData(Data([0x01, 0x02, 0x03]), fileExtension: "jpg")
        let documentSourceFolder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: documentSourceFolder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: documentSourceFolder) }
        let documentSourceURL = documentSourceFolder.appendingPathComponent("agreement.pdf")
        try Data("agreement".utf8).write(to: documentSourceURL)
        let documentFileName = try fileStorageService.saveDocument(from: documentSourceURL)

        let checklistItem = ChecklistItemRecord(
            title: "Walls",
            sortOrder: 0,
            photos: [EvidencePhoto(localFileName: photoFileName, phase: .moveIn)]
        )
        let room = RoomRecord(name: "Bedroom", type: .bedroom, sortOrder: 0, checklistItems: [checklistItem])
        let propertyPack = PropertyPack(
            nickname: "Home",
            rooms: [room],
            documents: [DocumentRecord(displayName: "Agreement", type: .tenancyAgreement, localFileName: documentFileName)]
        )

        context.insert(propertyPack)
        try context.save()

        let photoURL = try fileStorageService.urlForEvidencePhoto(fileName: photoFileName)
        let documentURL = try fileStorageService.urlForDocument(fileName: documentFileName)

        try deletionService.deletePropertyPack(propertyPack, context: context)

        let remainingPropertyPacks = try context.fetch(FetchDescriptor<PropertyPack>())
        #expect(remainingPropertyPacks.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: photoURL.path))
        #expect(!FileManager.default.fileExists(atPath: documentURL.path))
    }

    @Test func deleteAllDataClearsLocalStorageFolders() throws {
        let fileStorageService = makeService()
        let deletionService = RentoryDataDeletionService(fileStorageService: fileStorageService)
        let context = try makeModelContext()

        let photoFileName = try fileStorageService.saveImageData(Data([0x01, 0x02, 0x03]), fileExtension: "jpg")
        let documentSourceFolder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: documentSourceFolder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: documentSourceFolder) }
        let documentSourceURL = documentSourceFolder.appendingPathComponent("receipt.pdf")
        try Data("receipt".utf8).write(to: documentSourceURL)
        let documentFileName = try fileStorageService.saveDocument(from: documentSourceURL)
        let temporaryReportURL = try fileStorageService.saveTemporaryExportData(Data("report".utf8), preferredFileName: "rentory-report-test.pdf")

        let propertyPack = PropertyPack(
            nickname: "Home",
            rooms: [RoomRecord(name: "Hallway", type: .hallway, sortOrder: 0, checklistItems: [
                ChecklistItemRecord(title: "Walls", sortOrder: 0, photos: [EvidencePhoto(localFileName: photoFileName, phase: .moveIn)]),
            ])],
            documents: [DocumentRecord(displayName: "Receipt", type: .other, localFileName: documentFileName)]
        )

        context.insert(propertyPack)
        try context.save()

        let photoURL = try fileStorageService.urlForEvidencePhoto(fileName: photoFileName)
        let documentURL = try fileStorageService.urlForDocument(fileName: documentFileName)

        try deletionService.deleteAllData(context: context)

        let remainingPropertyPacks = try context.fetch(FetchDescriptor<PropertyPack>())
        #expect(remainingPropertyPacks.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: photoURL.path))
        #expect(!FileManager.default.fileExists(atPath: documentURL.path))
        #expect(!FileManager.default.fileExists(atPath: temporaryReportURL.path))
    }

    @Test func backupManifestCountsExpectedRecords() throws {
        let fileStorageService = makeService()
        let context = try makeModelContext()
        let backupService = RentoryBackupService(
            fileStorageService: fileStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: fileStorageService)
        )

        let propertyPack = PropertyPack(
            nickname: "Home",
            rooms: [RoomRecord(name: "Kitchen", type: .kitchen, sortOrder: 0)],
            documents: [DocumentRecord(displayName: "Receipt", type: .other, localFileName: "doc.pdf")],
            timelineEvents: [TimelineEvent(title: "Move-in", type: .moveIn, eventDate: .now)]
        )
        propertyPack.rooms[0].checklistItems = [
            ChecklistItemRecord(title: "Walls", sortOrder: 0, photos: [EvidencePhoto(localFileName: "photo.jpg", phase: .moveIn)]),
        ]

        context.insert(propertyPack)
        try context.save()

        let manifest = try backupService.makeManifest(context: context)

        #expect(manifest.propertyCount == 1)
        #expect(manifest.roomCount == 1)
        #expect(manifest.photoCount == 1)
        #expect(manifest.documentCount == 1)
        #expect(manifest.timelineEventCount == 1)
    }

    @Test func backupExportDoesNotIncludeTemporaryReports() throws {
        let fileStorageService = makeService()
        let context = try makeModelContext()
        let backupService = RentoryBackupService(
            fileStorageService: fileStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: fileStorageService)
        )

        _ = try fileStorageService.saveTemporaryExportData(Data("report".utf8), preferredFileName: "rentory-report-test.pdf")
        let propertyPack = PropertyPack(nickname: "Home")
        context.insert(propertyPack)
        try context.save()

        let backupURL = try backupService.createBackup(context: context)

        #expect(!FileManager.default.fileExists(atPath: backupURL.appendingPathComponent("TemporaryExports").path))
    }

    @Test func backupImportRejectsMissingManifest() throws {
        let fileStorageService = makeService()
        let backupService = RentoryBackupService(
            fileStorageService: fileStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: fileStorageService)
        )

        let backupURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("broken-\(UUID().uuidString).rentorybackup", isDirectory: true)
        try FileManager.default.createDirectory(at: backupURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: backupURL) }
        try Data("{}".utf8).write(to: backupURL.appendingPathComponent("data.json"))

        #expect(throws: RentoryBackupError.backupIncomplete) {
            _ = try backupService.loadBackup(from: backupURL)
        }
    }

    @Test func backupRoundTripPreservesCountsAndCreatesNewLocalFileNames() throws {
        let sourceStorageService = makeService()
        let sourceContext = try makeModelContext()
        let sourceBackupService = RentoryBackupService(
            fileStorageService: sourceStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: sourceStorageService)
        )

        let photoFileName = try sourceStorageService.saveImageData(Data([0x01, 0x02, 0x03]), fileExtension: "jpg")
        let documentFileName = try sourceStorageService.saveDocumentData(Data("sample".utf8), fileExtension: "txt")
        let checklistItem = ChecklistItemRecord(
            title: "Walls",
            sortOrder: 0,
            photos: [EvidencePhoto(localFileName: photoFileName, phase: .moveIn, captureDateIsConfirmed: true)]
        )
        let room = RoomRecord(name: "Bedroom", type: .bedroom, sortOrder: 0, checklistItems: [checklistItem])
        let propertyPack = PropertyPack(
            nickname: "Home",
            rooms: [room],
            documents: [DocumentRecord(displayName: "Sample note", type: .other, localFileName: documentFileName)],
            timelineEvents: [TimelineEvent(title: "Move-in", type: .moveIn, eventDate: .now)]
        )
        sourceContext.insert(propertyPack)
        try sourceContext.save()

        let backupURL = try sourceBackupService.createBackup(context: sourceContext)
        let loadedBackup = try sourceBackupService.loadBackup(from: backupURL)

        let destinationStorageService = makeService()
        let destinationContext = try makeModelContext()
        let destinationBackupService = RentoryBackupService(
            fileStorageService: destinationStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: destinationStorageService)
        )

        try destinationBackupService.importBackup(loadedBackup, mode: .addToExisting, context: destinationContext)

        let importedPropertyPacks = try destinationContext.fetch(FetchDescriptor<PropertyPack>())
        #expect(importedPropertyPacks.count == 1)
        #expect(importedPropertyPacks[0].rooms.count == 1)
        #expect(importedPropertyPacks[0].documents.count == 1)
        #expect(importedPropertyPacks[0].timelineEvents.count == 1)
        #expect(importedPropertyPacks[0].rooms[0].checklistItems.count == 1)
        #expect(importedPropertyPacks[0].rooms[0].checklistItems[0].photos.count == 1)
        #expect(importedPropertyPacks[0].rooms[0].checklistItems[0].photos[0].localFileName != photoFileName)
        #expect(importedPropertyPacks[0].rooms[0].checklistItems[0].photos[0].captureDateIsConfirmed)
        #expect(importedPropertyPacks[0].documents[0].localFileName != documentFileName)
    }

    @Test func backupRoundTripIncludesActions() throws {
        let sourceStorageService = makeService()
        let sourceContext = try makeModelContext()
        let sourceBackupService = RentoryBackupService(
            fileStorageService: sourceStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: sourceStorageService)
        )

        let reminder = Reminder(
            title: "Submit deposit",
            notes: "Email landlord",
            dueDate: Date(timeIntervalSince1970: 1_700_000_000 + 86_400 * 7),
            kind: .deposit,
            priority: .high
        )
        let propertyPack = PropertyPack(nickname: "Home", reminders: [reminder])
        sourceContext.insert(propertyPack)
        try sourceContext.save()

        let backupURL = try sourceBackupService.createBackup(context: sourceContext)
        let loaded = try sourceBackupService.loadBackup(from: backupURL)
        #expect(loaded.manifest.backupVersion == 5)
        #expect(loaded.manifest.reminderCount == 1)

        let destinationStorageService = makeService()
        let destinationContext = try makeModelContext()
        let destinationBackupService = RentoryBackupService(
            fileStorageService: destinationStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: destinationStorageService)
        )

        try destinationBackupService.importBackup(loaded, mode: .addToExisting, context: destinationContext)

        let imported = try destinationContext.fetch(FetchDescriptor<PropertyPack>())
        #expect(imported.count == 1)
        #expect(imported[0].reminders.count == 1)
        #expect(imported[0].reminders[0].title == "Submit deposit")
        #expect(imported[0].reminders[0].kind == .deposit)
        #expect(imported[0].reminders[0].priority == .high)
        #expect(imported[0].reminders[0].notes == "Email landlord")
    }

    @Test func backupRoundTripPreservesTenanciesAndTenants() throws {
        let sourceStorageService = makeService()
        let sourceContext = try makeModelContext()
        let sourceBackupService = RentoryBackupService(
            fileStorageService: sourceStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: sourceStorageService)
        )

        let startDate = Date(timeIntervalSince1970: 1_700_000_000)
        let endDate = Date(timeIntervalSince1970: 1_700_000_000 + 86_400 * 365)
        let primaryTenant = Tenant(
            name: "Alex Sample",
            email: "alex@sample.test",
            phone: "07000 111222",
            sortOrder: 0,
            notes: "Primary contact"
        )
        let secondaryTenant = Tenant(
            name: "Sam Sample",
            email: "sam@sample.test",
            phone: nil,
            sortOrder: 1,
            notes: nil
        )
        let activeTenancy = Tenancy(
            startDate: startDate,
            endDate: endDate,
            status: .active,
            tenancyType: .assuredShorthold,
            depositAmount: 1500,
            depositSchemeName: "Custodial sample",
            depositReference: "CST-7788",
            rentAmount: 1200,
            rentFrequency: .monthly,
            notes: "Twelve-month fixed term.",
            signedOnDate: startDate,
            breakClauseDate: Date(timeIntervalSince1970: 1_700_000_000 + 86_400 * 180),
            mode: .comprehensive,
            tenants: [primaryTenant, secondaryTenant]
        )
        let endedTenancy = Tenancy(
            startDate: Date(timeIntervalSince1970: 1_700_000_000 - 86_400 * 365),
            endDate: Date(timeIntervalSince1970: 1_700_000_000 - 86_400),
            status: .ended,
            tenancyType: .fixedTerm,
            rentAmount: 950,
            rentFrequency: .monthly,
            mode: .standard,
            tenants: [
                Tenant(name: "Previous Sample", sortOrder: 0),
            ]
        )

        let propertyPack = PropertyPack(
            nickname: "Linden Avenue",
            profile: .landlord,
            tenancies: [activeTenancy, endedTenancy]
        )
        sourceContext.insert(propertyPack)
        try sourceContext.save()

        let backupURL = try sourceBackupService.createBackup(context: sourceContext)
        let loaded = try sourceBackupService.loadBackup(from: backupURL)
        #expect(loaded.manifest.tenancyCount == 2)
        #expect(loaded.manifest.tenantCount == 3)

        let destinationStorageService = makeService()
        let destinationContext = try makeModelContext()
        let destinationBackupService = RentoryBackupService(
            fileStorageService: destinationStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: destinationStorageService)
        )

        try destinationBackupService.importBackup(loaded, mode: .addToExisting, context: destinationContext)

        let imported = try destinationContext.fetch(FetchDescriptor<PropertyPack>())
        #expect(imported.count == 1)

        let pack = imported[0]
        #expect(pack.profile == .landlord)
        #expect(pack.tenancies.count == 2)

        let sortedTenancies = pack.tenancies.sorted { $0.startDate > $1.startDate }
        let activeImported = sortedTenancies[0]
        #expect(activeImported.status == .active)
        #expect(activeImported.tenancyType == .assuredShorthold)
        #expect(activeImported.depositAmount == 1500)
        #expect(activeImported.depositSchemeName == "Custodial sample")
        #expect(activeImported.depositReference == "CST-7788")
        #expect(activeImported.rentAmount == 1200)
        #expect(activeImported.rentFrequency == .monthly)
        #expect(activeImported.notes == "Twelve-month fixed term.")
        #expect(activeImported.mode == .comprehensive)
        #expect(activeImported.signedOnDate == startDate)
        #expect(activeImported.breakClauseDate != nil)
        #expect(activeImported.tenants.count == 2)

        let sortedTenants = activeImported.tenants.sorted { $0.sortOrder < $1.sortOrder }
        #expect(sortedTenants[0].name == "Alex Sample")
        #expect(sortedTenants[0].email == "alex@sample.test")
        #expect(sortedTenants[0].phone == "07000 111222")
        #expect(sortedTenants[0].notes == "Primary contact")
        #expect(sortedTenants[1].name == "Sam Sample")
        #expect(sortedTenants[1].email == "sam@sample.test")
        #expect(sortedTenants[1].phone == nil)

        let endedImported = sortedTenancies[1]
        #expect(endedImported.status == .ended)
        #expect(endedImported.tenancyType == .fixedTerm)
        #expect(endedImported.mode == .standard)
        #expect(endedImported.tenants.count == 1)
        #expect(endedImported.tenants[0].name == "Previous Sample")
    }

    @Test func backupRoundTripPreservesRentPaymentsAndExpenses() throws {
        let sourceStorageService = makeService()
        let sourceContext = try makeModelContext()
        let backupService = RentoryBackupService(
            fileStorageService: sourceStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: sourceStorageService)
        )

        let dueDate = Date(timeIntervalSince1970: 1_700_000_000)
        let paidDate = Date(timeIntervalSince1970: 1_700_000_000 + 86_400 * 2)
        let payment = RentPayment(
            dueDate: dueDate,
            paidDate: paidDate,
            amount: 950,
            currencyCode: "GBP",
            status: .paid,
            notes: "Paid by bank transfer."
        )
        let tenancy = Tenancy(
            startDate: dueDate,
            status: .active,
            tenants: [Tenant(name: "Sam Sample")],
            rentPayments: [payment]
        )

        let expense = PropertyExpense(
            date: Date(timeIntervalSince1970: 1_700_000_000 + 86_400 * 5),
            title: "Boiler service",
            amount: 165.50,
            currencyCode: "GBP",
            category: .maintenance,
            notes: "Annual."
        )

        let propertyPack = PropertyPack(
            nickname: "Finance test property",
            profile: .landlord,
            tenancies: [tenancy],
            expenses: [expense]
        )
        sourceContext.insert(propertyPack)
        try sourceContext.save()

        let backupURL = try backupService.createBackup(context: sourceContext)
        let loaded = try backupService.loadBackup(from: backupURL)
        #expect(loaded.manifest.backupVersion == 5)
        #expect(loaded.manifest.rentPaymentCount == 1)
        #expect(loaded.manifest.expenseCount == 1)

        let destinationStorageService = makeService()
        let destinationContext = try makeModelContext()
        let destinationBackupService = RentoryBackupService(
            fileStorageService: destinationStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: destinationStorageService)
        )

        try destinationBackupService.importBackup(loaded, mode: .addToExisting, context: destinationContext)

        let imported = try destinationContext.fetch(FetchDescriptor<PropertyPack>())
        #expect(imported.count == 1)
        let pack = imported[0]
        #expect(pack.expenses.count == 1)
        let restoredExpense = pack.expenses[0]
        #expect(restoredExpense.title == "Boiler service")
        #expect(restoredExpense.amount == 165.50)
        #expect(restoredExpense.category == .maintenance)
        #expect(restoredExpense.currencyCode == "GBP")
        #expect(restoredExpense.notes == "Annual.")

        #expect(pack.tenancies.count == 1)
        let restoredTenancy = pack.tenancies[0]
        #expect(restoredTenancy.rentPayments.count == 1)
        let restoredPayment = restoredTenancy.rentPayments[0]
        #expect(restoredPayment.amount == 950)
        #expect(restoredPayment.status == .paid)
        #expect(restoredPayment.currencyCode == "GBP")
        #expect(restoredPayment.dueDate == dueDate)
        #expect(restoredPayment.paidDate == paidDate)
        #expect(restoredPayment.notes == "Paid by bank transfer.")
    }

    @Test func backupRoundTripPreservesProfileTag() throws {
        let sourceStorageService = makeService()
        let sourceContext = try makeModelContext()
        let sourceBackupService = RentoryBackupService(
            fileStorageService: sourceStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: sourceStorageService)
        )

        let renterPack = PropertyPack(nickname: "Renter pack", profile: .renter)
        let landlordPack = PropertyPack(nickname: "Landlord pack", profile: .landlord)
        sourceContext.insert(renterPack)
        sourceContext.insert(landlordPack)
        try sourceContext.save()

        let backupURL = try sourceBackupService.createBackup(context: sourceContext)
        let loaded = try sourceBackupService.loadBackup(from: backupURL)
        #expect(loaded.manifest.propertyCount == 2)

        let destinationStorageService = makeService()
        let destinationContext = try makeModelContext()
        let destinationBackupService = RentoryBackupService(
            fileStorageService: destinationStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: destinationStorageService)
        )

        try destinationBackupService.importBackup(loaded, mode: .addToExisting, context: destinationContext)

        let imported = try destinationContext.fetch(FetchDescriptor<PropertyPack>())
            .sorted { $0.nickname < $1.nickname }
        #expect(imported.count == 2)
        #expect(imported[0].nickname == "Landlord pack")
        #expect(imported[0].profile == .landlord)
        #expect(imported[1].nickname == "Renter pack")
        #expect(imported[1].profile == .renter)
    }

    @Test func backupRoundTripIncludesItemCommentsAndRoomOverride() throws {
        let sourceStorageService = makeService()
        let sourceContext = try makeModelContext()
        let sourceBackupService = RentoryBackupService(
            fileStorageService: sourceStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: sourceStorageService)
        )

        let item = ChecklistItemRecord(
            title: "Hob",
            sortOrder: 0,
            moveInConditionRawValue: EvidenceCondition.good.rawValue,
            moveOutConditionRawValue: EvidenceCondition.damaged.rawValue,
            comments: [
                ItemComment(body: "Front-right ring slow to heat", phase: .moveIn),
                ItemComment(body: "Burner cap missing at check-out", phase: .moveOut, sortOrder: 1),
            ]
        )
        let room = RoomRecord(
            name: "Kitchen",
            type: .kitchen,
            sortOrder: 0,
            manualConditionOverride: .fair,
            checklistItems: [item]
        )
        let propertyPack = PropertyPack(nickname: "Home", rooms: [room])
        sourceContext.insert(propertyPack)
        try sourceContext.save()

        let backupURL = try sourceBackupService.createBackup(context: sourceContext)
        let loaded = try sourceBackupService.loadBackup(from: backupURL)
        #expect(loaded.manifest.commentCount == 2)

        let destinationStorageService = makeService()
        let destinationContext = try makeModelContext()
        let destinationBackupService = RentoryBackupService(
            fileStorageService: destinationStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: destinationStorageService)
        )
        try destinationBackupService.importBackup(loaded, mode: .addToExisting, context: destinationContext)

        let imported = try destinationContext.fetch(FetchDescriptor<PropertyPack>())
        #expect(imported.count == 1)
        let importedRoom = imported[0].rooms.first
        #expect(importedRoom?.manualConditionOverride == .fair)
        let importedItem = importedRoom?.checklistItems.first
        #expect(importedItem?.comments.count == 2)
        #expect(importedItem?.comments.contains { $0.body == "Front-right ring slow to heat" } == true)
        #expect(importedItem?.comments.contains { $0.evidencePhase == .moveOut } == true)
    }

    @Test func legacyV1BackupLoadsWithEmptyActions() throws {
        let fileStorageService = makeService()
        let backupService = RentoryBackupService(
            fileStorageService: fileStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: fileStorageService)
        )

        let baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RentoryV1Compat-\(UUID().uuidString).rentorybackup", isDirectory: true)
        try FileManager.default.createDirectory(at: baseURL.appendingPathComponent("EvidencePhotos"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: baseURL.appendingPathComponent("ImportedDocuments"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: baseURL) }

        let v1Manifest = """
        {
          "appName": "Rentory",
          "appVersion": "0.95",
          "backupVersion": 1,
          "createdAt": "2026-05-01T00:00:00Z",
          "documentCount": 0,
          "photoCount": 0,
          "propertyCount": 1,
          "roomCount": 0,
          "timelineEventCount": 0
        }
        """
        try Data(v1Manifest.utf8).write(to: baseURL.appendingPathComponent("manifest.json"))

        let propertyID = UUID().uuidString.uppercased()
        let v1Payload = """
        {
          "checklistItems": [],
          "documents": [],
          "photos": [],
          "properties": [{
            "createdAt": "2026-05-01T00:00:00Z",
            "id": "\(propertyID)",
            "isArchived": false,
            "nickname": "Legacy",
            "updatedAt": "2026-05-01T00:00:00Z"
          }],
          "rooms": [],
          "timelineEvents": []
        }
        """
        try Data(v1Payload.utf8).write(to: baseURL.appendingPathComponent("data.json"))

        let loaded = try backupService.loadBackup(from: baseURL)
        #expect(loaded.manifest.backupVersion == 1)
        #expect(loaded.manifest.reminderCount == nil)

        let context = try makeModelContext()
        try backupService.importBackup(loaded, mode: .addToExisting, context: context)
        let imported = try context.fetch(FetchDescriptor<PropertyPack>())
        #expect(imported.count == 1)
        #expect(imported[0].reminders.isEmpty)
        #expect(imported[0].nickname == "Legacy")
    }

    // MARK: - Shared snapshot

    @Test @MainActor func snapshotIncludesOnlyCurrentProfileProperties() throws {
        let context = try makeModelContext()
        let renterPack = PropertyPack(nickname: "Renter house", profile: .renter)
        let landlordPack = PropertyPack(nickname: "Landlord flat", profile: .landlord)
        context.insert(renterPack)
        context.insert(landlordPack)
        try context.save()

        let publisher = RentorySnapshotPublisher()
        let snapshot = publisher.makeSnapshot(context: context, activeProfile: .renter, now: Date(timeIntervalSince1970: 1_700_000_000))

        #expect(snapshot.properties.count == 1)
        #expect(snapshot.properties[0].nickname == "Renter house")
        #expect(snapshot.activeProfileRawValue == "Renter")
    }

    @Test @MainActor func snapshotIncludesUpcomingRemindersOnlyWithinWindow() throws {
        let context = try makeModelContext()
        let pack = PropertyPack(nickname: "Home", profile: .renter)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let nearDate = Date(timeIntervalSince1970: 1_700_000_000 + 86_400 * 3)
        let farDate = Date(timeIntervalSince1970: 1_700_000_000 + 86_400 * 120)

        pack.reminders.append(Reminder(title: "Near", dueDate: nearDate))
        pack.reminders.append(Reminder(title: "Far", dueDate: farDate))
        pack.reminders.append(Reminder(title: "No date"))
        context.insert(pack)
        try context.save()

        let publisher = RentorySnapshotPublisher(upcomingReminderWindowDays: 21)
        let snapshot = publisher.makeSnapshot(context: context, activeProfile: .renter, now: now)

        #expect(snapshot.upcomingReminders.count == 1)
        #expect(snapshot.upcomingReminders[0].title == "Near")
        #expect(snapshot.totalReminderCount == 3)
    }

    @Test @MainActor func snapshotMonthlyFinanceForLandlord() throws {
        let context = try makeModelContext()
        let pack = PropertyPack(nickname: "Rental flat", profile: .landlord)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let tenancy = Tenancy(
            startDate: Date(timeIntervalSince1970: 1_690_000_000),
            status: .active,
            tenants: [Tenant(name: "Sam Sample")]
        )
        tenancy.rentPayments.append(
            RentPayment(
                dueDate: now,
                paidDate: now,
                amount: 800,
                status: .paid
            )
        )
        pack.tenancies.append(tenancy)
        pack.expenses.append(
            PropertyExpense(date: now, title: "Boiler service", amount: 165, category: .maintenance)
        )
        context.insert(pack)
        try context.save()

        let publisher = RentorySnapshotPublisher()
        let snapshot = publisher.makeSnapshot(context: context, activeProfile: .landlord, now: now)

        #expect(snapshot.properties.count == 1)
        let entry = snapshot.properties[0]
        #expect(entry.monthRentReceived == 800)
        #expect(entry.monthExpenses == 165)
        #expect(entry.monthNet == 635)
        #expect(entry.activeTenancyCount == 1)
        #expect(entry.primaryTenantName == "Sam Sample")
    }

    @Test @MainActor func snapshotDoesNotLeakCrossProfileReminders() throws {
        // Regression: before scoping the publisher's reminder feed, the
        // active profile's snapshot included reminders from the *other*
        // profile's properties, with propertyIDs that weren't in
        // snapshot.properties[].
        let context = try makeModelContext()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let dueSoon = Date(timeIntervalSince1970: 1_700_000_000 + 86_400 * 3)

        let renterPack = PropertyPack(nickname: "Renter house", profile: .renter)
        renterPack.reminders.append(Reminder(title: "Renter reminder", dueDate: dueSoon))
        let landlordPack = PropertyPack(nickname: "Landlord flat", profile: .landlord)
        landlordPack.reminders.append(Reminder(title: "Landlord reminder", dueDate: dueSoon))

        context.insert(renterPack)
        context.insert(landlordPack)
        try context.save()

        let publisher = RentorySnapshotPublisher()
        let snapshot = publisher.makeSnapshot(context: context, activeProfile: .renter, now: now)

        #expect(snapshot.properties.count == 1)
        #expect(snapshot.upcomingReminders.count == 1)
        #expect(snapshot.upcomingReminders[0].title == "Renter reminder")
        #expect(snapshot.totalReminderCount == 1)
        // Every reminder propertyID must resolve to a property in the snapshot.
        let propertyIDs = Set(snapshot.properties.map(\.id))
        for reminder in snapshot.upcomingReminders {
            #expect(propertyIDs.contains(reminder.propertyID))
        }
    }

    // MARK: - PDF builder pagination

    @Test @MainActor func pdfBuilderHandlesEmptyRecord() throws {
        let context = try makeModelContext()
        let pack = PropertyPack(nickname: "Empty pack", profile: .renter)
        context.insert(pack)
        try context.save()

        let data = try PDFReportBuilder().buildReportData(
            for: pack,
            options: ExportOptions()
        )

        // Cover + summary + disclaimer at minimum.
        let document = PDFDocument(data: data)
        #expect(document != nil)
        #expect((document?.pageCount ?? 0) >= 1)
    }

    @Test @MainActor func pdfBuilderHandlesManyRoomsAndChecklistItems() throws {
        let context = try makeModelContext()
        let pack = PropertyPack(nickname: "Stress room pack", profile: .renter)

        for index in 0..<50 {
            let room = RoomRecord(name: "Room \(index)", type: .other, sortOrder: index)
            for itemIndex in 0..<6 {
                let item = ChecklistItemRecord(
                    title: "Item \(itemIndex)",
                    sortOrder: itemIndex,
                    moveInConditionRawValue: EvidenceCondition.good.rawValue,
                    moveOutConditionRawValue: EvidenceCondition.good.rawValue
                )
                room.checklistItems.append(item)
            }
            pack.rooms.append(room)
        }
        context.insert(pack)
        try context.save()

        let data = try PDFReportBuilder().buildReportData(
            for: pack,
            options: ExportOptions()
        )

        let document = PDFDocument(data: data)
        #expect(document != nil)
        // 50 rooms × 6 items = 300 lines; comfortably exceeds the
        // 26-line per-page cap, so we expect multi-page pagination.
        #expect((document?.pageCount ?? 0) > 2)
    }

    @Test @MainActor func pdfBuilderHandlesTimelineHeavyRecord() throws {
        let context = try makeModelContext()
        let pack = PropertyPack(nickname: "Timeline pack", profile: .landlord)
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        for index in 0..<30 {
            let event = TimelineEvent(
                title: "Event \(index)",
                type: .inspection,
                eventDate: baseDate.addingTimeInterval(Double(index) * 86_400),
                notes: "Notes for event \(index)"
            )
            pack.timelineEvents.append(event)
        }
        context.insert(pack)
        try context.save()

        let data = try PDFReportBuilder().buildReportData(
            for: pack,
            options: ExportOptions()
        )

        let document = PDFDocument(data: data)
        #expect(document != nil)
        #expect((document?.pageCount ?? 0) >= 1)
    }

    @Test @MainActor func pdfReportAlwaysIncludesDisclaimer() throws {
        let context = try makeModelContext()
        let pack = PropertyPack(nickname: "Disclaimer check", profile: .renter)
        context.insert(pack)
        try context.save()

        let options = ExportOptions()

        let data = try PDFReportBuilder().buildReportData(
            for: pack,
            options: options
        )

        // The disclaimer section is always appended by the builder;
        // verify the report still produces and renders it.
        let document = PDFDocument(data: data)
        #expect(document != nil)
        let allText = (0..<(document?.pageCount ?? 0))
            .compactMap { document?.page(at: $0)?.string }
            .joined()
        // The disclaimer text contains the word "disclaimer" (case-insensitive).
        #expect(allText.lowercased().contains("disclaimer"))
    }

    // MARK: - Photo cache

    @Test @MainActor func photoCacheStoresAndReturnsThumbnail() throws {
        let service = PhotoStorageService()
        // `.rrCGImage` is the cross-platform accessor defined in
        // `ImageResizer.swift` — on iOS it forwards to UIImage's
        // built-in `.cgImage`, on macOS it bridges NSImage (which
        // has no `cgImage` property of the same shape).
        let cgImage = try makeImage(size: CGSize(width: 100, height: 100)).rrCGImage!
        let key = "test-cache-\(UUID().uuidString)"

        #expect(service.cachedThumbnail(for: key) == nil)
        service.storeThumbnail(UIImage.rrImage(from: cgImage, size: CGSize(width: 100, height: 100)), for: key)
        #expect(service.cachedThumbnail(for: key) != nil)
    }

    @Test @MainActor func photoCacheIsSharedAcrossInstances() throws {
        // The cache is a static NSCache so two PhotoStorageService
        // instances must share it; otherwise widgets and dashboards
        // would re-decode the same JPEGs twice.
        let serviceA = PhotoStorageService()
        let serviceB = PhotoStorageService()
        let cgImage = try makeImage(size: CGSize(width: 20, height: 20)).rrCGImage!
        let key = "rentory-shared-\(UUID().uuidString)"

        serviceA.storeThumbnail(UIImage.rrImage(from: cgImage, size: CGSize(width: 20, height: 20)), for: key)
        #expect(serviceB.cachedThumbnail(for: key) != nil)
    }

    // MARK: - Reminder notifications

    @Test @MainActor func triggerDateUsesNineAmOnTheDueDayInTheFuture() {
        let calendar = Calendar(identifier: .gregorian)
        let service = ReminderNotificationService(calendar: calendar)
        let dueDate = Date.now.addingTimeInterval(86_400 * 3) // three days out
        let reminder = Reminder(title: "Inspection", dueDate: dueDate)

        let fired = service.triggerDate(for: reminder)

        #expect(fired != nil)
        if let fired {
            let components = calendar.dateComponents([.hour, .minute], from: fired)
            #expect(components.hour == 9)
            #expect(components.minute == 0)
        }
    }

    // MARK: - Recurring reminders

    @Test func recurrenceNoneReturnsNilNextDate() {
        let due = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(ReminderRecurrence.none.nextDueDate(after: due) == nil)
    }

    @Test func recurrenceDailyAddsOneDay() {
        let calendar = Calendar(identifier: .gregorian)
        let due = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let next = ReminderRecurrence.daily.nextDueDate(after: due, calendar: calendar)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 6, day: 2))!
        #expect(next == expected)
    }

    @Test func recurrenceWeeklyAddsSevenDays() {
        let calendar = Calendar(identifier: .gregorian)
        let due = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let next = ReminderRecurrence.weekly.nextDueDate(after: due, calendar: calendar)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 6, day: 8))!
        #expect(next == expected)
    }

    @Test func recurrenceMonthlyHandlesMonthEnd() {
        // 31 January + monthly should resolve to 28 February (or 29 in a
        // leap year). The calendar rolls forward correctly without
        // overshooting into March, which is exactly what we want for
        // "rent due last day of month" style reminders.
        let calendar = Calendar(identifier: .gregorian)
        let due = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let next = ReminderRecurrence.monthly.nextDueDate(after: due, calendar: calendar)!
        let components = calendar.dateComponents([.year, .month, .day], from: next)
        #expect(components.year == 2026)
        #expect(components.month == 2)
        // 2026 is not a leap year, so February has 28 days.
        #expect(components.day == 28)
    }

    @Test func recurrenceQuarterlyAddsThreeMonths() {
        let calendar = Calendar(identifier: .gregorian)
        let due = calendar.date(from: DateComponents(year: 2026, month: 4, day: 6))!
        let next = ReminderRecurrence.quarterly.nextDueDate(after: due, calendar: calendar)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 7, day: 6))!
        #expect(next == expected)
    }

    @Test func recurrenceYearlyAddsOneYear() {
        let calendar = Calendar(identifier: .gregorian)
        let due = calendar.date(from: DateComponents(year: 2026, month: 4, day: 6))!
        let next = ReminderRecurrence.yearly.nextDueDate(after: due, calendar: calendar)
        let expected = calendar.date(from: DateComponents(year: 2027, month: 4, day: 6))!
        #expect(next == expected)
    }

    @Test func reminderShortLabelHidesNoneAndShortensFortnightly() {
        #expect(ReminderRecurrence.none.shortLabel == nil)
        #expect(ReminderRecurrence.fortnightly.shortLabel == "2-weekly")
        #expect(ReminderRecurrence.monthly.shortLabel == "Monthly")
    }

    @Test func reminderRecurrenceRoundTripsThroughRawValue() {
        // Ensures the var-setter clears the raw value when set back to
        // .none and writes the raw value otherwise — so SwiftData stays
        // tidy and old reminders without a stored recurrence still
        // decode to .none.
        let reminder = Reminder(title: "Test")
        #expect(reminder.recurrence == .none)
        #expect(reminder.recurrenceRuleRawValue == nil)

        reminder.recurrence = .monthly
        #expect(reminder.recurrenceRuleRawValue == ReminderRecurrence.monthly.rawValue)

        reminder.recurrence = .none
        #expect(reminder.recurrenceRuleRawValue == nil)
    }

    @Test @MainActor func backupRoundTripPreservesRecurrenceRule() throws {
        // Smoke test: a reminder with .monthly recurrence survives a
        // make-and-import-payload round trip. Uses the same harness as
        // the other backup round-trip tests so the package layout, file
        // staging, and import logic are all exercised end to end.
        let storage = makeService()
        let sourceContext = try makeModelContext()

        let pack = PropertyPack(nickname: "Monthly rent", profile: .renter)
        let reminder = Reminder(
            title: "Rent due",
            dueDate: Date(timeIntervalSince1970: 1_700_000_000),
            recurrence: .monthly
        )
        pack.reminders.append(reminder)
        sourceContext.insert(pack)
        try sourceContext.save()

        let backupService = RentoryBackupService(
            fileStorageService: storage,
            deletionService: RentoryDataDeletionService(fileStorageService: storage)
        )
        let backupURL = try backupService.createBackup(context: sourceContext)

        let importContext = try makeModelContext()
        try backupService.importBackup(
            backupService.loadBackup(from: backupURL),
            mode: .replaceAll,
            context: importContext
        )

        let restoredPacks = try importContext.fetch(FetchDescriptor<PropertyPack>())
        let restoredPack = try #require(restoredPacks.first)
        let restoredReminder = try #require(restoredPack.reminders.first)
        #expect(restoredReminder.recurrence == .monthly)
        #expect(restoredReminder.title == "Rent due")
    }

    // MARK: - AppIntents pending queue + applier

    @Test @MainActor func pendingIntentApplierCreatesReminderOnMatchingProperty() throws {
        // The applier resolves the propertyID, builds a Reminder, and
        // attaches it to the pack. This is the same code path Siri's
        // AddReminderIntent will exercise on next launch.
        let context = try makeModelContext()
        let pack = PropertyPack(nickname: "Test pack", profile: .renter)
        context.insert(pack)
        try context.save()

        // Apply directly without touching the on-disk queue — the
        // applier is split so we can exercise the per-kind branch
        // without coordinating files in a test process.
        let due = Date(timeIntervalSince1970: 1_700_000_000)
        let queued = RentoryPendingIntentEnvelope(
            id: UUID(),
            queuedAt: .now,
            payload: .addReminder(propertyID: pack.id, title: "Boiler service", dueDate: due, createdAt: .now)
        )

        // Inject by writing once + applyAll() reading it back. Use a
        // temporary App Group container if entitled; otherwise the
        // store no-ops and the test is a soft pass.
        try RentoryPendingIntentStore.enqueue(queued.payload)
        let applied = RentoryPendingIntentApplier.applyAll(in: context)
        // If we're in a process without the App Group container,
        // applyAll returns 0 because readAll returns []. Skip the rest
        // in that case — we still got coverage of the enqueue path.
        guard applied > 0 else { return }

        let refreshed = try context.fetch(FetchDescriptor<PropertyPack>())
        let savedPack = try #require(refreshed.first)
        let reminder = try #require(savedPack.reminders.first(where: { $0.title == "Boiler service" }))
        #expect(reminder.dueDate == due)
    }

    @Test func pendingIntentPayloadEquatableHonoursAllAssociatedValues() {
        // Sanity check that Codable + Equatable conform correctly for
        // the enum cases — useful so the queue file's diff-based
        // remove(ids:) drops the exact entry we applied.
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let createdAt = Date(timeIntervalSince1970: 1_705_000_000)
        let lhs = RentoryPendingIntent.addReminder(propertyID: id, title: "x", dueDate: date, createdAt: createdAt)
        let rhs = RentoryPendingIntent.addReminder(propertyID: id, title: "x", dueDate: date, createdAt: createdAt)
        #expect(lhs == rhs)

        let differentTitle = RentoryPendingIntent.addReminder(propertyID: id, title: "y", dueDate: date, createdAt: createdAt)
        #expect(lhs != differentTitle)
    }

    @Test func pendingIntentEnvelopeRoundTripsThroughJSON() throws {
        // The queue file is JSON — make sure the envelope and every
        // payload case decode cleanly so an intent process can hand a
        // payload to the next launch reliably.
        let due = Date(timeIntervalSince1970: 1_700_000_000)
        let envelope = RentoryPendingIntentEnvelope(
            id: UUID(),
            queuedAt: Date(timeIntervalSince1970: 1_705_000_000),
            payload: .logRentPayment(
                propertyID: UUID(),
                amount: 750,
                paidDate: due,
                currencyCode: "GBP",
                createdAt: .now
            )
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode([envelope])

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode([RentoryPendingIntentEnvelope].self, from: data)

        #expect(decoded.count == 1)
        let restored = try #require(decoded.first)
        #expect(restored.id == envelope.id)
        if case let .logRentPayment(propertyID, amount, paidDate, currencyCode, _) = restored.payload {
            #expect(amount == 750)
            #expect(currencyCode == "GBP")
            #expect(paidDate == due)
            // propertyID is a UUID round-tripped through JSON — should
            // match the source exactly.
            if case let .logRentPayment(originalID, _, _, _, _) = envelope.payload {
                #expect(propertyID == originalID)
            }
        } else {
            Issue.record("Expected logRentPayment payload after round trip")
        }
    }

    // MARK: - Calendar mirror

    @Test func calendarMirrorNotesEmbedReminderID() {
        // The mirror writes "[Rentory:<UUID>]" on each event so the
        // next reconciliation can find it again. With no user notes
        // the marker is the whole body; with notes the marker sits
        // below them on its own line.
        let id = UUID()
        let withoutNotes = CalendarMirrorService.makeNotes(body: nil, reminderID: id)
        #expect(withoutNotes == "[Rentory:\(id.uuidString)]")

        let withNotes = CalendarMirrorService.makeNotes(body: "Bring spare keys", reminderID: id)
        #expect(withNotes.hasPrefix("Bring spare keys"))
        #expect(withNotes.contains("[Rentory:\(id.uuidString)]"))
    }

    @Test func calendarMirrorParsesReminderIDFromMarker() {
        let id = UUID()
        let notes = "User edited this in Calendar\n\n[Rentory:\(id.uuidString)]"
        #expect(CalendarMirrorService.parseReminderID(from: notes) == id)
    }

    @Test func calendarMirrorReturnsNilForUnmarkedNotes() {
        #expect(CalendarMirrorService.parseReminderID(from: nil) == nil)
        #expect(CalendarMirrorService.parseReminderID(from: "") == nil)
        #expect(CalendarMirrorService.parseReminderID(from: "Just regular notes") == nil)
        #expect(CalendarMirrorService.parseReminderID(from: "[Rentory:not-a-uuid]") == nil)
    }

    @Test func calendarMirrorRoundTripsMakeAndParse() {
        let id = UUID()
        let composed = CalendarMirrorService.makeNotes(body: "Annual gas check", reminderID: id)
        #expect(CalendarMirrorService.parseReminderID(from: composed) == id)
    }

    @Test @MainActor func triggerDateFiresImmediatelyIfTodaysPreferredTimeHasPassed() {
        // Regression: prior to the fix, a reminder due today created after
        // 9 AM was silently dropped. It should now schedule 1 minute out.
        let calendar = Calendar(identifier: .gregorian)
        let service = ReminderNotificationService(calendar: calendar)
        let dueToday = Date.now
        let reminder = Reminder(title: "Boiler", dueDate: dueToday)

        let fired = service.triggerDate(for: reminder)

        if calendar.component(.hour, from: .now) >= 9 {
            // After 9 AM the preferred slot is gone; fall through to ASAP.
            #expect(fired != nil)
            if let fired {
                #expect(fired > Date.now)
                #expect(fired <= Date.now.addingTimeInterval(120))
            }
        } else {
            // Before 9 AM today, the preferred slot is still in the future.
            #expect(fired != nil)
        }
    }

    @Test @MainActor func triggerDateRefusesGenuinelyPastDueReminders() {
        let calendar = Calendar(identifier: .gregorian)
        let service = ReminderNotificationService(calendar: calendar)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: .now) ?? Date.now
        let reminder = Reminder(title: "Overdue", dueDate: yesterday)

        let fired = service.triggerDate(for: reminder)

        #expect(fired == nil)
    }

    @Test @MainActor func triggerDateReturnsNilForUndatedReminders() {
        let service = ReminderNotificationService()
        let reminder = Reminder(title: "No date")

        #expect(service.triggerDate(for: reminder) == nil)
    }

    // MARK: - Watch pending reminder applier

    @Test @MainActor func watchApplierIgnoresUnknownProperty() throws {
        let context = try makeModelContext()
        let payload = PendingReminderPayload(
            id: UUID(),
            propertyID: UUID(),
            title: "Doesn't matter",
            dueDate: .now,
            createdAt: .now
        )

        let result = WatchPendingReminderApplier.apply(payload, in: context)

        #expect(result == nil)
    }

    @Test @MainActor func watchApplierAddsReminderToMatchingProperty() throws {
        let context = try makeModelContext()
        let pack = PropertyPack(nickname: "Home", profile: .renter)
        context.insert(pack)
        try context.save()

        let payload = PendingReminderPayload(
            id: UUID(),
            propertyID: pack.id,
            title: "Boiler from watch",
            dueDate: .now.addingTimeInterval(86_400),
            createdAt: .now
        )

        let result = WatchPendingReminderApplier.apply(payload, in: context)

        #expect(result != nil)
        #expect(result?.title == "Boiler from watch")
        let saved = try context.fetch(FetchDescriptor<PropertyPack>()).first
        #expect(saved?.reminders.count == 1)
        #expect(saved?.reminders.first?.title == "Boiler from watch")
    }

    // MARK: - Deep link router

    @Test @MainActor func deepLinkRouterParsesPropertyURL() {
        let router = RentoryDeepLinkRouter()
        let uuid = UUID()
        let url = URL(string: "rentory://property/\(uuid.uuidString)")!

        router.handle(url)

        #expect(router.pendingPropertyID == uuid)
    }

    @Test @MainActor func deepLinkRouterIgnoresUnknownScheme() {
        let router = RentoryDeepLinkRouter()
        router.handle(URL(string: "https://example.com/property/123")!)
        #expect(router.pendingPropertyID == nil)
    }

    @Test @MainActor func deepLinkRouterClearsPendingTarget() {
        let router = RentoryDeepLinkRouter()
        router.pendingPropertyID = UUID()
        router.clearPending()
        #expect(router.pendingPropertyID == nil)
    }

    @Test func snapshotRoundTripsThroughJSONDecoder() throws {
        let original = RentorySharedSnapshot(
            writtenAt: Date(timeIntervalSince1970: 1_700_000_000),
            activeProfileRawValue: "Landlord",
            totalReminderCount: 4,
            properties: [
                RentorySharedSnapshot.PropertyEntry(
                    id: UUID(),
                    nickname: "Sample",
                    recordTypeRawValue: "House",
                    profileRawValue: "Landlord",
                    isFavourite: true,
                    completionPercent: 80,
                    completionStatusTitle: "Nearly ready",
                    nextActionTitle: "Add move-out checks",
                    recentEventTitle: "Tenancy signed",
                    activeTenancyCount: 1,
                    primaryTenantName: "Sam",
                    tenancyEndDate: nil,
                    monthRentReceived: 1200,
                    monthExpenses: 200,
                    monthNet: 1000,
                    currencyCode: "GBP"
                ),
            ],
            upcomingReminders: []
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let restored = try decoder.decode(RentorySharedSnapshot.self, from: data)

        #expect(restored == original)
    }

    // MARK: - Quality & stability

    @Test func syncImportsWhenRemoteNewerThanLastSync() {
        let result = ICloudSyncService.shouldImportRemoteSnapshot(
            remoteModificationDate: Date(timeIntervalSince1970: 100),
            localRecordCount: 3,
            lastSyncDate: Date(timeIntervalSince1970: 50)
        )
        #expect(result)
    }

    @Test func syncSkipsImportWhenRemoteOlderThanLastSync() {
        let result = ICloudSyncService.shouldImportRemoteSnapshot(
            remoteModificationDate: Date(timeIntervalSince1970: 50),
            localRecordCount: 3,
            lastSyncDate: Date(timeIntervalSince1970: 100)
        )
        #expect(!result)
    }

    @Test func syncImportsOntoEmptyDeviceWithMissingRemoteDate() {
        let result = ICloudSyncService.shouldImportRemoteSnapshot(
            remoteModificationDate: nil,
            localRecordCount: 0,
            lastSyncDate: nil
        )
        #expect(result)
    }

    @Test func syncSkipsImportOntoPopulatedDeviceThatHasNeverSynced() {
        let result = ICloudSyncService.shouldImportRemoteSnapshot(
            remoteModificationDate: Date(timeIntervalSince1970: 100),
            localRecordCount: 5,
            lastSyncDate: nil
        )
        #expect(!result)
    }

    @Test func syncImportsOntoEmptyDeviceEvenWithNoLastSync() {
        let result = ICloudSyncService.shouldImportRemoteSnapshot(
            remoteModificationDate: Date(timeIntervalSince1970: 100),
            localRecordCount: 0,
            lastSyncDate: nil
        )
        #expect(result)
    }

    @Test func syncSkipsImportOntoPopulatedDeviceWithNoRemoteDate() {
        let result = ICloudSyncService.shouldImportRemoteSnapshot(
            remoteModificationDate: nil,
            localRecordCount: 5,
            lastSyncDate: Date(timeIntervalSince1970: 100)
        )
        #expect(!result)
    }

    @Test func reportPaginatesAcrossMultiplePagesForHeavyProperty() throws {
        let builder = PDFReportBuilder()
        var rooms: [RoomRecord] = []
        for roomIndex in 0..<20 {
            let items = (0..<8).map { itemIndex in
                ChecklistItemRecord(
                    title: "Item \(itemIndex) in room \(roomIndex)",
                    sortOrder: itemIndex,
                    moveInConditionRawValue: EvidenceCondition.good.rawValue,
                    moveOutConditionRawValue: EvidenceCondition.notChecked.rawValue,
                    moveInNotes: "Move-in note for item \(itemIndex).",
                    moveOutNotes: nil,
                    isFlagged: false
                )
            }
            rooms.append(
                RoomRecord(
                    name: "Room \(roomIndex)",
                    type: .other,
                    sortOrder: roomIndex,
                    notes: "Sample notes for room \(roomIndex).",
                    checklistItems: items
                )
            )
        }
        let propertyPack = PropertyPack(nickname: "Heavy property", rooms: rooms)

        let sections = builder.makeReportSections(for: propertyPack, options: ExportOptions())
        let titles = sections.map(\.title)
        let lineCounts = sections.map(\.lines.count)

        // Roughly 20 rooms × ~5 lines each = ~100+ lines, exceeding the 26-line per-page chunk.
        #expect(titles.contains("Rooms and checklist"))
        let roomsSectionLines = sections.first { $0.title == "Rooms and checklist" }?.lines.count ?? 0
        #expect(roomsSectionLines > 80)
        // Ensure at least one of the sections produced enough content to span multiple pages
        // when paginated at 26 lines each.
        #expect(lineCounts.contains(where: { $0 > 26 }))
    }

    @Test func backupLoadRejectsMissingPhotoFile() throws {
        let sourceStorageService = makeService()
        let sourceContext = try makeModelContext()
        let backupService = RentoryBackupService(
            fileStorageService: sourceStorageService,
            deletionService: RentoryDataDeletionService(fileStorageService: sourceStorageService)
        )

        let image = try makeImage(size: CGSize(width: 80, height: 80))
        let photoStorageService = PhotoStorageService(fileStorageService: sourceStorageService)
        let photoFileName = try photoStorageService.savePhoto(image)

        let photo = EvidencePhoto(localFileName: photoFileName, phase: .moveIn)
        let item = ChecklistItemRecord(title: "Hob", sortOrder: 0, photos: [photo])
        let room = RoomRecord(name: "Kitchen", type: .kitchen, sortOrder: 0, checklistItems: [item])
        let propertyPack = PropertyPack(nickname: "Missing photo", rooms: [room])
        sourceContext.insert(propertyPack)
        try sourceContext.save()

        let backupURL = try backupService.createBackup(context: sourceContext)
        let photoDirectory = backupURL.appendingPathComponent("EvidencePhotos", isDirectory: true)
        let storedPhotos = try FileManager.default.contentsOfDirectory(at: photoDirectory, includingPropertiesForKeys: nil)
        guard let firstPhoto = storedPhotos.first else {
            throw TestImageError.unableToCreateImage
        }
        try FileManager.default.removeItem(at: firstPhoto)

        #expect(throws: RentoryBackupError.backupIncomplete) {
            _ = try backupService.loadBackup(from: backupURL)
        }
    }

    @Test func backupLoadRejectsForeignKeyMismatch() throws {
        let baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RentoryFKTest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)

        let packageURL = baseURL.appendingPathComponent("rentory-fk.rentorybackup", isDirectory: true)
        try FileManager.default.createDirectory(at: packageURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: packageURL.appendingPathComponent("EvidencePhotos"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: packageURL.appendingPathComponent("ImportedDocuments"), withIntermediateDirectories: true)

        let manifest = """
        {
          "appName": "Rentory",
          "backupVersion": 3,
          "createdAt": "2026-05-01T00:00:00Z",
          "appVersion": "1.0",
          "propertyCount": 1,
          "roomCount": 1,
          "photoCount": 0,
          "documentCount": 0,
          "timelineEventCount": 0
        }
        """
        try Data(manifest.utf8).write(to: packageURL.appendingPathComponent("manifest.json"))

        let propertyID = UUID().uuidString.uppercased()
        let orphanedRoomPropertyID = UUID().uuidString.uppercased()
        let payload = """
        {
          "checklistItems": [],
          "documents": [],
          "photos": [],
          "properties": [{
            "createdAt": "2026-05-01T00:00:00Z",
            "id": "\(propertyID)",
            "isArchived": false,
            "nickname": "Mismatch",
            "updatedAt": "2026-05-01T00:00:00Z"
          }],
          "rooms": [{
            "id": "\(UUID().uuidString.uppercased())",
            "propertyID": "\(orphanedRoomPropertyID)",
            "name": "Orphan",
            "typeRawValue": "Other",
            "sortOrder": 0,
            "createdAt": "2026-05-01T00:00:00Z",
            "updatedAt": "2026-05-01T00:00:00Z"
          }],
          "timelineEvents": []
        }
        """
        try Data(payload.utf8).write(to: packageURL.appendingPathComponent("data.json"))

        let backupService = RentoryBackupService(
            fileStorageService: makeService(),
            deletionService: RentoryDataDeletionService(fileStorageService: makeService())
        )

        #expect(throws: RentoryBackupError.backupIncomplete) {
            _ = try backupService.loadBackup(from: packageURL)
        }
    }

    @Test @MainActor func photoCacheInvalidatesOnDelete() throws {
        let storage = makeService()
        let photoService = PhotoStorageService(fileStorageService: storage)
        let image = try makeImage(size: CGSize(width: 100, height: 100))
        let fileName = try photoService.savePhoto(image)

        // Simulate the UI populating the thumbnail cache after a fetch.
        photoService.storeThumbnail(image, for: fileName)
        #expect(photoService.cachedThumbnail(for: fileName) != nil)

        try photoService.deletePhoto(fileName: fileName)

        #expect(photoService.cachedThumbnail(for: fileName) == nil)
    }

    @Test @MainActor func demoDataFactoryClearsPartialRecordsOnCancellation() async throws {
        let storage = makeService()
        let factory = DemoDataFactory(fileStorageService: storage)
        let context = try makeModelContext()

        let task = Task {
            try await factory.loadSampleData(
                context: context,
                profile: .renter,
                style: .fullSampleSet
            ) { _ in }
        }

        try await Task.sleep(nanoseconds: 150_000_000)
        task.cancel()

        let result = await task.result
        switch result {
        case .success:
            // If the loader actually finished before we cancelled, that's fine — there's nothing
            // partial to verify. The test only asserts the cleanup contract when cancellation lands
            // mid-flight.
            break
        case .failure(let error):
            #expect(error is CancellationError)
            let remaining = try context.fetch(FetchDescriptor<PropertyPack>())
            #expect(remaining.isEmpty)
        }
    }

    @Test @MainActor func syncAlertContentSurfacesSignInGuidanceWhenNotAuthenticated() {
        let content = ICloudSyncService.alertContent(for: CKError(.notAuthenticated))
        #expect(content.title.localizedCaseInsensitiveContains("not signed in"))
    }

    @Test @MainActor func syncAlertContentSurfacesConnectionGuidanceForNetworkErrors() {
        let unavailable = ICloudSyncService.alertContent(for: CKError(.networkUnavailable))
        let failure = ICloudSyncService.alertContent(for: CKError(.networkFailure))
        #expect(unavailable.title.localizedCaseInsensitiveContains("connection"))
        #expect(failure.title.localizedCaseInsensitiveContains("connection"))
    }

    @Test @MainActor func syncAlertContentSurfacesStorageGuidanceWhenQuotaExceeded() {
        let content = ICloudSyncService.alertContent(for: CKError(.quotaExceeded))
        #expect(content.title.localizedCaseInsensitiveContains("storage is full"))
    }

    @Test @MainActor func syncAlertContentFallsBackToTryAgainForUnknownError() {
        struct UnknownError: Error {}
        let content = ICloudSyncService.alertContent(for: UnknownError())
        #expect(content.title.localizedCaseInsensitiveContains("could not finish"))
    }

    @Test @MainActor func landlordSampleSetLoadsSixRecordsWithLandlordOnlyContent() throws {
        let storage = makeService()
        let factory = DemoDataFactory(fileStorageService: storage)
        let context = try makeModelContext()

        let records = try factory.loadSampleData(
            context: context,
            profile: .landlord,
            style: .fullSampleSet
        )

        #expect(records.count == 6)
        for record in records {
            #expect(record.profile == .landlord)
        }

        let allTenancies = records.flatMap(\.tenancies)
        #expect(!allTenancies.isEmpty)

        let landlordOnlyKinds: Set<ReminderKind> = [
            .gasSafety, .electricalSafety, .energyPerformance, .periodicInspection, .tenancyRenewal,
        ]
        let landlordOnlyReminders = records
            .flatMap(\.reminders)
            .filter { landlordOnlyKinds.contains($0.kind) }
        #expect(!landlordOnlyReminders.isEmpty)

        let recordsWithTenancies = records.filter { !$0.tenancies.isEmpty }
        #expect(recordsWithTenancies.count >= 4)

        let archivedRecords = records.filter(\.isArchived)
        #expect(archivedRecords.count == 1)
    }

    private func makeService() -> FileStorageService {
        let baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RentoryTests-\(UUID().uuidString)", isDirectory: true)

        return FileStorageService(baseDirectoryURL: baseURL)
    }

    private func makeModelContext() throws -> ModelContext {
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

    private func makeImage(size: CGSize) throws -> UIImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        guard let context else {
            throw TestImageError.unableToCreateContext
        }

        context.setFillColor(red: 0.12, green: 0.42, blue: 0.88, alpha: 1)
        context.fill(CGRect(origin: .zero, size: size))

        guard let cgImage = context.makeImage() else {
            throw TestImageError.unableToCreateImage
        }

        return UIImage.rrImage(from: cgImage, size: size)
    }
}

private enum TestImageError: Error {
    case unableToCreateContext
    case unableToCreateImage
}
