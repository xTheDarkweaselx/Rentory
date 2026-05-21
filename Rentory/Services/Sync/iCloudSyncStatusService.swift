//
//  iCloudSyncStatusService.swift
//  Rentory
//
//  Cheap availability checker for the user's iCloud account. The
//  full orchestrator (sign in / disable, upload + import, conflict
//  resolution, alerts) lives in ICloudSyncService.swift — this file
//  intentionally stays small so the "is iCloud usable right now?"
//  question has an obvious place to live.
//

import CloudKit
import Foundation

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
