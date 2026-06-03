//
//  PropertyActionWidget.swift
//  RentoryWidgets
//
//  Small + medium widget showing the user's most-active record together
//  with its single next suggested action and completion progress. The
//  purpose is action-oriented: not "you have 4 photos" trivia, but "this
//  record is 62% complete and the next thing to do is add move-in photos".
//
//  Falls back to a friendly empty state when the user has no records yet.
//

import AppIntents
import SwiftUI
import WidgetKit

struct PropertyActionWidget: Widget {
    let kind = "RentoryPropertyActionWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: RentoryPropertyConfigurationIntent.self,
            provider: PropertyActionTimelineProvider()
        ) { entry in
            PropertyActionWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next step")
        .description("Pick a record (long-press to edit) and the widget shows its next suggested action and completion progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PropertyActionEntry: TimelineEntry {
    let date: Date
    let primary: Item?
    let supporting: [Item]

    /// Smart Stack relevance. Records with low completion + a defined
    /// next action are the most worth nudging — that's when the widget
    /// genuinely helps the user move forward. Records already near
    /// 100% get less air time.
    var relevance: TimelineEntryRelevance? {
        guard let primary else {
            return TimelineEntryRelevance(score: 0)
        }
        let hasAction = primary.nextActionTitle != nil
        switch primary.completionPercent {
        case ..<26: return TimelineEntryRelevance(score: hasAction ? 70 : 50)
        case 26...60: return TimelineEntryRelevance(score: hasAction ? 50 : 35)
        case 61...89: return TimelineEntryRelevance(score: 30)
        default: return TimelineEntryRelevance(score: 15)
        }
    }

    struct Item: Identifiable, Hashable {
        let id: UUID
        let nickname: String
        let recordTypeRawValue: String
        let completionPercent: Int
        let nextActionTitle: String?
        let completionStatusTitle: String
    }

    static let placeholder = PropertyActionEntry(
        date: Date(),
        primary: Item(
            id: UUID(),
            nickname: "Main rental house",
            recordTypeRawValue: "House",
            completionPercent: 62,
            nextActionTitle: "Add a move-in photo",
            completionStatusTitle: "Good progress"
        ),
        supporting: [
            Item(
                id: UUID(),
                nickname: "Studio flat",
                recordTypeRawValue: "Flat",
                completionPercent: 88,
                nextActionTitle: "Confirm move-out condition",
                completionStatusTitle: "Nearly ready"
            ),
            Item(
                id: UUID(),
                nickname: "Coastal cottage",
                recordTypeRawValue: "House",
                completionPercent: 24,
                nextActionTitle: "Add a room",
                completionStatusTitle: "Getting started"
            )
        ]
    )

    static let emptySample = PropertyActionEntry(date: Date(), primary: nil, supporting: [])
}

struct PropertyActionTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PropertyActionEntry {
        .placeholder
    }

    func snapshot(for configuration: RentoryPropertyConfigurationIntent, in context: Context) async -> PropertyActionEntry {
        makeEntry(configuration: configuration, context: context)
    }

    func timeline(for configuration: RentoryPropertyConfigurationIntent, in context: Context) async -> Timeline<PropertyActionEntry> {
        let entry = makeEntry(configuration: configuration, context: context)
        let nextRefresh = Date().addingTimeInterval(60 * 60 * 4)
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    private func makeEntry(configuration: RentoryPropertyConfigurationIntent, context: Context) -> PropertyActionEntry {
        if context.isPreview {
            return .placeholder
        }

        let snapshot = RentorySharedSnapshotStore.read()
        let items = snapshot.properties.map { property -> PropertyActionEntry.Item in
            PropertyActionEntry.Item(
                id: property.id,
                nickname: property.nickname,
                recordTypeRawValue: property.recordTypeRawValue,
                completionPercent: property.completionPercent,
                nextActionTitle: property.nextActionTitle,
                completionStatusTitle: property.completionStatusTitle
            )
        }

        // Honour the user's configured property first; fall back to the
        // top-of-list item (favourite + most-recently-updated) so the
        // widget still surfaces something useful on a brand-new install
        // before the user has edited it.
        let primary: PropertyActionEntry.Item?
        if let configuredID = configuration.property?.id,
           let match = items.first(where: { $0.id == configuredID }) {
            primary = match
        } else {
            primary = items.first
        }

        let supporting = Array(items.filter { $0.id != primary?.id }.prefix(2))
        return PropertyActionEntry(date: Date(), primary: primary, supporting: supporting)
    }
}

struct PropertyActionWidgetEntryView: View {
    let entry: PropertyActionEntry

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

    /// Tapping the widget focuses the primary (top-of-list) property.
    private var deepLinkURL: URL? {
        guard let primary = entry.primary else { return nil }
        return URL(string: "rentory://property/\(primary.id.uuidString)")
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            Spacer(minLength: 0)
            if let primary = entry.primary {
                Text(primary.nickname)
                    .font(WidgetTheme.Typography.headline)
                    .foregroundStyle(WidgetTheme.Palette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                if let action = primary.nextActionTitle {
                    Text(action)
                        .font(WidgetTheme.Typography.footnote)
                        .foregroundStyle(WidgetTheme.Palette.mutedText)
                        .lineLimit(2)
                } else {
                    Text("Ready to export")
                        .font(WidgetTheme.Typography.footnote)
                        .foregroundStyle(WidgetTheme.Palette.success)
                }
                progressRow(percent: primary.completionPercent)
            } else {
                emptyStateMessage
            }
        }
        .padding(2)
    }

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            if let primary = entry.primary {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(primary.nickname)
                            .font(WidgetTheme.Typography.title)
                            .foregroundStyle(WidgetTheme.Palette.primary)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text("\(primary.completionPercent)%")
                            .font(WidgetTheme.Typography.headline)
                            .foregroundStyle(tint(forPercent: primary.completionPercent))
                    }

                    if let action = primary.nextActionTitle {
                        Label(action, systemImage: "arrow.forward.circle.fill")
                            .labelStyle(.titleAndIcon)
                            .font(WidgetTheme.Typography.body)
                            .foregroundStyle(WidgetTheme.Palette.secondary)
                            .lineLimit(2)
                    } else {
                        Label("Ready to export", systemImage: "checkmark.seal.fill")
                            .labelStyle(.titleAndIcon)
                            .font(WidgetTheme.Typography.body)
                            .foregroundStyle(WidgetTheme.Palette.success)
                    }

                    progressRow(percent: primary.completionPercent)
                }

                if !entry.supporting.isEmpty {
                    Divider().opacity(0.4)
                    VStack(spacing: 4) {
                        ForEach(entry.supporting) { item in
                            HStack(spacing: 6) {
                                Text(item.nickname)
                                    .font(WidgetTheme.Typography.footnote)
                                    .foregroundStyle(WidgetTheme.Palette.primary)
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                Text("\(item.completionPercent)%")
                                    .font(WidgetTheme.Typography.footnote.weight(.semibold))
                                    .foregroundStyle(tint(forPercent: item.completionPercent))
                            }
                        }
                    }
                }
            } else {
                Spacer(minLength: 0)
                emptyStateMessage
                Spacer(minLength: 0)
            }
        }
        .padding(2)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("NEXT STEP")
                .font(WidgetTheme.Typography.caption)
                .foregroundStyle(WidgetTheme.Palette.mutedText)
                .tracking(0.6)
            Spacer(minLength: 0)
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WidgetTheme.Palette.secondary)
        }
    }

    private var emptyStateMessage: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Create your first record")
                .font(WidgetTheme.Typography.headline)
                .foregroundStyle(WidgetTheme.Palette.primary)
            Text("Open Rentory to add a property and start building your evidence record.")
                .font(WidgetTheme.Typography.footnote)
                .foregroundStyle(WidgetTheme.Palette.mutedText)
                .lineLimit(3)
        }
    }

    private func progressRow(percent: Int) -> some View {
        let clamped = max(0, min(100, percent))
        return ProgressView(value: Double(clamped), total: 100)
            .progressViewStyle(.linear)
            .tint(tint(forPercent: clamped))
    }

    private func tint(forPercent percent: Int) -> Color {
        switch percent {
        case ..<26: return WidgetTheme.Palette.danger
        case 26...60: return WidgetTheme.Palette.warning
        case 61...89: return WidgetTheme.Palette.secondary
        default: return WidgetTheme.Palette.success
        }
    }
}

#Preview(as: .systemSmall) {
    PropertyActionWidget()
} timeline: {
    PropertyActionEntry.placeholder
    PropertyActionEntry.emptySample
}

#Preview(as: .systemMedium) {
    PropertyActionWidget()
} timeline: {
    PropertyActionEntry.placeholder
    PropertyActionEntry.emptySample
}
