//
//  PurchaseError.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

enum PurchaseError: LocalizedError {
    case purchaseNotCompleted
    case purchaseCouldNotBeRestored
    case purchaseCouldNotBeChecked

    var errorDescription: String? {
        switch self {
        case .purchaseNotCompleted:
            return "Purchase not completed"
        case .purchaseCouldNotBeRestored:
            return "Purchase could not be restored"
        case .purchaseCouldNotBeChecked:
            return "Rentory could not check your purchase"
        }
    }

    var recoverySuggestion: String? {
        "Please try again."
    }
}

extension UserFacingError {
    static let purchaseNotCompleted = UserFacingError(
        title: "Purchase not completed",
        message: "You have not been charged. Please try again when you are ready.",
        recoveryActionTitle: "Try again"
    )

    static let purchaseCouldNotBeRestored = UserFacingError(
        title: "Purchase could not be restored",
        message: "Please try again.",
        recoveryActionTitle: "Try again"
    )

    static let purchaseCouldNotBeChecked = UserFacingError(
        title: "Rentory could not check your purchase",
        message: "The unlock option is not available right now. Please try again in a moment.",
        recoveryActionTitle: "Try again"
    )
}
