//
//  RoomRowView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RoomRowView: View {
    let room: RoomRecord

    private var checkedItemCount: Int {
        room.checklistItems.filter { item in
            item.moveInCondition != .notChecked || item.moveOutCondition != .notChecked
        }.count
    }

    private var flaggedItemCount: Int {
        room.checklistItems.filter(\.isFlagged).count
    }

    private var progressLabel: String {
        guard !room.checklistItems.isEmpty else {
            return "Not started"
        }

        if checkedItemCount == 0 {
            return "Not started"
        }

        if checkedItemCount == room.checklistItems.count {
            return "Checked"
        }

        return "In progress"
    }

    var body: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name)
                        .font(RRTypography.headline)
                        .foregroundStyle(RRColours.primary)

                    Text(room.type.rawValue)
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                }

                ViewThatFits {
                    HStack(spacing: 10) {
                        summaryPills
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        summaryPills
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Opens this room.")
    }

    private var summaryPills: some View {
        Group {
            RRProgressPill(title: progressLabel, tint: RRColours.secondary)
            RRProgressPill(title: "\(checkedItemCount) of \(room.checklistItems.count) checked", tint: RRColours.success)
            if photoCount > 0 {
                RRProgressPill(title: photoCount == 1 ? "1 photo" : "\(photoCount) photos", tint: RRColours.warning)
            }

            if flaggedItemCount > 0 {
                RRProgressPill(title: "\(flaggedItemCount) flagged", tint: RRColours.danger)
            }
        }
    }

    private var photoCount: Int {
        room.checklistItems.reduce(0) { partialResult, item in
            partialResult + item.photos.count
        }
    }

    private var accessibilitySummary: String {
        var parts = [room.name, room.type.rawValue, progressLabel, "\(checkedItemCount) of \(room.checklistItems.count) checked"]
        if photoCount > 0 {
            parts.append(photoCount == 1 ? "1 photo" : "\(photoCount) photos")
        }
        if flaggedItemCount > 0 {
            parts.append("\(flaggedItemCount) flagged")
        }
        return parts.joined(separator: ", ")
    }
}
