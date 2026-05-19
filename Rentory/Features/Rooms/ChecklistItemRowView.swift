//
//  ChecklistItemRowView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct ChecklistItemRowView: View {
    let item: ChecklistItemRecord
    var stage: TenancyStage? = nil

    private var photoSummary: String {
        switch item.photos.count {
        case 0:
            return "No photos"
        case 1:
            return "1 photo"
        default:
            return "\(item.photos.count) photos"
        }
    }

    @AppStorage(AppColourTheme.storageKey) private var appColourThemeRawValue = AppColourTheme.defaultLook.rawValue

    var body: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(item.title)
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)

                ViewThatFits {
                    HStack(spacing: 10) {
                        conditionSummary
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        conditionSummary
                    }
                }

                Text(photoSummary)
                    .font(RRTypography.caption)
                    .foregroundStyle(RRColours.mutedText)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.title), move-in \(item.moveInCondition.rawValue), move-out \(item.moveOutCondition.rawValue), \(photoSummary)")
        .accessibilityHint("Opens this checklist item.")
        .id(appColourThemeRawValue)
    }

    @ViewBuilder
    private var conditionSummary: some View {
        switch stage {
        case .moveIn:
            labelledCondition(label: "Move-in", condition: item.moveInCondition)
        case .moveOut:
            labelledCondition(label: "Move-out", condition: item.moveOutCondition)
        case .living, .none:
            Group {
                RRConditionBadge(condition: item.moveInCondition)
                RRConditionBadge(condition: item.moveOutCondition)
            }
        }
    }

    private func labelledCondition(label: String, condition: EvidenceCondition) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(RRTypography.caption.weight(.semibold))
                .foregroundStyle(RRColours.mutedText)
            RRConditionBadge(condition: condition)
        }
    }
}
