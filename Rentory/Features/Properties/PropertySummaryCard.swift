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

    @AppStorage(RentoryUserProfile.storageKey) private var profileRawValue = RentoryUserProfile.defaultProfile.rawValue

    private var profile: RentoryUserProfile {
        RentoryUserProfile(rawValue: profileRawValue) ?? .defaultProfile
    }

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

    @AppStorage(AppColourTheme.storageKey) private var appColourThemeRawValue = AppColourTheme.defaultLook.rawValue

    var body: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: RRTheme.controlSpacing) {
                    RRIconBadge(systemName: propertyPack.recordIconName, tint: RRColours.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(propertyPack.recordType.rawValue)
                            .font(RRTypography.title.weight(.semibold))
                            .foregroundStyle(RRColours.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        if let typeDetailSummary = propertyPack.typeDetailSummary {
                            Text(typeDetailSummary)
                                .font(RRTypography.footnote)
                                .foregroundStyle(RRColours.mutedText)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }

                    Spacer(minLength: 12)

                    if propertyPack.isFavourite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(RRColours.warning)
                            .accessibilityLabel("Favourite")
                    }
                }

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

                WrappingHStack(horizontalSpacing: 10, verticalSpacing: 8) {
                    summaryPills
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Opens this rental record.")
        .id(appColourThemeRawValue)
    }

    private var summaryPills: some View {
        Group {
            RRProgressPill(title: "\(propertyPack.rooms.count) rooms", tint: RRColours.secondary)
            RRProgressPill(title: "\(propertyPack.documents.count) documents", tint: RRColours.warning)
            RRProgressPill(title: "\(propertyPack.timelineEvents.count) events", tint: RRColours.success)
            if profile == .landlord, !propertyPack.tenancies.isEmpty {
                RRProgressPill(title: "\(propertyPack.tenancies.count) \(propertyPack.tenancies.count == 1 ? "tenancy" : "tenancies")", tint: RRColours.danger)
            }
        }
    }

    private var accessibilitySummary: String {
        var parts = [propertyPack.nickname, propertyPack.recordType.rawValue]
        if propertyPack.isFavourite {
            parts.append("Favourite")
        }
        if let typeDetailSummary = propertyPack.typeDetailSummary {
            parts.append(typeDetailSummary)
        }
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
        if profile == .landlord, !propertyPack.tenancies.isEmpty {
            parts.append("\(propertyPack.tenancies.count) \(propertyPack.tenancies.count == 1 ? "tenancy" : "tenancies")")
        }
        return parts.joined(separator: ", ")
    }
}

private func firstNonEmpty(_ values: String?...) -> String? {
    values.first(where: { value in
        guard let value else { return false }
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }) ?? nil
}

/// Lays out its subviews left-to-right, wrapping onto a new row when the next
/// subview would overflow the proposed width. Each row's height matches the
/// tallest subview on that row.
struct WrappingHStack: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = makeRows(maxWidth: proposal.width ?? .infinity, subviews: subviews)
        guard !rows.isEmpty else { return .zero }
        let height = rows.reduce(0) { $0 + $1.height } + verticalSpacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = makeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for placement in row.placements {
                subviews[placement.index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(placement.size)
                )
                x += placement.size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    private struct Placement {
        let index: Int
        let size: CGSize
    }

    private struct Row {
        let placements: [Placement]
        let width: CGFloat
        let height: CGFloat
    }

    private func makeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        guard !subviews.isEmpty else { return [] }

        var rows: [Row] = []
        var currentPlacements: [Placement] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        func flush() {
            guard !currentPlacements.isEmpty else { return }
            rows.append(Row(placements: currentPlacements, width: currentWidth, height: currentHeight))
            currentPlacements = []
            currentWidth = 0
            currentHeight = 0
        }

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let prospectiveWidth = currentWidth + (currentPlacements.isEmpty ? 0 : horizontalSpacing) + size.width
            if !currentPlacements.isEmpty && prospectiveWidth > maxWidth {
                flush()
                currentPlacements = [Placement(index: index, size: size)]
                currentWidth = size.width
                currentHeight = size.height
            } else {
                currentPlacements.append(Placement(index: index, size: size))
                currentWidth = prospectiveWidth
                currentHeight = max(currentHeight, size.height)
            }
        }
        flush()
        return rows
    }
}
