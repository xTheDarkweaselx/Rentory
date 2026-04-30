//
//  PropertySummaryCard.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct PropertySummaryCard: View {
    let propertyPack: PropertyPack
    var showsLastUpdated = false

    private var locationSummary: String? {
        firstNonEmpty(propertyPack.townCity, propertyPack.postcode)
    }

    private var tenancySummary: String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        switch (propertyPack.tenancyStartDate, propertyPack.tenancyEndDate) {
        case let (start?, end?):
            return "\(formatter.string(from: start)) to \(formatter.string(from: end))"
        case let (start?, nil):
            return "From \(formatter.string(from: start))"
        case let (nil, end?):
            return "Until \(formatter.string(from: end))"
        case (nil, nil):
            return nil
        }
    }

    var body: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(propertyPack.nickname)
                        .font(RRTypography.headline)
                        .foregroundStyle(RRColours.primary)

                    if let locationSummary {
                        Label(locationSummary, systemImage: "mappin.and.ellipse")
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.mutedText)
                    }

                    if let tenancySummary {
                        Label(tenancySummary, systemImage: "calendar")
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.mutedText)
                    }

                    if showsLastUpdated {
                        Text("Updated \(propertyPack.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(RRTypography.caption)
                            .foregroundStyle(RRColours.mutedText)
                    }
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
        .accessibilityHint("Opens this rental record.")
    }

    private var summaryPills: some View {
        Group {
            RRProgressPill(title: "\(propertyPack.rooms.count) rooms", tint: RRColours.secondary)
            RRProgressPill(title: "\(propertyPack.documents.count) documents", tint: RRColours.warning)
            RRProgressPill(title: "\(propertyPack.timelineEvents.count) events", tint: RRColours.success)
        }
    }

    private var accessibilitySummary: String {
        var parts = [propertyPack.nickname]
        if let locationSummary {
            parts.append(locationSummary)
        }
        if let tenancySummary {
            parts.append(tenancySummary)
        }
        if showsLastUpdated {
            parts.append("Updated \(propertyPack.updatedAt.formatted(date: .abbreviated, time: .omitted))")
        }
        parts.append("\(propertyPack.rooms.count) rooms")
        parts.append("\(propertyPack.documents.count) documents")
        parts.append("\(propertyPack.timelineEvents.count) events")
        return parts.joined(separator: ", ")
    }
}

private func firstNonEmpty(_ values: String?...) -> String? {
    values.first(where: { value in
        guard let value else { return false }
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }) ?? nil
}
