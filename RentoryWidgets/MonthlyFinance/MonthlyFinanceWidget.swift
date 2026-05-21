//
//  MonthlyFinanceWidget.swift
//  RentoryWidgets
//
//  Small + medium widget that summarises this month's rent vs expenses
//  for the active landlord profile. If the active profile is renter (or
//  the landlord has no landlord-profile records), shows a calm "Landlord
//  only" message so renters aren't shown blank numbers.
//
//  Aggregates across all landlord properties in the snapshot. The medium
//  variant additionally lists the top three properties by net for the
//  current month so the user can see which records are pulling their
//  weight.
//

import SwiftUI
import WidgetKit

struct MonthlyFinanceWidget: Widget {
    let kind = "RentoryMonthlyFinanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthlyFinanceTimelineProvider()) { entry in
            MonthlyFinanceWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Monthly finance")
        .description("This month's rent received, expenses out, and net across your landlord records.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MonthlyFinanceEntry: TimelineEntry {
    let date: Date
    let isLandlordProfile: Bool
    let hasLandlordRecords: Bool
    let totalRentReceived: Double
    let totalExpenses: Double
    let totalNet: Double
    let currencyCode: String
    let topProperties: [PropertyLine]

    struct PropertyLine: Identifiable, Hashable {
        let id: UUID
        let nickname: String
        let net: Double
    }

    static let placeholder = MonthlyFinanceEntry(
        date: Date(),
        isLandlordProfile: true,
        hasLandlordRecords: true,
        totalRentReceived: 2400,
        totalExpenses: 615,
        totalNet: 1785,
        currencyCode: "GBP",
        topProperties: [
            PropertyLine(id: UUID(), nickname: "Main rental house", net: 980),
            PropertyLine(id: UUID(), nickname: "Studio flat", net: 540),
            PropertyLine(id: UUID(), nickname: "Coastal cottage", net: 265)
        ]
    )

    static let renterSample = MonthlyFinanceEntry(
        date: Date(),
        isLandlordProfile: false,
        hasLandlordRecords: false,
        totalRentReceived: 0,
        totalExpenses: 0,
        totalNet: 0,
        currencyCode: "GBP",
        topProperties: []
    )

    static let emptyLandlordSample = MonthlyFinanceEntry(
        date: Date(),
        isLandlordProfile: true,
        hasLandlordRecords: false,
        totalRentReceived: 0,
        totalExpenses: 0,
        totalNet: 0,
        currencyCode: "GBP",
        topProperties: []
    )
}

struct MonthlyFinanceTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthlyFinanceEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthlyFinanceEntry) -> Void) {
        completion(makeEntry(forContext: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthlyFinanceEntry>) -> Void) {
        let entry = makeEntry(forContext: context)
        let calendar = Calendar.current
        let now = Date()
        let nextRefresh: Date
        if let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: calendar.startOfMonth(for: now)),
           startOfNextMonth.timeIntervalSince(now) < 60 * 60 * 6 {
            nextRefresh = startOfNextMonth
        } else {
            nextRefresh = now.addingTimeInterval(60 * 60 * 6)
        }
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func makeEntry(forContext context: Context) -> MonthlyFinanceEntry {
        if context.isPreview {
            return .placeholder
        }

        let snapshot = RentorySharedSnapshotStore.read()
        let isLandlord = snapshot.activeProfileRawValue == "Landlord"
        let landlordProperties = snapshot.properties.filter { $0.profileRawValue == "Landlord" }

        guard isLandlord, !landlordProperties.isEmpty else {
            return MonthlyFinanceEntry(
                date: Date(),
                isLandlordProfile: isLandlord,
                hasLandlordRecords: !landlordProperties.isEmpty,
                totalRentReceived: 0,
                totalExpenses: 0,
                totalNet: 0,
                currencyCode: landlordProperties.first?.currencyCode ?? "GBP",
                topProperties: []
            )
        }

        let totalRent = landlordProperties.reduce(0.0) { $0 + ($1.monthRentReceived ?? 0) }
        let totalExpenses = landlordProperties.reduce(0.0) { $0 + ($1.monthExpenses ?? 0) }
        let totalNet = landlordProperties.reduce(0.0) { $0 + ($1.monthNet ?? 0) }
        let currencyCode = landlordProperties.first(where: { $0.currencyCode != nil })?.currencyCode ?? "GBP"

        let topProperties = landlordProperties
            .compactMap { property -> MonthlyFinanceEntry.PropertyLine? in
                guard let net = property.monthNet else { return nil }
                return MonthlyFinanceEntry.PropertyLine(id: property.id, nickname: property.nickname, net: net)
            }
            .sorted { $0.net > $1.net }
            .prefix(3)

        return MonthlyFinanceEntry(
            date: Date(),
            isLandlordProfile: true,
            hasLandlordRecords: true,
            totalRentReceived: totalRent,
            totalExpenses: totalExpenses,
            totalNet: totalNet,
            currencyCode: currencyCode,
            topProperties: Array(topProperties)
        )
    }
}

