//
//  TimelineEventDetailView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct TimelineEventDetailView: View {
    let event: TimelineEvent

    var body: some View {
        ScrollView {
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(event.title)
                        .font(RRTypography.title)
                        .foregroundStyle(RRColours.primary)

                    Text(event.eventType.rawValue)
                        .font(RRTypography.body)
                        .foregroundStyle(RRColours.mutedText)

                    Text(event.eventDate.formatted(date: .abbreviated, time: .omitted))
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)

                    if let notes = trimmed(event.notes) {
                        Text(notes)
                            .font(RRTypography.body)
                            .foregroundStyle(RRColours.mutedText)
                    }
                }
            }
            .padding(20)
        }
        .background(RRColours.groupedBackground.ignoresSafeArea())
        .navigationTitle(event.title)
        .rrInlineNavigationTitle()
    }

    private func trimmed(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
