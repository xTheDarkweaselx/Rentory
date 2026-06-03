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
    /// Optional one-line note explaining *why* this record matched a
    /// search term (e.g. "Matched in reminder: Gas safety"). When set,
    /// surfaces as a tinted footer pill so the user understands why a
    /// record is in the filtered list when the term doesn't appear in
    /// the visible nickname/address.
    var searchHint: String? = nil

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

                if let searchHint {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 10, weight: .semibold))
                        Text(searchHint)
                            .font(RRTypography.caption.weight(.semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(RRColours.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RRColours.secondary.opacity(0.14), in: Capsule())
                    .transition(.opacity)
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
