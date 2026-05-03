//
//  RentoryTests.swift
//  RentoryTests
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation
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
        #expect(options.includeDisclaimer)
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
        var options = ExportOptions()
        options.includeDisclaimer = false

        let sections = builder.makeReportSections(for: propertyPack, options: options)
        let text = sections.flatMap(\.lines).joined(separator: "\n")

        #expect(text.contains(ReportDisclaimerView.reportText))
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
            photos: [EvidencePhoto(localFileName: photoFileName, phase: .moveIn)]
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
        #expect(importedPropertyPacks[0].documents[0].localFileName != documentFileName)
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
        ])
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
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
