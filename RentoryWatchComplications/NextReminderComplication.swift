//
//  NextReminderComplication.swift  (RentoryWatchComplications target)
//  Rentory
//
//  Watch face complication showing the next reminder due across the
//  user's records, refreshed when the watch app receives a new
//  snapshot from the paired iPhone. Supports the four standard
//  accessory families so users can choose where on the face it lives.
//

import SwiftUI
import WidgetKit

struct NextReminderComplication: Widget {
    let kind = "RentoryNextReminderComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextReminderComplicationProvider()) { entry in
            NextReminderComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next reminder")
        .description("Next rental reminder due across your records.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}

struct NextReminderComplicationEntry: TimelineEntry {
    let date: Date
    let reminder: RentorySharedSnapshot.ReminderEntry?

    static let placeholder = NextReminderComplicationEntry(
        date: Date(),
        reminder: nil
    )

    static let sample = NextReminderComplicationEntry(
        date: Date(),
        reminder: RentorySharedSnapshot.ReminderEntry(
            id: UUID(),
            propertyID: UUID(),
            propertyNickname: "Main rental house",
            title: "Gas safety renewal",
            kindRawValue: "Gas safety",
            priorityRawValue: "Normal",
            dueDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()
        )
    )
}

struct NextReminderComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextReminderComplicationEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (NextReminderComplicationEntry) -> Void) {
        completion(entry(forContext: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextReminderComplicationEntry>) -> Void) {
        let current = entry(forContext: context)
        let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(60 * 60)
        completion(Timeline(entries: [current], policy: .after(nextMidnight)))
    }

    private func entry(forContext context: Context) -> NextReminderComplicationEntry {
        if context.isPreview {
            return .sample
        }
        let snapshot = WatchComplicationSnapshotReader.read()
        return NextReminderComplicationEntry(
            date: Date(),
            reminder: snapshot.upcomingReminders.first
        )
    }
}

struct NextReminderComplicationView: View {
    let entry: NextReminderComplicationEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                inlineLayout
            case .accessoryCircular:
                circularLayout
            case .accessoryCorner:
                cornerLayout
            case .accessoryRectangular:
                rectangularLayout
            default:
                rectangularLayout
            }
        }
        .widgetURL(deepLinkURL)
    }

    /// Tapping the complication opens the watch app focused on the
    /// reminder's parent property. We use the parent property (not the
    /// reminder itself) so the user lands on the actionable surface.
    private var deepLinkURL: URL? {
        guard let propertyID = entry.reminder?.propertyID else { return nil }
        return URL(string: "rentory://property/\(propertyID.uuidString)")
    }

    private var inlineLayout: some View {
        Group {
            if let reminder = entry.reminder {
                let days = ComplicationTheme.daysUntilDue(for: reminder.dueDate)
                let prefix = days < 0 ? "Overdue: " : "Next: "
                Text("\(prefix)\(reminder.title) (\(ComplicationTheme.relativeShortDescription(for: reminder.dueDate)))")
            } else {
                Text("Rentory · All clear")
            }
        }
    }

    private var circularLayout: some View {
        Group {
            if let reminder = entry.reminder {
                let days = ComplicationTheme.daysUntilDue(for: reminder.dueDate)
                VStack(spacing: 1) {
                    Image(systemName: ComplicationTheme.kindIcon(for: reminder.kindRawValue))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ComplicationTheme.urgencyTint(for: days))
                    Text(ComplicationTheme.relativeShortDescription(for: reminder.dueDate))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            } else {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ComplicationTheme.success)
            }
        }
        .widgetAccentable()
    }

    private var cornerLayout: some View {
        Group {
            if let reminder = entry.reminder {
                let days = ComplicationTheme.daysUntilDue(for: reminder.dueDate)
                Image(systemName: ComplicationTheme.kindIcon(for: reminder.kindRawValue))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ComplicationTheme.urgencyTint(for: days))
                    .widgetLabel {
                        Text("\(reminder.title) · \(ComplicationTheme.relativeShortDescription(for: reminder.dueDate))")
                            .lineLimit(1)
                    }
            } else {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ComplicationTheme.success)
                    .widgetLabel {
                        Text("All clear")
                    }
            }
        }
    }

    private var rectangularLayout: some View {
        Group {
            if let reminder = entry.reminder {
                let days = ComplicationTheme.daysUntilDue(for: reminder.dueDate)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Image(systemName: ComplicationTheme.kindIcon(for: reminder.kindRawValue))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(ComplicationTheme.urgencyTint(for: days))
                        Text(reminder.title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                    }
                    Text(reminder.propertyNickname)
                        .font(.system(size: 11, design: .rounded))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                    Text(ComplicationTheme.relativeShortDescription(for: reminder.dueDate))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(ComplicationTheme.urgencyTint(for: days))
                }
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text("All clear")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Text("Nothing due in the next 3 weeks.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }
}
