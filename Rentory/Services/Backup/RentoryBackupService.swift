//
//  RentoryBackupService.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

struct LoadedRentoryBackup: Identifiable {
    let id = UUID()
    let manifest: RentoryBackupManifest
    fileprivate let payload: RentoryBackupPayload
    fileprivate let packageURL: URL
}

enum BackupImportMode: String, CaseIterable, Identifiable {
    case addToExisting = "Add to existing records"
    case replaceAll = "Replace all Rentory data"

    var id: String { rawValue }
}

struct RentoryBackupService {
    static let backupVersion = 4
    static let supportedBackupVersions: ClosedRange<Int> = 1...4
    static let backupContentType = UTType(exportedAs: "com.fusionstudios.rentory.backup", conformingTo: .package)

    private let fileManager: FileManager
    private let fileStorageService: FileStorageService
    private let deletionService: RentoryDataDeletionService

    init(
        fileManager: FileManager = .default,
        fileStorageService: FileStorageService = FileStorageService(),
        deletionService: RentoryDataDeletionService = RentoryDataDeletionService()
    ) {
        self.fileManager = fileManager
        self.fileStorageService = fileStorageService
        self.deletionService = deletionService
    }

    func makeManifest(context: ModelContext) throws -> RentoryBackupManifest {
        let payload = try buildPayload(context: context)
        return makeManifest(for: payload)
    }

    func createBackup(context: ModelContext) throws -> URL {
        let payload = try buildPayload(context: context)
        let manifest = makeManifest(for: payload)
        let backupURL = try makeBackupPackageURL()

        do {
            try fileManager.createDirectory(at: backupURL, withIntermediateDirectories: true)

            let photosFolderURL = backupURL.appendingPathComponent("EvidencePhotos", isDirectory: true)
            let documentsFolderURL = backupURL.appendingPathComponent("ImportedDocuments", isDirectory: true)
            try fileManager.createDirectory(at: photosFolderURL, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: documentsFolderURL, withIntermediateDirectories: true)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            try encoder.encode(manifest).write(to: backupURL.appendingPathComponent("manifest.json"), options: .atomic)
            try encoder.encode(payload).write(to: backupURL.appendingPathComponent("data.json"), options: .atomic)

            for photo in payload.photos {
                let sourceURL = try fileStorageService.urlForEvidencePhoto(fileName: photo.localFileName)
                let destinationURL = photosFolderURL.appendingPathComponent(photo.backupFileName, isDirectory: false)
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
            }

            for document in payload.documents {
                let sourceURL = try fileStorageService.urlForDocument(fileName: document.localFileName)
                let destinationURL = documentsFolderURL.appendingPathComponent(document.backupFileName, isDirectory: false)
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
            }

            return backupURL
        } catch {
            try? fileManager.removeItem(at: backupURL)
            throw RentoryBackupError.backupNotCreated
        }
    }

