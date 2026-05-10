//
//  iCloudSyncStatusService.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import CloudKit
import Combine
import Foundation
import SwiftData

struct ICloudSyncStatusService {
    private let fileManagerProvider: @Sendable () -> FileManager

    init(fileManagerProvider: @escaping @Sendable () -> FileManager = { FileManager.default }) {
        self.fileManagerProvider = fileManagerProvider
    }

    func currentStatus() -> SyncStatus {
        let fileManager = fileManagerProvider()

        guard fileManager.ubiquityIdentityToken != nil else {
            return .unavailable
        }

        return .available
    }

    func checkStatus() async -> SyncStatus {
        let fileManager = fileManagerProvider()

        guard fileManager.ubiquityIdentityToken != nil else {
            return .unavailable
        }

        do {
            switch try await CKContainer.default().accountStatus() {
            case .available:
                return .available
            case .noAccount, .restricted:
                return .unavailable
            case .couldNotDetermine, .temporarilyUnavailable:
                return .unknown
            @unknown default:
                return .unknown
            }
        } catch {
            return .unknown
        }
    }
}

@MainActor
final class ICloudSyncService: ObservableObject {
    @Published private(set) var syncStatus: SyncStatus = .checking
    @Published private(set) var isSyncEnabled: Bool
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published var alertContent: RRAlertContent?

    private let statusService: ICloudSyncStatusService
    private let backupService: RentoryBackupService
    private let database: CKDatabase
    private let userDefaults: UserDefaults
    private let fileManager: FileManager

    private let isEnabledKey = "isICloudSyncEnabled"
    private let lastSyncDateKey = "lastICloudSyncDate"
    private let recordType = "RentorySyncSnapshot"
    private let recordName = "primary"

    init(
        statusService: ICloudSyncStatusService? = nil,
        backupService: RentoryBackupService? = nil,
        container: CKContainer = .default(),
        userDefaults: UserDefaults = .standard,
        fileManager: FileManager = .default
    ) {
        self.statusService = statusService ?? ICloudSyncStatusService()
        self.backupService = backupService ?? RentoryBackupService()
        self.database = container.privateCloudDatabase
        self.userDefaults = userDefaults
        self.fileManager = fileManager
        self.isSyncEnabled = userDefaults.bool(forKey: isEnabledKey)
        self.lastSyncDate = userDefaults.object(forKey: lastSyncDateKey) as? Date
    }

    func refreshStatus() async {
        syncStatus = .checking
        syncStatus = await statusService.checkStatus()
    }

    func setSyncEnabled(_ isEnabled: Bool, context: ModelContext) async {
        if isEnabled == isSyncEnabled {
            return
        }

        if isEnabled {
            guard syncStatus == .available else {
                alertContent = RRAlertContent(
                    title: "iCloud is not available",
                    message: "Sign in to iCloud and turn on iCloud Drive before you turn on sync."
                )
                return
            }

            userDefaults.set(true, forKey: isEnabledKey)
            isSyncEnabled = true
            await syncOnEnable(context: context)
        } else {
            userDefaults.set(false, forKey: isEnabledKey)
            isSyncEnabled = false
            alertContent = RRAlertContent(
                title: "iCloud sync turned off",
                message: "Rentory will keep the records already on this device and stop syncing new changes through iCloud."
            )
        }
    }

    func syncNow(context: ModelContext) async {
        guard isSyncEnabled else { return }
        await performSync(context: context, reason: .manual)
    }

    func syncIfNeededForSceneActive(context: ModelContext) async {
        guard isSyncEnabled else { return }
        await performSync(context: context, reason: .sceneActive)
    }

    func syncBeforeBackground(context: ModelContext) async {
        guard isSyncEnabled else { return }

        do {
            try await uploadLocalSnapshot(context: context)
        } catch {
            return
        }
    }

