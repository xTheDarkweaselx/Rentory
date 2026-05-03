//
//  TimelineEventRowView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct TimelineEventRowView: View {
    let event: TimelineEvent

    var body: some View {
        RRGlassCard {
            HStack(alignment: .top, spacing: 12) {
                RRIconBadge(systemName: "calendar", tint: RRColours.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(RRTypography.headline)
                        .foregroundStyle(RRColours.primary)

                    Text(event.eventType.rawValue)
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)

                    Text(event.eventDate.formatted(date: .abbreviated, time: .omitted))
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)

                    if trimmed(event.notes) != nil {
                        Text("Has notes")
                            .font(RRTypography.body)
                            .foregroundStyle(RRColours.mutedText)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Opens this timeline event.")
    }

    private var accessibilitySummary: String {
        var parts = [event.title, event.eventType.rawValue, event.eventDate.formatted(date: .abbreviated, time: .omitted)]
        if trimmed(event.notes) != nil {
            parts.append("Has notes")
        }
        return parts.joined(separator: ", ")
    }

    private func trimmed(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