    func loadBackup(from url: URL) throws -> LoadedRentoryBackup {
        let didAccessScopedResource = url.startAccessingSecurityScopedResource()
        defer {
            if didAccessScopedResource {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let packageURL = try validatedBackupPackageURL(from: url)
        let manifestURL = packageURL.appendingPathComponent("manifest.json", isDirectory: false)
        let dataURL = packageURL.appendingPathComponent("data.json", isDirectory: false)
        let photosFolderURL = packageURL.appendingPathComponent("EvidencePhotos", isDirectory: true)
        let documentsFolderURL = packageURL.appendingPathComponent("ImportedDocuments", isDirectory: true)

        guard fileManager.fileExists(atPath: manifestURL.path),
              fileManager.fileExists(atPath: dataURL.path) else {
            throw RentoryBackupError.backupIncomplete
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let manifest = try decoder.decode(RentoryBackupManifest.self, from: Data(contentsOf: manifestURL, options: [.mappedIfSafe]))
            guard Self.supportedBackupVersions.contains(manifest.backupVersion) else {
                throw RentoryBackupError.backupNotSupported
            }

            let payload = try decoder.decode(RentoryBackupPayload.self, from: Data(contentsOf: dataURL, options: [.mappedIfSafe]))
            try validate(payload: payload, photosFolderURL: photosFolderURL, documentsFolderURL: documentsFolderURL)
            return LoadedRentoryBackup(manifest: manifest, payload: payload, packageURL: packageURL)
        } catch let error as RentoryBackupError {
            throw error
        } catch {
            throw RentoryBackupError.backupNotOpened
        }
    }

    func importBackup(_ backup: LoadedRentoryBackup, mode: BackupImportMode, context: ModelContext) throws {
        let stagedFiles = try stageFiles(from: backup)
        let importedPropertyPacks = buildImportedPropertyPacks(from: backup.payload, stagedFiles: stagedFiles)

        do {
            if mode == .replaceAll {
                try deletionService.deleteAllData(context: context)
            }

            for propertyPack in importedPropertyPacks {
                context.insert(propertyPack)
            }

            try context.save()
        } catch {
            cleanupStagedFiles(stagedFiles)
            throw RentoryBackupError.backupNotImported
        }
    }

    private func buildPayload(context: ModelContext) throws -> RentoryBackupPayload {
        let propertyPacks = try context.fetch(FetchDescriptor<PropertyPack>())
        let sortedPropertyPacks = propertyPacks.sorted { $0.createdAt < $1.createdAt }

        var properties: [BackupPropertyPack] = []
        var rooms: [BackupRoomRecord] = []
        var checklistItems: [BackupChecklistItemRecord] = []
        var photos: [BackupEvidencePhoto] = []
        var documents: [BackupDocumentRecord] = []
        var timelineEvents: [BackupTimelineEvent] = []
        var reminders: [BackupReminder] = []
        var comments: [BackupItemComment] = []
        var tenancies: [BackupTenancy] = []
        var tenants: [BackupTenant] = []
        var rentPayments: [BackupRentPayment] = []
        var expenses: [BackupPropertyExpense] = []

        for propertyPack in sortedPropertyPacks {
            properties.append(
                BackupPropertyPack(
                    id: propertyPack.id,
                    nickname: propertyPack.nickname,
                    recordTypeRawValue: propertyPack.recordTypeRawValue,
                    profileRawValue: propertyPack.profileRawValue,
                    isFavourite: propertyPack.isFavourite,
                    addressLine1: propertyPack.addressLine1,
                    addressLine2: propertyPack.addressLine2,
                    townCity: propertyPack.townCity,
                    postcode: propertyPack.postcode,
                    buildingName: propertyPack.buildingName,
                    spaceIdentifier: propertyPack.spaceIdentifier,
                    floorLevel: propertyPack.floorLevel,
                    mainPropertyName: propertyPack.mainPropertyName,
                    accessDetails: propertyPack.accessDetails,
                    tenancyStartDate: propertyPack.tenancyStartDate,
                    tenancyEndDate: propertyPack.tenancyEndDate,
                    landlordOrAgentName: propertyPack.landlordOrAgentName,
                    landlordOrAgentEmail: propertyPack.landlordOrAgentEmail,
                    depositSchemeName: propertyPack.depositSchemeName,
                    depositReference: propertyPack.depositReference,
                    notes: propertyPack.notes,
                    manualTenancyStageRawValue: propertyPack.manualTenancyStageRawValue,
                    createdAt: propertyPack.createdAt,
                    updatedAt: propertyPack.updatedAt,
                    isArchived: propertyPack.isArchived
                )
            )

            for room in propertyPack.rooms.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                rooms.append(
                    BackupRoomRecord(
                        id: room.id,
                        propertyID: propertyPack.id,
                        name: room.name,
                        typeRawValue: room.typeRawValue,
                        notes: room.notes,
                        sortOrder: room.sortOrder,
                        createdAt: room.createdAt,
                        updatedAt: room.updatedAt,
                        manualConditionOverrideRawValue: room.manualConditionOverrideRawValue
                    )
                )

                for item in room.checklistItems.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                    checklistItems.append(
                        BackupChecklistItemRecord(
                            id: item.id,
                            roomID: room.id,
                            title: item.title,
                            category: item.category,
                            moveInConditionRawValue: item.moveInConditionRawValue,
                            moveOutConditionRawValue: item.moveOutConditionRawValue,
                            moveInNotes: item.moveInNotes,
                            moveOutNotes: item.moveOutNotes,
                            isFlagged: item.isFlagged,
                            sortOrder: item.sortOrder,
                            updatedAt: item.updatedAt
                        )
                    )

                    for comment in item.comments.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                        comments.append(
                            BackupItemComment(
                                id: comment.id,
                                checklistItemID: item.id,
                                body: comment.body,
                                createdAt: comment.createdAt,
                                evidencePhaseRawValue: comment.evidencePhaseRawValue,
                                sortOrder: comment.sortOrder
                            )
                        )
                    }

                    for photo in item.photos.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                        photos.append(
                            BackupEvidencePhoto(
                                id: photo.id,
                                checklistItemID: item.id,
                                localFileName: photo.localFileName,
                                backupFileName: backupFileName(for: photo.localFileName, prefix: "photo"),
                                caption: photo.caption,
                                evidencePhaseRawValue: photo.evidencePhaseRawValue,
                                capturedAt: photo.capturedAt,
                                includeInExport: photo.includeInExport,
                                sortOrder: photo.sortOrder
                            )
                        )
                    }
                }
            }

