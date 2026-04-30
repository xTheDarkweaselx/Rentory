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
        title: "Rentory not unlocked",
        message: "Rentory could not be unlocked. Please try again when you are ready.",
        recoveryActionTitle: "Try again"
    )

    static let somethingWentWrong = UserFacingError(
        title: "Something went wrong",
        message: "Please try again.",
        recoveryActionTitle: "OK"
    )
}
