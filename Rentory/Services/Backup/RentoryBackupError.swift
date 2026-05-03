//
//  RentoryBackupError.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import Foundation

enum RentoryBackupError: LocalizedError {
    case backupNotCreated
    case backupNotOpened
    case backupNotSupported
    case backupIncomplete
    case backupValidationFailed
    case backupNotImported

    var errorDescription: String? {
        switch self {
        case .backupNotCreated:
            return "Backup not created"
        case .backupNotOpened:
            return "This backup could not be opened."
        case .backupNotSupported:
            return "This backup is not supported."
        case .backupIncomplete:
            return "This backup looks incomplete."
        case .backupValidationFailed:
            return "Your current records were not changed."
        case .backupNotImported:
            return "Backup not imported"
        }
    }
}

extension UserFacingError {
    static let backupNotCreated = UserFacingError(
        title: "Backup not created",
        message: "Your backup could not be created. Please try again.",
        recoveryActionTitle: "Try again"
    )

    static let backupNotImported = UserFacingError(
        title: "Backup not imported",
        message: "This backup could not be opened.",
        recoveryActionTitle: "OK"
    )

    static let backupNotSupported = UserFacingError(
        title: "Backup not imported",
        message: "This backup is not supported.",
        recoveryActionTitle: "OK"
    )

    static let backupIncomplete = UserFacingError(
        title: "Backup not imported",
        message: "This backup looks incomplete.",
        recoveryActionTitle: "OK"
    )

    static let backupValidationFailed = UserFacingError(
        title: "Backup not imported",
        message: "Your current records were not changed.",
        recoveryActionTitle: "OK"
    )
}
