//
//  ChecklistItemRowView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct ChecklistItemRowView: View {
    let item: ChecklistItemRecord

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
    }

    private var conditionSummary: some View {
        Group {
            RRConditionBadge(condition: item.moveInCondition)
            RRConditionBadge(condition: item.moveOutCondition)
        }
    }
}
