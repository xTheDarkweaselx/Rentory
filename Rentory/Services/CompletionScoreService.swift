//
//  CompletionScoreService.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

struct CompletionScoreResult {
    let percentage: Int
    let statusTitle: String
    let shortMessage: String
    let completedItems: [String]
    let suggestedNextItems: [String]
}

enum CompletionScoreService {
    static func score(for propertyPack: PropertyPack) -> CompletionScoreResult {
        let checks = buildChecks(for: propertyPack)
        let completedChecks = checks.filter(\.isComplete)
        let percentage = Int((Double(completedChecks.count) / Double(checks.count)) * 100.0)

        let statusTitle: String
        let shortMessage: String

        switch percentage {
        case 0..<26:
            statusTitle = "Getting started"
            shortMessage = "Add a few details to build out this record."
        case 26..<61:
            statusTitle = "Good progress"
            shortMessage = "You have started building a useful record."
        case 61..<90:
            statusTitle = "Nearly ready"
            shortMessage = "This record has most of the key sections filled in."
        default:
            statusTitle = "Ready to export"
            shortMessage = "This record is ready to turn into a report."
        }

        let completedItems = completedChecks.map(\.completedLabel)
        let suggestedNextItems = checks
            .filter { !$0.isComplete }
            .map(\.suggestedLabel)
            .prefix(2)

        return CompletionScoreResult(
            percentage: percentage,
            statusTitle: statusTitle,
            shortMessage: shortMessage,
            completedItems: completedItems,
            suggestedNextItems: Array(suggestedNextItems)
        )
    }

    private static func buildChecks(for propertyPack: PropertyPack) -> [CompletionCheck] {
        let checklistItems = propertyPack.rooms.flatMap(\.checklistItems)
        let hasMoveInChecks = checklistItems.contains { $0.moveInCondition != .notChecked }
        let hasMoveOutChecks = checklistItems.contains { $0.moveOutCondition != .notChecked }
        let hasPhotos = checklistItems.contains { !$0.photos.isEmpty }
        let hasOptionalLocation = [
            propertyPack.addressLine1,
            propertyPack.townCity,
            propertyPack.postcode,
        ].contains { value in
            guard let value else { return false }
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let hasTenancyDates = propertyPack.tenancyStartDate != nil && propertyPack.tenancyEndDate != nil

        return [
            CompletionCheck(
                isComplete: true,
                completedLabel: "Property record created",
                suggestedLabel: "Create a record"
            ),
            CompletionCheck(
                isComplete: !propertyPack.rooms.isEmpty,
                completedLabel: "Added at least one room",
                suggestedLabel: "Add your first room"
            ),
            CompletionCheck(
                isComplete: hasMoveInChecks,
                completedLabel: "Checked some move-in room items",
                suggestedLabel: "Check a few room items"
            ),
            CompletionCheck(
                isComplete: hasMoveOutChecks,
                completedLabel: "Checked some move-out room items",
                suggestedLabel: "Add move-out checks"
            ),
            CompletionCheck(
                isComplete: hasPhotos,
                completedLabel: "Added at least one photo",
                suggestedLabel: "Add move-in photos"
            ),
            CompletionCheck(
                isComplete: !propertyPack.documents.isEmpty,
                completedLabel: "Added at least one document",
                suggestedLabel: "Add useful documents"
            ),
            CompletionCheck(
                isComplete: !propertyPack.timelineEvents.isEmpty,
                completedLabel: "Added at least one timeline event",
                suggestedLabel: "Add a timeline event"
            ),
            CompletionCheck(
                isComplete: hasTenancyDates,
                completedLabel: "Added tenancy dates",
                suggestedLabel: "Add tenancy dates"
            ),
            CompletionCheck(
                isComplete: hasOptionalLocation,
                completedLabel: "Added some location details",
                suggestedLabel: "Add location details"
            ),
        ]
    }
}

private struct CompletionCheck {
    let isComplete: Bool
    let completedLabel: String
    let suggestedLabel: String
}
