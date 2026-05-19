//
//  PropertyCompletionComplication.swift  (RentoryWatchComplications)
//  Rentory
//
//  Watch face complication that surfaces the top record's completion
//  progress so the user can glance and see how close their current
//  rental record is to "ready to export". Useful at the start of a
//  tenancy when there are lots of empty fields, and at the end when
//  the user is hunting the last few items.
//

import SwiftUI
import WidgetKit

struct PropertyCompletionComplication: Widget {
    let kind = "RentoryPropertyCompletionComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PropertyCompletionComplicationProvider()) { entry in
            PropertyCompletionComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Record progress")
        .description("Top record's completion progress and next step.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct PropertyCompletionComplicationEntry: TimelineEntry {
    let date: Date
    let property: RentorySharedSnapshot.PropertyEntry?

    static let placeholder = PropertyCompletionComplicationEntry(date: Date(), property: nil)

    static let sample = PropertyCompletionComplicationEntry(
        date: Date(),
        property: RentorySharedSnapshot.PropertyEntry(
            id: UUID(),
            nickname: "Main rental house",
            recordTypeRawValue: "House",
            profileRawValue: "Landlord",
            isFavourite: true,
            completionPercent: 62,
            completionStatusTitle: "Good progress",
            nextActionTitle: "Add a move-in photo",
            recentEventTitle: nil,
            activeTenancyCount: 1,
            primaryTenantName: "A. Tenant",
            tenancyEndDate: nil,
            monthRentReceived: 1200,
            monthExpenses: 320,
            monthNet: 880,
            currencyCode: "GBP"
        )
    )
}

struct PropertyCompletionComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> PropertyCompletionComplicationEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PropertyCompletionComplicationEntry) -> Void) {
        completion(entry(forContext: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PropertyCompletionComplicationEntry>) -> Void) {
        let current = entry(forContext: context)
        let nextRefresh = Date().addingTimeInterval(60 * 60 * 4)
        completion(Timeline(entries: [current], policy: .after(nextRefresh)))
    }

    private func entry(forContext context: Context) -> PropertyCompletionComplicationEntry {
        if context.isPreview {
            return .sample
        }
        let snapshot = WatchComplicationSnapshotReader.read()
        return PropertyCompletionComplicationEntry(
            date: Date(),
            property: snapshot.properties.first
        )
    }
}

struct PropertyCompletionComplicationView: View {
    let entry: PropertyCompletionComplicationEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            inlineLayout
        case .accessoryCircular:
            circularLayout
        case .accessoryRectangular:
            rectangularLayout
        default:
            rectangularLayout
        }
    }

    private var inlineLayout: some View {
        Group {
            if let property = entry.property {
                Text("\(property.nickname) · \(property.completionPercent)%")
            } else {
                Text("Rentory · No records yet")
            }
        }
    }

    private var circularLayout: some View {
        Group {
            if let property = entry.property {
                let clamped = Double(max(0, min(100, property.completionPercent))) / 100
                ZStack {
                    Circle()
                        .stroke(progressTint(for: property.completionPercent).opacity(0.25), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: clamped)
                        .stroke(progressTint(for: property.completionPercent), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(property.completionPercent)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(progressTint(for: property.completionPercent))
                }
                .widgetAccentable()
            } else {
                Image(systemName: "house.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ComplicationTheme.secondary)
            }
        }
    }

    private var rectangularLayout: some View {
        Group {
            if let property = entry.property {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(property.nickname)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text("\(property.completionPercent)%")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(progressTint(for: property.completionPercent))
                    }
                    if let action = property.nextActionTitle {
                        Text(action)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text(property.completionStatusTitle)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text("No records yet")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Text("Add a property in Rentory to track progress.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private func progressTint(for percent: Int) -> Color {
        switch percent {
        case ..<26: return ComplicationTheme.danger
        case 26...60: return ComplicationTheme.warning
        case 61...89: return ComplicationTheme.secondary
        default: return ComplicationTheme.success
        }
    }
}
