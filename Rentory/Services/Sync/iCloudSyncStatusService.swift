//
//  iCloudSyncStatusService.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

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

        return fileManager.url(forUbiquityContainerIdentifier: nil) == nil ? .unknown : .available
    }
}