    private func syncOnEnable(context: ModelContext) async {
        let localRecordCount = (try? context.fetchCount(FetchDescriptor<PropertyPack>())) ?? 0

        do {
            if let remoteRecord = try await fetchRemoteRecord() {
                if localRecordCount == 0 {
                    try await importRemoteRecord(remoteRecord, context: context)
                    alertContent = RRAlertContent(
                        title: "iCloud sync turned on",
                        message: "Rentory has brought your records in from iCloud."
                    )
                } else {
                    let assetURL = try createSnapshotAsset(context: context)
                    let savedRecord = try await saveSnapshotRecord(makeSnapshotRecord(from: assetURL, existingRecord: remoteRecord))
                    finishSuccessfulSync(at: savedRecord.modificationDate ?? .now)
                    try? fileManager.removeItem(at: assetURL)
                    alertContent = RRAlertContent(
                        title: "iCloud sync turned on",
                        message: "Rentory is now keeping this device in step with your private iCloud account."
                    )
                }
            } else {
                try await uploadLocalSnapshot(context: context)
                alertContent = RRAlertContent(
                    title: "iCloud sync turned on",
                    message: "Rentory is now keeping this device in step with your private iCloud account."
                )
            }
        } catch {
            userDefaults.set(true, forKey: isEnabledKey)
            isSyncEnabled = true
            alertContent = RRAlertContent(
                title: "iCloud sync is on",
                message: "Rentory will keep trying to sync. The first sync could not finish just now, so please check your connection and try Sync now again in a moment."
            )
        }
    }

    private func performSync(context: ModelContext, reason: SyncReason) async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            if let remoteRecord = try await fetchRemoteRecord(), shouldImport(remoteRecord: remoteRecord, context: context) {
                try await importRemoteRecord(remoteRecord, context: context)
            } else {
                try await uploadLocalSnapshot(context: context)
            }