            for document in propertyPack.documents.sorted(by: { $0.addedAt < $1.addedAt }) {
                documents.append(
                    BackupDocumentRecord(
                        id: document.id,
                        propertyID: propertyPack.id,
                        displayName: document.displayName,
                        localFileName: document.localFileName,
                        backupFileName: backupFileName(for: document.localFileName, prefix: "document"),
                        documentTypeRawValue: document.documentTypeRawValue,
                        notes: document.notes,
                        documentDate: document.documentDate,
                        addedAt: document.addedAt,
                        includeInExport: document.includeInExport
                    )
                )
            }

            for event in propertyPack.timelineEvents.sorted(by: { $0.eventDate < $1.eventDate }) {
                timelineEvents.append(
                    BackupTimelineEvent(
                        id: event.id,
                        propertyID: propertyPack.id,
                        title: event.title,
                        eventTypeRawValue: event.eventTypeRawValue,
                        eventDate: event.eventDate,
                        notes: event.notes,
                        createdAt: event.createdAt,
                        includeInExport: event.includeInExport
                    )
                )
            }

            for reminder in propertyPack.reminders.sorted(by: { $0.createdAt < $1.createdAt }) {
                reminders.append(
                    BackupReminder(
                        id: reminder.id,
                        propertyID: propertyPack.id,
                        title: reminder.title,
                        notes: reminder.notes,
                        dueDate: reminder.dueDate,
                        completedAt: reminder.completedAt,
                        kindRawValue: reminder.kindRawValue,
                        priorityRawValue: reminder.priorityRawValue,
                        createdAt: reminder.createdAt,
                        linkedRoomID: reminder.linkedRoomID,
                        linkedChecklistItemID: reminder.linkedChecklistItemID,
                        linkedDocumentID: reminder.linkedDocumentID,
                        linkedTimelineEventID: reminder.linkedTimelineEventID
                    )
                )
            }

            for tenancy in propertyPack.tenancies.sorted(by: { $0.createdAt < $1.createdAt }) {
                tenancies.append(
                    BackupTenancy(
                        id: tenancy.id,
                        propertyID: propertyPack.id,
                        startDate: tenancy.startDate,
                        endDate: tenancy.endDate,
                        statusRawValue: tenancy.statusRawValue,
                        tenancyTypeRawValue: tenancy.tenancyTypeRawValue,
                        depositAmount: tenancy.depositAmount,
                        depositSchemeName: tenancy.depositSchemeName,
                        depositReference: tenancy.depositReference,
                        rentAmount: tenancy.rentAmount,
                        rentFrequencyRawValue: tenancy.rentFrequencyRawValue,
                        notes: tenancy.notes,
                        signedOnDate: tenancy.signedOnDate,
                        breakClauseDate: tenancy.breakClauseDate,
                        inventoryDocumentID: tenancy.inventoryDocumentID,
                        modeRawValue: tenancy.modeRawValue,
                        createdAt: tenancy.createdAt,
                        updatedAt: tenancy.updatedAt
                    )
                )

                for tenant in tenancy.tenants.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                    tenants.append(
                        BackupTenant(
                            id: tenant.id,
                            tenancyID: tenancy.id,
                            name: tenant.name,
                            email: tenant.email,
                            phone: tenant.phone,
                            sortOrder: tenant.sortOrder,
                            notes: tenant.notes,
                            createdAt: tenant.createdAt
                        )
                    )
                }

