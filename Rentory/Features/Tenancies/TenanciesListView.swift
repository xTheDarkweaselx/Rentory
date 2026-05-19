//
//  TenanciesListView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 19/05/2026.
//

import SwiftData
import SwiftUI

struct TenanciesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(AppColourTheme.storageKey) private var appColourThemeRawValue = AppColourTheme.defaultLook.rawValue

    let propertyPack: PropertyPack

    @State private var isShowingAddSheet = false

    private var groupedTenancies: [(TenancyStatus, [Tenancy])] {
        let order: [TenancyStatus] = [.active, .upcoming, .ended]
        return order.compactMap { status in
            let matched = propertyPack.tenancies.filter { $0.status == status }
                .sorted { $0.startDate > $1.startDate }
            return matched.isEmpty ? nil : (status, matched)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                if propertyPack.tenancies.isEmpty {
                    RREmptyStateView(
                        symbolName: "person.2",
                        title: "No tenancies yet",
                        message: "Record a tenancy to track tenants, dates, deposit details and more for this property.",
                        buttonTitle: "Add a tenancy",
                        buttonAction: { isShowingAddSheet = true }
                    )
                } else {
                    ForEach(groupedTenancies, id: \.0) { status, tenancies in
                        section(title: status.rawValue, tint: tint(for: status), tenancies: tenancies)
                    }
                }
            }
            .frame(maxWidth: DeviceLayout.contentWidth(for: horizontalSizeClass, maximum: 980), alignment: .leading)
            .padding(RRTheme.screenPadding)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .scrollIndicators(.hidden)
        .background(RRBackgroundView())
        .navigationTitle("Tenancies")
        .rrInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .rrPrimaryAction) {
                Button { isShowingAddSheet = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add tenancy")
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            AddTenancyView(propertyPack: propertyPack)
                .rrAdaptiveSheetPresentation()
        }
        .id(appColourThemeRawValue)
    }

    @ViewBuilder
    private func section(title: String, tint: Color, tenancies: [Tenancy]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(RRTypography.headline)
                    .foregroundStyle(tint)
                Spacer()
                Text("\(tenancies.count)")
                    .font(RRTypography.footnote.weight(.semibold))
                    .foregroundStyle(RRColours.mutedText)
            }

            VStack(spacing: 0) {
                ForEach(Array(tenancies.enumerated()), id: \.element.id) { index, tenancy in
                    if index > 0 { Divider().background(RRColours.border) }
                    NavigationLink {
                        TenancyDetailView(tenancy: tenancy, propertyPack: propertyPack)
                    } label: {
                        row(tenancy: tenancy, tint: tint)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(RRColours.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    @ViewBuilder
    private func row(tenancy: Tenancy, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: tenancy.status.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(tenantsSummary(for: tenancy))
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)
                    .lineLimit(2)

                Text(dateRange(for: tenancy))
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)

                if let amount = tenancy.rentAmount, let freq = tenancy.rentFrequency {
                    Text(String(format: "£%.0f %@", amount, freq.rawValue.lowercased()))
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(RRColours.mutedText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
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

    private func tint(for status: TenancyStatus) -> Color {
        switch status {
        case .active: return RRColours.success
        case .upcoming: return RRColours.warning
        case .ended: return RRColours.mutedText
        }
    }
}
