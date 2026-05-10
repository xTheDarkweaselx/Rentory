//
//  UserFacingError.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

struct UserFacingError: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let recoveryActionTitle: String?
    let technicalContext: String?

    init(
        title: String,
        message: String,
        recoveryActionTitle: String? = nil,
        technicalContext: String? = nil
    ) {
        self.title = title
        self.message = message
        self.recoveryActionTitle = recoveryActionTitle
        self.technicalContext = technicalContext
    }
}

extension UserFacingError {
    static let photoCouldNotBeAdded = UserFacingError(
        title: "Photo not added",
        message: "This photo could not be added. Please try again.",
        recoveryActionTitle: "Try again"
    )

    static let photoCouldNotBeOpened = UserFacingError(
        title: "Photo not opened",
        message: "This photo could not be opened here.",
        recoveryActionTitle: "OK"
    )

    static let photoCouldNotBeDeleted = UserFacingError(
        title: "Photo not deleted",
        message: "This photo could not be deleted. Please try again.",
        recoveryActionTitle: "Try again"
    )

    static let documentCouldNotBeAdded = UserFacingError(
        title: "Document not added",
        message: "This document could not be added. Please try again.",
        recoveryActionTitle: "Try again"
    )

    static let fileTypeNotSupported = UserFacingError(
        title: "File not added",
        message: "This file type is not supported yet.",
        recoveryActionTitle: "OK"
    )

    static let documentCouldNotBeOpened = UserFacingError(
        title: "Document not opened",
        message: "This document could not be opened here.",
        recoveryActionTitle: "OK"
    )

    static let documentCouldNotBeDeleted = UserFacingError(
        title: "Document not deleted",
        message: "This document could not be deleted. Please try again.",
        recoveryActionTitle: "Try again"
    )

    static let reportCouldNotBeCreated = UserFacingError(
        title: "Report not created",
        message: "Your report could not be created. Please try again.",
        recoveryActionTitle: "Try again"
    )

    static let reportCreated = UserFacingError(
        title: "Report ready",
        message: "Your report has been created on this device.",
        recoveryActionTitle: "Share report"
    )

    static let reportCouldNotBeSaved = UserFacingError(
        title: "Report not saved",
        message: "Rentory could not save a copy of this report. Please try again.",
        recoveryActionTitle: "Try again"
    )

    static let recordCouldNotBeSaved = UserFacingError(
        title: "Record not saved",
        message: "Your changes could not be saved. Please try again.",
        recoveryActionTitle: "Try again"
    )

    static let recordCouldNotBeDeleted = UserFacingError(
        title: "Record not deleted",
        message: "This record could not be deleted. Please try again.",
        recoveryActionTitle: "Try again"
    )

    static let temporaryReportsCouldNotBeCleared = UserFacingError(
        title: "Temporary reports not cleared",
        message: "Temporary reports could not be cleared. Please try again.",
        recoveryActionTitle: "Try again"
    )

    static let appCouldNotBeUnlocked = UserFacingError(
        title: "Rentory could not be unlocked",
        message: "Try again when you are ready.",
        recoveryActionTitle: "Try again"
    )

    static let appLockNotAvailable = UserFacingError(
        title: "App Lock is not available",
        message: "You can still use Rentory, but this device does not currently support Face ID, Touch ID or passcode unlock for the app.",
        recoveryActionTitle: "OK"
    )

    static let purchaseRestored = UserFacingError(
        title: "Purchase restored",
        message: "Your lifetime unlock is ready to use on this device.",
        recoveryActionTitle: "OK"
    )

    static let purchaseCancelled = UserFacingError(
        title: "Purchase cancelled",
        message: "No problem. You can unlock Rentory whenever you are ready.",
        recoveryActionTitle: "OK"
    )

    static let somethingWentWrong = UserFacingError(
        title: "Something went wrong",
        message: "Please try again.",
        recoveryActionTitle: "OK"
    )
}