                for payment in tenancy.rentPayments.sorted(by: { $0.dueDate < $1.dueDate }) {
                    rentPayments.append(
                        BackupRentPayment(
                            id: payment.id,
                            tenancyID: tenancy.id,
                            dueDate: payment.dueDate,
                            paidDate: payment.paidDate,
                            amount: payment.amount,
                            currencyCode: payment.currencyCode,
                            statusRawValue: payment.statusRawValue,
                            notes: payment.notes,
                            createdAt: payment.createdAt,
                            updatedAt: payment.updatedAt
                        )
                    )
                }
            }

            for expense in propertyPack.expenses.sorted(by: { $0.date < $1.date }) {
                expenses.append(
                    BackupPropertyExpense(
                        id: expense.id,
                        propertyID: propertyPack.id,
                        date: expense.date,
                        title: expense.title,
                        amount: expense.amount,
                        currencyCode: expense.currencyCode,
                        categoryRawValue: expense.categoryRawValue,
                        notes: expense.notes,
                        createdAt: expense.createdAt,
                        updatedAt: expense.updatedAt
                    )
                )
            }
        }

        return RentoryBackupPayload(
            properties: properties,
            rooms: rooms,
            checklistItems: checklistItems,
            photos: photos,
            documents: documents,
            timelineEvents: timelineEvents,
            reminders: reminders,
            comments: comments,
            tenancies: tenancies,
            tenants: tenants,
            rentPayments: rentPayments,
            expenses: expenses
        )
    }

    private func makeManifest(for payload: RentoryBackupPayload) -> RentoryBackupManifest {
        RentoryBackupManifest(
            backupVersion: Self.backupVersion,
            appName: "Rentory",
            createdAt: .now,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            propertyCount: payload.properties.count,
            roomCount: payload.rooms.count,
            photoCount: payload.photos.count,
            documentCount: payload.documents.count,
            timelineEventCount: payload.timelineEvents.count,
            reminderCount: payload.reminderList.count,
            commentCount: payload.commentList.count,
            tenancyCount: payload.tenancyList.count,
            tenantCount: payload.tenantList.count,
            rentPaymentCount: payload.rentPaymentList.count,
            expenseCount: payload.expenseList.count
        )
    }

    private func makeBackupPackageURL() throws -> URL {
        let backupFolderURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RentoryBackups", isDirectory: true)

        do {
            try fileManager.createDirectory(at: backupFolderURL, withIntermediateDirectories: true)
        } catch {
            throw RentoryBackupError.backupNotCreated
        }

        return backupFolderURL.appendingPathComponent("rentory-backup-\(UUID().uuidString.lowercased()).rentorybackup", isDirectory: true)
    }

    private func validatedBackupPackageURL(from url: URL) throws -> URL {
        let standardisedURL = url.standardizedFileURL

        guard standardisedURL.pathExtension == "rentorybackup" else {
            throw RentoryBackupError.backupNotSupported
        }

        guard !standardisedURL.path.contains("/../") else {
            throw RentoryBackupError.backupValidationFailed
        }

        return standardisedURL
    }

    private func validate(payload: RentoryBackupPayload, photosFolderURL: URL, documentsFolderURL: URL) throws {
        let propertyIDs = Set(payload.properties.map(\.id))
        let roomIDs = Set(payload.rooms.map(\.id))
        let checklistItemIDs = Set(payload.checklistItems.map(\.id))
        let tenancyIDs = Set(payload.tenancyList.map(\.id))

        guard payload.rooms.allSatisfy({ propertyIDs.contains($0.propertyID) }),
              payload.documents.allSatisfy({ propertyIDs.contains($0.propertyID) }),
              payload.timelineEvents.allSatisfy({ propertyIDs.contains($0.propertyID) }),
              payload.reminderList.allSatisfy({ propertyIDs.contains($0.propertyID) }),
              payload.tenancyList.allSatisfy({ propertyIDs.contains($0.propertyID) }),
              payload.tenantList.allSatisfy({ tenancyIDs.contains($0.tenancyID) }),
              payload.checklistItems.allSatisfy({ roomIDs.contains($0.roomID) }),
              payload.photos.allSatisfy({ checklistItemIDs.contains($0.checklistItemID) }),
              payload.commentList.allSatisfy({ checklistItemIDs.contains($0.checklistItemID) }) else {
            throw RentoryBackupError.backupIncomplete
        }

        for photo in payload.photos {
            _ = try validatedBackupFileName(photo.backupFileName)
            let fileURL = photosFolderURL.appendingPathComponent(photo.backupFileName, isDirectory: false)
            guard fileManager.fileExists(atPath: fileURL.path) else {
                throw RentoryBackupError.backupIncomplete
            }
        }

        for document in payload.documents {
            _ = try validatedBackupFileName(document.backupFileName)
            let fileURL = documentsFolderURL.appendingPathComponent(document.backupFileName, isDirectory: false)
            guard fileManager.fileExists(atPath: fileURL.path) else {
                throw RentoryBackupError.backupIncomplete
            }
        }
    }

    private func backupFileName(for localFileName: String, prefix: String) -> String {
        let fileExtension = URL(fileURLWithPath: localFileName).pathExtension.lowercased()
        return "\(prefix)-\(UUID().uuidString.lowercased()).\(fileExtension)"
    }

    private func validatedBackupFileName(_ fileName: String) throws -> String {
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !trimmed.contains("/"),
              !trimmed.contains(".."),
              !trimmed.hasPrefix("/") else {
            throw RentoryBackupError.backupValidationFailed
        }
        return trimmed
    }

    private func stageFiles(from backup: LoadedRentoryBackup) throws -> StagedFiles {
        let photosFolderURL = backup.packageURL.appendingPathComponent("EvidencePhotos", isDirectory: true)
        let documentsFolderURL = backup.packageURL.appendingPathComponent("ImportedDocuments", isDirectory: true)

        var importedPhotoNames: [UUID: String] = [:]
        var importedDocumentNames: [UUID: String] = [:]
        var stagedPhotoFileNames: [String] = []
        var stagedDocumentFileNames: [String] = []

        do {
            for photo in backup.payload.photos {
                let fileName = try validatedBackupFileName(photo.backupFileName)
                let fileURL = photosFolderURL.appendingPathComponent(fileName, isDirectory: false)
                let data = try Data(contentsOf: fileURL, options: [.mappedIfSafe])
                let fileExtension = URL(fileURLWithPath: fileName).pathExtension
                let newLocalFileName = try fileStorageService.saveImageData(data, fileExtension: fileExtension)
                importedPhotoNames[photo.id] = newLocalFileName
                stagedPhotoFileNames.append(newLocalFileName)
            }

            for document in backup.payload.documents {
                let fileName = try validatedBackupFileName(document.backupFileName)
                let fileURL = documentsFolderURL.appendingPathComponent(fileName, isDirectory: false)
                let data = try Data(contentsOf: fileURL, options: [.mappedIfSafe])
                let fileExtension = URL(fileURLWithPath: fileName).pathExtension
                let newLocalFileName = try fileStorageService.saveDocumentData(data, fileExtension: fileExtension)
                importedDocumentNames[document.id] = newLocalFileName
                stagedDocumentFileNames.append(newLocalFileName)
            }

            return StagedFiles(
                photoFileNamesByID: importedPhotoNames,
                documentFileNamesByID: importedDocumentNames,
                stagedPhotoFileNames: stagedPhotoFileNames,
                stagedDocumentFileNames: stagedDocumentFileNames
            )
        } catch let error as RentoryBackupError {
            cleanupStagedFiles(
                StagedFiles(
                    photoFileNamesByID: importedPhotoNames,
                    documentFileNamesByID: importedDocumentNames,
                    stagedPhotoFileNames: stagedPhotoFileNames,
                    stagedDocumentFileNames: stagedDocumentFileNames
                )
            )
            throw error
        } catch {
            cleanupStagedFiles(
                StagedFiles(
                    photoFileNamesByID: importedPhotoNames,
                    documentFileNamesByID: importedDocumentNames,
                    stagedPhotoFileNames: stagedPhotoFileNames,
                    stagedDocumentFileNames: stagedDocumentFileNames
                )
            )
            throw RentoryBackupError.backupNotImported
        }
    }

    private func cleanupStagedFiles(_ stagedFiles: StagedFiles) {
        for fileName in stagedFiles.stagedPhotoFileNames {
            try? fileStorageService.deleteEvidencePhoto(fileName: fileName)
        }

        for fileName in stagedFiles.stagedDocumentFileNames {
            try? fileStorageService.deleteDocument(fileName: fileName)
        }
    }

    private func buildImportedPropertyPacks(from payload: RentoryBackupPayload, stagedFiles: StagedFiles) -> [PropertyPack] {
        var propertyPacksByID: [UUID: PropertyPack] = [:]
        var roomsByID: [UUID: RoomRecord] = [:]
        var checklistItemsByID: [UUID: ChecklistItemRecord] = [:]

        for property in payload.properties {
            propertyPacksByID[property.id] = PropertyPack(
                nickname: property.nickname,
                recordType: property.recordTypeRawValue.flatMap(PropertyRecordType.init(rawValue:)) ?? .house,
                profile: property.profileRawValue.flatMap(RentoryUserProfile.init(rawValue:)) ?? .renter,
                isFavourite: property.isFavourite ?? false,
                addressLine1: property.addressLine1,
                addressLine2: property.addressLine2,
                townCity: property.townCity,
                postcode: property.postcode,
                buildingName: property.buildingName,
                spaceIdentifier: property.spaceIdentifier,
                floorLevel: property.floorLevel,
                mainPropertyName: property.mainPropertyName,
                accessDetails: property.accessDetails,
                tenancyStartDate: property.tenancyStartDate,
                tenancyEndDate: property.tenancyEndDate,
                landlordOrAgentName: property.landlordOrAgentName,
                landlordOrAgentEmail: property.landlordOrAgentEmail,
                depositSchemeName: property.depositSchemeName,
                depositReference: property.depositReference,
                notes: property.notes,
                manualTenancyStageRawValue: property.manualTenancyStageRawValue,
                createdAt: property.createdAt,
                updatedAt: property.updatedAt,
                isArchived: property.isArchived
            )
        }

        for room in payload.rooms.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let importedRoom = RoomRecord(
                name: room.name,
                type: RoomType(rawValue: room.typeRawValue) ?? .other,
                sortOrder: room.sortOrder,
                notes: room.notes,
                manualConditionOverride: room.manualConditionOverrideRawValue
                    .flatMap(EvidenceCondition.init(rawValue:)),
                createdAt: room.createdAt,
                updatedAt: room.updatedAt
            )
            roomsByID[room.id] = importedRoom
            propertyPacksByID[room.propertyID]?.rooms.append(importedRoom)
        }

        for checklistItem in payload.checklistItems.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let importedItem = ChecklistItemRecord(
                title: checklistItem.title,
                sortOrder: checklistItem.sortOrder,
                category: checklistItem.category,
                moveInConditionRawValue: checklistItem.moveInConditionRawValue,
                moveOutConditionRawValue: checklistItem.moveOutConditionRawValue,
                moveInNotes: checklistItem.moveInNotes,
                moveOutNotes: checklistItem.moveOutNotes,
                isFlagged: checklistItem.isFlagged,
                updatedAt: checklistItem.updatedAt
            )
            checklistItemsByID[checklistItem.id] = importedItem
            roomsByID[checklistItem.roomID]?.checklistItems.append(importedItem)
        }

        for comment in payload.commentList.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let importedComment = ItemComment(
                body: comment.body,
                phase: comment.evidencePhaseRawValue.flatMap(EvidencePhase.init(rawValue:)),
                createdAt: comment.createdAt,
                sortOrder: comment.sortOrder
            )
            checklistItemsByID[comment.checklistItemID]?.comments.append(importedComment)
        }

        for photo in payload.photos.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            guard let localFileName = stagedFiles.photoFileNamesByID[photo.id] else {
                continue
            }

            let importedPhoto = EvidencePhoto(
                localFileName: localFileName,
                phase: EvidencePhase(rawValue: photo.evidencePhaseRawValue) ?? .duringTenancy,
                caption: photo.caption,
                capturedAt: photo.capturedAt,
                includeInExport: photo.includeInExport,
                sortOrder: photo.sortOrder
            )
            checklistItemsByID[photo.checklistItemID]?.photos.append(importedPhoto)
        }

        for document in payload.documents {
            guard let localFileName = stagedFiles.documentFileNamesByID[document.id] else {
                continue
            }

            let importedDocument = DocumentRecord(
                displayName: document.displayName,
                type: DocumentType(rawValue: document.documentTypeRawValue) ?? .other,
                localFileName: localFileName,
                notes: document.notes,
                documentDate: document.documentDate,
                addedAt: document.addedAt,
                includeInExport: document.includeInExport
            )
            propertyPacksByID[document.propertyID]?.documents.append(importedDocument)
        }

        for event in payload.timelineEvents {
            let importedEvent = TimelineEvent(
                title: event.title,
                type: TimelineEventType(rawValue: event.eventTypeRawValue) ?? .other,
                eventDate: event.eventDate,
                notes: event.notes,
                createdAt: event.createdAt,
                includeInExport: event.includeInExport
            )
            propertyPacksByID[event.propertyID]?.timelineEvents.append(importedEvent)
        }

        for reminder in payload.reminderList {
            let importedReminder = Reminder(
                title: reminder.title,
                notes: reminder.notes,
                dueDate: reminder.dueDate,
                completedAt: reminder.completedAt,
                kind: ReminderKind(rawValue: reminder.kindRawValue) ?? .custom,
                priority: ReminderPriority(rawValue: reminder.priorityRawValue) ?? .normal,
                createdAt: reminder.createdAt,
                linkedRoomID: reminder.linkedRoomID,
                linkedChecklistItemID: reminder.linkedChecklistItemID,
                linkedDocumentID: reminder.linkedDocumentID,
                linkedTimelineEventID: reminder.linkedTimelineEventID
            )
            propertyPacksByID[reminder.propertyID]?.reminders.append(importedReminder)
        }

        var tenanciesByID: [UUID: Tenancy] = [:]
        for tenancy in payload.tenancyList.sorted(by: { $0.createdAt < $1.createdAt }) {
            let importedTenancy = Tenancy(
                startDate: tenancy.startDate,
                endDate: tenancy.endDate,
                status: TenancyStatus(rawValue: tenancy.statusRawValue) ?? .upcoming,
                tenancyType: TenancyType(rawValue: tenancy.tenancyTypeRawValue) ?? .assuredShorthold,
                depositAmount: tenancy.depositAmount,
                depositSchemeName: tenancy.depositSchemeName,
                depositReference: tenancy.depositReference,
                rentAmount: tenancy.rentAmount,
                rentFrequency: tenancy.rentFrequencyRawValue.flatMap(RentFrequency.init(rawValue:)),
                notes: tenancy.notes,
                signedOnDate: tenancy.signedOnDate,
                breakClauseDate: tenancy.breakClauseDate,
                inventoryDocumentID: tenancy.inventoryDocumentID,
                mode: TenancyMode(rawValue: tenancy.modeRawValue) ?? .standard,
                createdAt: tenancy.createdAt,
                updatedAt: tenancy.updatedAt
            )
            tenanciesByID[tenancy.id] = importedTenancy
            propertyPacksByID[tenancy.propertyID]?.tenancies.append(importedTenancy)
        }

        for tenant in payload.tenantList.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let importedTenant = Tenant(
                name: tenant.name,
                email: tenant.email,
                phone: tenant.phone,
                sortOrder: tenant.sortOrder,
                notes: tenant.notes,
                createdAt: tenant.createdAt
            )
            tenanciesByID[tenant.tenancyID]?.tenants.append(importedTenant)
        }

        for payment in payload.rentPaymentList.sorted(by: { $0.dueDate < $1.dueDate }) {
            let importedPayment = RentPayment(
                dueDate: payment.dueDate,
                paidDate: payment.paidDate,
                amount: payment.amount,
                currencyCode: payment.currencyCode,
                status: RentPaymentStatus(rawValue: payment.statusRawValue) ?? .pending,
                notes: payment.notes,
                createdAt: payment.createdAt,
                updatedAt: payment.updatedAt
            )
            tenanciesByID[payment.tenancyID]?.rentPayments.append(importedPayment)
        }

        for expense in payload.expenseList.sorted(by: { $0.date < $1.date }) {
            let importedExpense = PropertyExpense(
                date: expense.date,
                title: expense.title,
                amount: expense.amount,
                currencyCode: expense.currencyCode,
                category: ExpenseCategory(rawValue: expense.categoryRawValue) ?? .other,
                notes: expense.notes,
                createdAt: expense.createdAt,
                updatedAt: expense.updatedAt
            )
            propertyPacksByID[expense.propertyID]?.expenses.append(importedExpense)
        }

        return payload.properties.compactMap { propertyPacksByID[$0.id] }
    }
}

