//
//  FeatureAccessService.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

struct FeatureAccessService {
    static func canCreateProperty(currentPropertyCount: Int, isUnlocked: Bool) -> Bool {
        isUnlocked || currentPropertyCount < FreePlanLimits.maxPropertyPacks
    }

    static func canAddRoom(currentRoomCount: Int, isUnlocked: Bool) -> Bool {
        isUnlocked || currentRoomCount < FreePlanLimits.maxRooms
    }

    static func canAddPhoto(currentPhotoCount: Int, isUnlocked: Bool) -> Bool {
        isUnlocked || currentPhotoCount < FreePlanLimits.maxPhotos
    }

    static func canCreateFullReport(isUnlocked: Bool) -> Bool {
        isUnlocked || !FreePlanLimits.fullReportExportRequiresUnlock
    }

    static func canUseAppLock(isUnlocked: Bool) -> Bool {
        isUnlocked || !FreePlanLimits.appLockRequiresUnlock
    }

    static func propertyLimitPrompt(isSampleDataUsingFreeRecord: Bool) -> UpgradePromptContent {
        if isSampleDataUsingFreeRecord {
            return UpgradePromptContent(
                title: "Sample records are using your free slot",
                message: "You can keep the sample records and make them your own, clear them in Settings > Data on this device > Sample data, or unlock Rentory to create more records."
            )
        }

        return UpgradePromptContent(
            title: "You’ve used your free record",
            message: "You can keep using this record. Unlock Rentory when you want to create more."
        )
    }

    static let roomLimitPrompt = UpgradePromptContent(
        title: "You’ve added two rooms",
        message: "You can keep using these rooms. Unlock Rentory to add more."
    )

    static let photoLimitPrompt = UpgradePromptContent(
        title: "You’ve added twenty photos",
        message: "You can keep viewing and deleting your photos. Unlock Rentory to add more."
    )

    static let reportLimitPrompt = UpgradePromptContent(
        title: "Full reports are included with the lifetime unlock",
        message: "You can keep building your record and unlock full report export when you are ready."
    )

    static let appLockLimitPrompt = UpgradePromptContent(
        title: "App Lock is included with the lifetime unlock",
        message: "Keep using your existing records and unlock Rentory when you want App Lock."
    )
}