struct MonthlyFinanceWidgetEntryView: View {
    let entry: MonthlyFinanceEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallLayout
            default:
                mediumLayout
            }
        }
        .widgetURL(deepLinkURL)
    }

    /// Tapping the widget focuses the highest-net property when one
    /// exists; otherwise opens Rentory to the dashboard root.
    private var deepLinkURL: URL? {
        guard let first = entry.topProperties.first else { return nil }
        return URL(string: "rentory://property/\(first.id.uuidString)")
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            Spacer(minLength: 0)
            if shouldShowEmptyState {
                emptyStateMessage
            } else {
                Text(formattedCurrency(entry.totalNet))
                    .font(WidgetTheme.Typography.title)
                    .foregroundStyle(netTint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text("Net this month")
                    .font(WidgetTheme.Typography.footnote)
                    .foregroundStyle(WidgetTheme.Palette.mutedText)
            }
        }
        .padding(2)
    }

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            if shouldShowEmptyState {
                Spacer(minLength: 0)
                emptyStateMessage
                Spacer(minLength: 0)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    summaryColumn(
                        title: "Rent in",
                        value: entry.totalRentReceived,
                        tint: WidgetTheme.Palette.success
                    )
                    summaryColumn(
                        title: "Expenses",
                        value: entry.totalExpenses,
                        tint: WidgetTheme.Palette.warning
                    )
                    summaryColumn(
                        title: "Net",
                        value: entry.totalNet,
                        tint: netTint
                    )
                }

                if !entry.topProperties.isEmpty {
                    Divider().opacity(0.4)
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(entry.topProperties.prefix(3)) { line in
                            HStack(spacing: 6) {
                                Text(line.nickname)
                                    .font(WidgetTheme.Typography.footnote)
                                    .foregroundStyle(WidgetTheme.Palette.primary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer(minLength: 4)
                                Text(formattedCurrency(line.net))
                                    .font(WidgetTheme.Typography.footnote.weight(.semibold))
                                    .foregroundStyle(line.net >= 0 ? WidgetTheme.Palette.success : WidgetTheme.Palette.danger)
                            }
                        }
                    }
                }
            }
        }
        .padding(2)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("THIS MONTH")
                .font(WidgetTheme.Typography.caption)
                .foregroundStyle(WidgetTheme.Palette.mutedText)
                .tracking(0.6)
            Spacer(minLength: 0)
            Image(systemName: "sterlingsign.circle.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WidgetTheme.Palette.secondary)
        }
    }

    private var shouldShowEmptyState: Bool {
        !entry.isLandlordProfile || !entry.hasLandlordRecords
    }

    private var emptyStateMessage: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.isLandlordProfile ? "No landlord records yet" : "Switch to Landlord profile")
                .font(WidgetTheme.Typography.headline)
                .foregroundStyle(WidgetTheme.Palette.primary)
                .lineLimit(2)
            Text(entry.isLandlordProfile
                 ? "Add a property to your landlord profile to see monthly figures here."
                 : "Open Rentory and switch profiles to see landlord finance figures.")
                .font(WidgetTheme.Typography.footnote)
                .foregroundStyle(WidgetTheme.Palette.mutedText)
                .lineLimit(3)
        }
    }

    private func summaryColumn(title: String, value: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(WidgetTheme.Typography.caption)
                .foregroundStyle(WidgetTheme.Palette.mutedText)
                .tracking(0.4)
            Text(formattedCurrency(value))
                .font(WidgetTheme.Typography.headline)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var netTint: Color {
        entry.totalNet >= 0 ? WidgetTheme.Palette.success : WidgetTheme.Palette.danger
    }

    private func formattedCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = entry.currencyCode
        formatter.maximumFractionDigits = abs(amount) >= 1000 ? 0 : 2
        return formatter.string(from: NSNumber(value: amount)) ?? "—"
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

#Preview(as: .systemSmall) {
    MonthlyFinanceWidget()
} timeline: {
    MonthlyFinanceEntry.placeholder
    MonthlyFinanceEntry.renterSample
}

#Preview(as: .systemMedium) {
    MonthlyFinanceWidget()
} timeline: {
    MonthlyFinanceEntry.placeholder
    MonthlyFinanceEntry.emptyLandlordSample
}