            if reason == .manual {
                alertContent = RRAlertContent(
                    title: "iCloud sync complete",
                    message: "Rentory has checked iCloud and updated this device."
                )
            }
        } catch {
            if reason == .manual {
                alertContent = RRAlertContent(
                    title: "iCloud sync could not finish",
                    message: "Rentory could not update from iCloud just now. Please try again."
                )
            }
        }
    }

    private func shouldImport(remoteRecord: CKRecord, context: ModelContext) -> Bool {
        let localCount = (try? context.fetchCount(FetchDescriptor<PropertyPack>())) ?? 0

        guard let remoteDate = remoteRecord.modificationDate else {
            return localCount == 0
        }

        guard let lastSyncDate else {
            return localCount == 0
        }

        return remoteDate > lastSyncDate
    }

    private func uploadLocalSnapshot(context: ModelContext) async throws {
        let assetURL = try createSnapshotAsset(context: context)
        let existingRecord = try await fetchRemoteRecord()
        let savedRecord = try await saveSnapshotRecord(makeSnapshotRecord(from: assetURL, existingRecord: existingRecord))
        finishSuccessfulSync(at: savedRecord.modificationDate ?? .now)
        try? fileManager.removeItem(at: assetURL)
    }

    private func importRemoteRecord(_ record: CKRecord, context: ModelContext) async throws {
        guard let asset = record["snapshot"] as? CKAsset, let fileURL = asset.fileURL else {
            throw ICloudSyncError.remoteSnapshotMissing
        }

        let snapshotData = try Data(contentsOf: fileURL, options: [.mappedIfSafe])
        let snapshot = try JSONDecoder().decode(ICloudSyncSnapshot.self, from: snapshotData)
        let packageURL = try writeSnapshotPackage(snapshot)
        let loadedBackup = try backupService.loadBackup(from: packageURL)
        try backupService.importBackup(loadedBackup, mode: .replaceAll, context: context)
        finishSuccessfulSync(at: record.modificationDate ?? .now)
        try? fileManager.removeItem(at: packageURL)
    }

    private func createSnapshotAsset(context: ModelContext) throws -> URL {
        let backupURL = try backupService.createBackup(context: context)
        defer { try? fileManager.removeItem(at: backupURL) }

        let snapshot = try makeSnapshot(from: backupURL)
        let destinationURL = fileManager.temporaryDirectory
            .appendingPathComponent("rentory-sync-\(UUID().uuidString.lowercased())", isDirectory: false)
            .appendingPathExtension("json")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(snapshot).write(to: destinationURL, options: .atomic)
        return destinationURL
    }

    private func makeSnapshot(from packageURL: URL) throws -> ICloudSyncSnapshot {
        let manifestURL = packageURL.appendingPathComponent("manifest.json", isDirectory: false)
        let dataURL = packageURL.appendingPathComponent("data.json", isDirectory: false)
        let photosFolderURL = packageURL.appendingPathComponent("EvidencePhotos", isDirectory: true)
        let documentsFolderURL = packageURL.appendingPathComponent("ImportedDocuments", isDirectory: true)

        let manifestData = try Data(contentsOf: manifestURL, options: [.mappedIfSafe])
        let payloadData = try Data(contentsOf: dataURL, options: [.mappedIfSafe])

        return ICloudSyncSnapshot(
            manifestData: manifestData,
            payloadData: payloadData,
            photos: try loadFiles(in: photosFolderURL),
            documents: try loadFiles(in: documentsFolderURL)
        )
    }

    private func loadFiles(in folderURL: URL) throws -> [String: Data] {
        guard fileManager.fileExists(atPath: folderURL.path) else {
            return [:]
        }

        let files = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        var loadedFiles: [String: Data] = [:]

        for fileURL in files {
            loadedFiles[fileURL.lastPathComponent] = try Data(contentsOf: fileURL, options: [.mappedIfSafe])
        }

        return loadedFiles
    }

    private func writeSnapshotPackage(_ snapshot: ICloudSyncSnapshot) throws -> URL {
        let packageURL = fileManager.temporaryDirectory
            .appendingPathComponent("rentory-sync-import-\(UUID().uuidString.lowercased()).rentorybackup", isDirectory: true)
        let photosFolderURL = packageURL.appendingPathComponent("EvidencePhotos", isDirectory: true)
        let documentsFolderURL = packageURL.appendingPathComponent("ImportedDocuments", isDirectory: true)

        try fileManager.createDirectory(at: photosFolderURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: documentsFolderURL, withIntermediateDirectories: true)
        try snapshot.manifestData.write(to: packageURL.appendingPathComponent("manifest.json"), options: .atomic)
        try snapshot.payloadData.write(to: packageURL.appendingPathComponent("data.json"), options: .atomic)

        for (fileName, data) in snapshot.photos {
            try data.write(to: photosFolderURL.appendingPathComponent(fileName), options: .atomic)
        }

        for (fileName, data) in snapshot.documents {
            try data.write(to: documentsFolderURL.appendingPathComponent(fileName), options: .atomic)
        }

        return packageURL
    }

    private func makeSnapshotRecord(from assetURL: URL, existingRecord: CKRecord?) -> CKRecord {
        let record = existingRecord ?? CKRecord(recordType: recordType, recordID: CKRecord.ID(recordName: recordName))
        record["snapshot"] = CKAsset(fileURL: assetURL)
        record["updatedAt"] = Date()
        return record
    }

    private func fetchRemoteRecord() async throws -> CKRecord? {
        do {
            return try await database.record(for: CKRecord.ID(recordName: recordName))
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    private func saveSnapshotRecord(_ record: CKRecord) async throws -> CKRecord {
        try await database.save(record)
    }

    private func finishSuccessfulSync(at date: Date) {
        lastSyncDate = date
        userDefaults.set(date, forKey: lastSyncDateKey)
    }
}

private struct ICloudSyncSnapshot: Codable {
    let manifestData: Data
    let payloadData: Data
    let photos: [String: Data]
    let documents: [String: Data]
}

private enum SyncReason {
    case manual
    case sceneActive
}

private enum ICloudSyncError: Error {
    case remoteSnapshotMissing
}