private struct StagedFiles {
    let photoFileNamesByID: [UUID: String]
    let documentFileNamesByID: [UUID: String]
    let stagedPhotoFileNames: [String]
    let stagedDocumentFileNames: [String]
}

private struct RentoryBackupPayload: Codable {
    let properties: [BackupPropertyPack]
    let rooms: [BackupRoomRecord]
    let checklistItems: [BackupChecklistItemRecord]
    let photos: [BackupEvidencePhoto]
    let documents: [BackupDocumentRecord]
    let timelineEvents: [BackupTimelineEvent]
    let reminders: [BackupReminder]?
    let comments: [BackupItemComment]?
    let tenancies: [BackupTenancy]?
    let tenants: [BackupTenant]?
    let rentPayments: [BackupRentPayment]?
    let expenses: [BackupPropertyExpense]?

    var reminderList: [BackupReminder] { reminders ?? [] }
    var commentList: [BackupItemComment] { comments ?? [] }
    var tenancyList: [BackupTenancy] { tenancies ?? [] }
    var tenantList: [BackupTenant] { tenants ?? [] }
    var rentPaymentList: [BackupRentPayment] { rentPayments ?? [] }
    var expenseList: [BackupPropertyExpense] { expenses ?? [] }
}

private struct BackupPropertyPack: Codable {
    let id: UUID
    let nickname: String
    let recordTypeRawValue: String?
    let profileRawValue: String?
    let isFavourite: Bool?
    let addressLine1: String?
    let addressLine2: String?
    let townCity: String?
    let postcode: String?
    let buildingName: String?
    let spaceIdentifier: String?
    let floorLevel: String?
    let mainPropertyName: String?
    let accessDetails: String?
    let tenancyStartDate: Date?
    let tenancyEndDate: Date?
    let landlordOrAgentName: String?
    let landlordOrAgentEmail: String?
    let depositSchemeName: String?
    let depositReference: String?
    let notes: String?
    let manualTenancyStageRawValue: String?
    let createdAt: Date
    let updatedAt: Date
    let isArchived: Bool
}

