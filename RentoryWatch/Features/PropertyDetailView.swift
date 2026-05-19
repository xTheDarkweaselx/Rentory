//
//  PropertyDetailView.swift  (RentoryWatch target)
//  Rentory
//
//  One-step detail for a property snapshot. Surfaces the actionable
//  bits — next suggested step, completion percentage, the property's
//  most pressing reminder — without drowning the user in data. Anything
//  deeper opens on the paired iPhone.
//

import SwiftUI

struct PropertyDetailView: View {
    let property: RentorySharedSnapshot.PropertyEntry

    @EnvironmentObject private var snapshotStore: WatchSnapshotStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                header
                Divider()
                completionSection
                if let action = property.nextActionTitle {
                    Divider()
                    nextActionSection(action)
                }
                if let reminder = nextReminderForProperty {
                    Divider()
                    nextReminderSection(reminder)
                }
                if property.profileRawValue == "Landlord", let net = property.monthNet {
                    Divider()
                    landlordFinanceSection(net: net)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
        .navigationTitle(property.nickname)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(property.recordTypeRawValue.uppercased())
                .font(WatchTheme.Typography.caption)
                .tracking(0.5)
                .foregroundStyle(WatchTheme.Palette.mutedText)
            Text(property.nickname)
                .font(WatchTheme.Typography.title)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }

    private var completionSection: some View {
        HStack(spacing: 10) {
            CompletionRing(percent: property.completionPercent)
                .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(property.completionStatusTitle)
                    .font(WatchTheme.Typography.headline)
                Text("\(property.completionPercent)% complete")
                    .font(WatchTheme.Typography.footnote)
                    .foregroundStyle(WatchTheme.Palette.mutedText)
            }
        }
    }

    private func nextActionSection(_ action: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Next step", systemImage: "arrow.forward.circle.fill")
                .font(WatchTheme.Typography.caption)
                .foregroundStyle(WatchTheme.Palette.secondary)
            Text(action)
                .font(WatchTheme.Typography.body)
                .lineLimit(3)
        }
    }

    private func nextReminderSection(_ reminder: RentorySharedSnapshot.ReminderEntry) -> some View {
        let days = WatchTheme.daysUntilDue(for: reminder.dueDate)
        return VStack(alignment: .leading, spacing: 4) {
            Label("Next reminder", systemImage: "bell.fill")
                .font(WatchTheme.Typography.caption)
                .foregroundStyle(WatchTheme.urgencyTint(for: days))
            Text(reminder.title)
                .font(WatchTheme.Typography.body)
                .lineLimit(2)
            Text(WatchTheme.relativeDescription(for: reminder.dueDate))
                .font(WatchTheme.Typography.footnote)
                .foregroundStyle(WatchTheme.urgencyTint(for: days))
        }
    }

    private func landlordFinanceSection(net: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("This month", systemImage: "sterlingsign.circle.fill")
                .font(WatchTheme.Typography.caption)
                .foregroundStyle(WatchTheme.Palette.secondary)
            Text(formattedNet(net))
                .font(WatchTheme.Typography.body)
                .foregroundStyle(net >= 0 ? WatchTheme.Palette.success : WatchTheme.Palette.danger)
            if let tenant = property.primaryTenantName {
                Text("Tenant: \(tenant)")
                    .font(WatchTheme.Typography.footnote)
                    .foregroundStyle(WatchTheme.Palette.mutedText)
                    .lineLimit(1)
            }
        }
    }

    private var nextReminderForProperty: RentorySharedSnapshot.ReminderEntry? {
        snapshotStore.snapshot.upcomingReminders.first(where: { $0.propertyID == property.id })
    }

    private func formattedNet(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = property.currencyCode ?? "GBP"
        formatter.maximumFractionDigits = abs(value) >= 1000 ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }
}
