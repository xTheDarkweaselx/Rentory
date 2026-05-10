//
//  DialogCopy.swift
//  Rentory
//
//  Created by Adam Ibrahim on 01/05/2026.
//

import SwiftUI

enum DialogCopy {
    static let deletePhoto = RRDialogContent(
        title: "Delete this photo?",
        message: "This removes the photo from this record.",
        confirmTitle: "Delete",
        cancelTitle: "Cancel",
        confirmRole: .destructive
    )

    static let deleteDocument = RRDialogContent(
        title: "Delete this document?",
        message: "This removes the document from this record.",
        confirmTitle: "Delete",
        cancelTitle: "Cancel",
        confirmRole: .destructive
    )

    static let deleteTimelineEvent = RRDialogContent(
        title: "Delete this event?",
        message: "This removes the event from this record.",
        confirmTitle: "Delete",
        cancelTitle: "Cancel",
        confirmRole: .destructive
    )

    static let deleteRoom = RRDialogContent(
        title: "Delete this room?",
        message: "This removes the room and its checklist from this record.",
        confirmTitle: "Delete",
        cancelTitle: "Cancel",
        confirmRole: .destructive
    )

    static let deleteRentalRecord = RRDialogContent(
        title: "Delete this record?",
        message: "This removes the record, including its photos and documents, from this device. This cannot be undone.",
        confirmTitle: "Delete",
        cancelTitle: "Cancel",
        confirmRole: .destructive
    )

    static let deleteAllData = RRDialogContent(
        title: "Delete all Rentory data?",
        message: "This removes all rental records, photos, documents and temporary reports from this device. This cannot be undone.",
        confirmTitle: "Delete all data",
        cancelTitle: "Cancel",
        confirmRole: .destructive
    )

    static let archiveRecord = RRDialogContent(
        title: "Archive this record?",
        message: "You can keep it out of your active list without deleting it.",
        confirmTitle: "Archive",
        cancelTitle: "Cancel",
        confirmRole: .destructive
    )

    static let clearTemporaryReports = RRDialogContent(
        title: "Clear temporary reports?",
        message: "This removes reports created earlier from temporary storage on this device.",
        confirmTitle: "Clear reports",
        cancelTitle: "Cancel",
        confirmRole: .destructive
    )

    static let reportCreated = RRAlertContent(
        title: "Report ready",
        message: "Your report has been created on this device.",
        buttonTitle: "Share report"
    )

    static let reportFailed = RRAlertContent(error: .reportCouldNotBeCreated)

    static let purchaseRestored = RRAlertContent(
        title: "Purchase restored",
        message: "Your lifetime unlock is ready to use on this device.",
        buttonTitle: "OK"
    )

    static let purchaseCompleted = RRAlertContent(
        title: "Thank you for unlocking Rentory",
        message: "Your lifetime unlock is now ready to use. Thank you for supporting Rentory.",
        buttonTitle: "OK"
    )

    static let purchaseNotCompleted = RRAlertContent(error: .purchaseNotCompleted)

    static let appUnlockFailed = RRAlertContent(error: .appCouldNotBeUnlocked)

    static let appLockUnavailable = RRAlertContent(error: .appLockNotAvailable)

    static let appLockTurnedOn = RRAlertContent(
        title: "App Lock turned on",
        message: "Rentory will ask you to unlock the app before showing your rental records.",
        buttonTitle: "OK"
    )

    static let appLockNotTurnedOn = RRAlertContent(
        title: "App Lock not turned on",
        message: "You can try again when you are ready.",
        buttonTitle: "OK"
    )

    static let appLockTurnedOff = RRAlertContent(
        title: "App Lock turned off",
        message: "Rentory will open without asking to unlock.",
        buttonTitle: "OK"
    )

    static let appLockStillOn = RRAlertContent(
        title: "App Lock is still on",
        message: "Rentory will keep asking to unlock before showing your records.",
        buttonTitle: "OK"
    )

    static let photoNotAdded = RRAlertContent(error: .photoCouldNotBeAdded)

    static let documentNotOpened = RRAlertContent(error: .documentCouldNotBeOpened)
}