private struct BackupRoomRecord: Codable {
    let id: UUID
    let propertyID: UUID
    let name: String
    let typeRawValue: String
    let notes: String?
    let sortOrder: Int
    let createdAt: Date
    let updatedAt: Date
    let manualConditionOverrideRawValue: String?
}

private struct BackupChecklistItemRecord: Codable {
    let id: UUID
    let roomID: UUID
    let title: String
    let category: String?
    let moveInConditionRawValue: String
    let moveOutConditionRawValue: String
    let moveInNotes: String?
    let moveOutNotes: String?
    let isFlagged: Bool
    let sortOrder: Int
    let updatedAt: Date
}

private struct BackupEvidencePhoto: Codable {
    let id: UUID
    let checklistItemID: UUID
    let localFileName: String
    let backupFileName: String
    let caption: String?
    let evidencePhaseRawValue: String
    let capturedAt: Date
    let includeInExport: Bool
    let sortOrder: Int
}

private struct BackupDocumentRecord: Codable {
    let id: UUID
    let propertyID: UUID
    let displayName: String
    let localFileName: String
    let backupFileName: String
    let documentTypeRawValue: String
    let notes: String?
    let documentDate: Date?
    let addedAt: Date
    let includeInExport: Bool
}

private struct BackupTimelineEvent: Codable {
    let id: UUID
    let propertyID: UUID
    let title: String
    let eventTypeRawValue: String
    let eventDate: Date
    let notes: String?
    let createdAt: Date
    let includeInExport: Bool
}

