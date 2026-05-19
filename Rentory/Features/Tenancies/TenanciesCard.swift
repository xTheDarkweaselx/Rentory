//
//  TenanciesCard.swift
//  Rentory
//
//  Created by Adam Ibrahim on 19/05/2026.
//

import SwiftUI

/// Compact summary of tenancies for the property dashboard. Shown only to
/// landlord-mode users via PropertyDashboardView's gating.
///
/// - Empty: nudges the landlord to record their first tenancy.
/// - With tenancies: shows the active (or next upcoming) tenancy at a glance
///   plus a status pill, and a "View all tenancies" button that drills into
///   the full list.
struct TenanciesCard: View {
    let propertyPack: PropertyPack
    let onAddTenancy: () -> Void
    let onViewAllTenancies: () -> Void

    @AppStorage(AppColourTheme.storageKey) private var appColourThemeRawValue = AppColourTheme.defaultLook.rawValue

    private var sortedTenancies: [Tenancy] {
        propertyPack.tenancies.sorted { $0.startDate > $1.startDate }
    }

    private var activeOrNextTenancy: Tenancy? {
        // Prefer the currently active tenancy. Fall back to the next upcoming.
        // If only ended tenancies exist, show the most recent.
        if let active = sortedTenancies.first(where: { $0.status == .active }) {
            return active
        }
        if let upcoming = sortedTenancies
            .filter({ $0.status == .upcoming })
            .sorted(by: { $0.startDate < $1.startDate })
            .first {
            return upcoming
        }
        return sortedTenancies.first
    }

    private var counts: (active: Int, upcoming: Int, ended: Int) {
        var active = 0, upcoming = 0, ended = 0
        for tenancy in propertyPack.tenancies {
            switch tenancy.status {
            case .active: active += 1
            case .upcoming: upcoming += 1
            case .ended: ended += 1
            }
        }
        return (active, upcoming, ended)
    }

    var body: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                header

                if propertyPack.tenancies.isEmpty {
                    emptyBody
                } else {
                    populatedBody
                }
            }
            .accessibilityElement(children: .contain)
        }
        .id(appColourThemeRawValue)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tenancies")
                .font(RRTypography.footnote.weight(.semibold))
                .foregroundStyle(RRColours.mutedText)
                .textCase(.uppercase)

            Text(headerTitle)
                .font(RRTypography.title)
                .foregroundStyle(headerColour)

            Text(headerMessage)
                .font(RRTypography.body)
                .foregroundStyle(RRColours.mutedText)
        }
    }

    @ViewBuilder
    private var emptyBody: some View {
        RRSecondaryButton(title: "Add a tenancy", action: onAddTenancy)
    }

    @ViewBuilder
    private var populatedBody: some View {
        if counts.active > 0 || counts.upcoming > 0 {
            countPills
        }

        if let tenancy = activeOrNextTenancy {
            Divider().background(RRColours.border)
            tenancySummary(for: tenancy)
        }

        RRSecondaryButton(title: "View all tenancies", action: onViewAllTenancies)
    }

    private var countPills: some View {
        HStack(spacing: 8) {
            if counts.active > 0 {
                countPill(value: counts.active, label: counts.active == 1 ? "active" : "active", colour: RRColours.success)
            }
            if counts.upcoming > 0 {
                countPill(value: counts.upcoming, label: "upcoming", colour: RRColours.warning)
            }
            if counts.ended > 0 {
                countPill(value: counts.ended, label: "ended", colour: RRColours.mutedText)
            }
        }
    }

    private func countPill(value: Int, label: String, colour: Color) -> some View {
        HStack(spacing: 6) {
            Text("\(value)")
                .font(RRTypography.headline)
                .foregroundStyle(.white)
            Text(label)
                .font(RRTypography.footnote.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(colour, in: Capsule())
    }

    private func tenancySummary(for tenancy: Tenancy) -> some View {
        HStack(spacing: 12) {
            Image(systemName: tenancy.status.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(statusTint(for: tenancy.status))
                .frame(width: 32, height: 32)
                .background(statusTint(for: tenancy.status).opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(tenantsSummary(for: tenancy))
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)
                    .lineLimit(2)

                Text(dateRange(for: tenancy))
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }

            Spacer(minLength: 8)

            statusBadge(for: tenancy.status)
        }
    }

    private func statusBadge(for status: TenancyStatus) -> some View {
        Text(status.rawValue)
            .font(RRTypography.footnote.weight(.semibold))
            .foregroundStyle(statusTint(for: status))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusTint(for: status).opacity(0.16), in: Capsule())
    }

    // MARK: - Copy helpers

    private var headerTitle: String {
        if propertyPack.tenancies.isEmpty {
            return "No tenancies yet"
        }
        if counts.active > 0 {
            return counts.active == 1 ? "1 active tenancy" : "\(counts.active) active tenancies"
        }
        if counts.upcoming > 0 {
            return counts.upcoming == 1 ? "1 upcoming" : "\(counts.upcoming) upcoming"
        }
        return "\(counts.ended) ended"
    }

    private var headerMessage: String {
        if propertyPack.tenancies.isEmpty {
            return "Record a tenancy to track tenants, dates and deposit details."
        }
        if counts.active > 0, counts.upcoming > 0 {
            return "\(counts.upcoming) upcoming and \(counts.ended) ended on file."
        }
        if counts.active > 0 {
            return counts.ended == 0
                ? "Currently active. Add another when this one ends."
                : "\(counts.ended) ended on file."
        }
        if counts.upcoming > 0 {
            return "No active tenancy right now."
        }
        return "No active or upcoming tenancies. History kept for the record."
    }

    private var headerColour: Color {
        if propertyPack.tenancies.isEmpty { return RRColours.primary }
        if counts.active > 0 { return RRColours.success }
        if counts.upcoming > 0 { return RRColours.warning }
        return RRColours.primary
    }

    private func statusTint(for status: TenancyStatus) -> Color {
        switch status {
        case .active: return RRColours.success
        case .upcoming: return RRColours.warning
        case .ended: return RRColours.mutedText
        }
    }

    private func tenantsSummary(for tenancy: Tenancy) -> String {
        let names = tenancy.tenants
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(\.name)
            .filter { !$0.isEmpty }

        if names.isEmpty {
            return "Tenancy (no tenants added)"
        }
        if names.count == 1 {
            return names[0]
        }
        if names.count == 2 {
            return "\(names[0]) & \(names[1])"
        }
        return "\(names[0]) +\(names.count - 1) more"
    }

    private func dateRange(for tenancy: Tenancy) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "en_GB")
        let startString = formatter.string(from: tenancy.startDate)
        if let endDate = tenancy.endDate {
            return "\(startString) – \(formatter.string(from: endDate))"
        }
        return "From \(startString)"
    }
}