private struct BackupItemComment: Codable {
    let id: UUID
    let checklistItemID: UUID
    let body: String
    let createdAt: Date
    let evidencePhaseRawValue: String?
    let sortOrder: Int
}

private struct BackupTenancy: Codable {
    let id: UUID
    let propertyID: UUID
    let startDate: Date
    let endDate: Date?
    let statusRawValue: String
    let tenancyTypeRawValue: String
    let depositAmount: Double?
    let depositSchemeName: String?
    let depositReference: String?
    let rentAmount: Double?
    let rentFrequencyRawValue: String?
    let notes: String?
    let signedOnDate: Date?
    let breakClauseDate: Date?
    let inventoryDocumentID: UUID?
    let modeRawValue: String
    let createdAt: Date
    let updatedAt: Date
}

private struct BackupTenant: Codable {
    let id: UUID
    let tenancyID: UUID
    let name: String
    let email: String?
    let phone: String?
    let sortOrder: Int
    let notes: String?
    let createdAt: Date
}

private struct BackupReminder: Codable {
    let id: UUID
    let propertyID: UUID
    let title: String
    let notes: String?
    let dueDate: Date?
    let completedAt: Date?
    let kindRawValue: String
    let priorityRawValue: String
    let createdAt: Date
    let linkedRoomID: UUID?
    let linkedChecklistItemID: UUID?
    let linkedDocumentID: UUID?
    let linkedTimelineEventID: UUID?
}

private struct BackupRentPayment: Codable {
    let id: UUID
    let tenancyID: UUID
    let dueDate: Date
    let paidDate: Date?
    let amount: Double
    let currencyCode: String
    let statusRawValue: String
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}

private struct BackupPropertyExpense: Codable {
    let id: UUID
    let propertyID: UUID
    let date: Date
    let title: String
    let amount: Double
    let currencyCode: String
    let categoryRawValue: String
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}
