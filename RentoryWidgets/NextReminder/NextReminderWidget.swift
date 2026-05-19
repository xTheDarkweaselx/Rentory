//
//  NextReminderWidget.swift
//  RentoryWidgets
//
//  Small + medium widget showing the single next reminder due across the
//  user's records. Refreshes on each app foreground (when the main app
//  re-publishes the snapshot) and at midnight (when day-until-due
//  changes). No network. No login.
//

import SwiftUI
import WidgetKit

struct NextReminderWidget: Widget {
    let kind = "RentoryNextReminderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextReminderTimelineProvider()) { entry in
            NextReminderWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next reminder")
        .description("The next reminder due across your Rentory records.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NextReminderEntry: TimelineEntry {
    let date: Date
    let reminder: RentorySharedSnapshot.ReminderEntry?
    let activeProfileRawValue: String

    static let placeholder = NextReminderEntry(
        date: Date(),
        reminder: nil,
        activeProfileRawValue: "Renter"
    )

    static let sample = NextReminderEntry(
        date: Date(),
        reminder: RentorySharedSnapshot.ReminderEntry(
            id: UUID(),
            propertyID: UUID(),
            propertyNickname: "Main rental house",
            title: "Gas safety renewal",
            kindRawValue: "Gas safety",
            priorityRawValue: "Normal",
            dueDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()
        ),
        activeProfileRawValue: "Landlord"
    )
}

struct NextReminderTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextReminderEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (NextReminderEntry) -> Void) {
        completion(makeEntry(forContext: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextReminderEntry>) -> Void) {
        let entry = makeEntry(forContext: context)
        let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(60 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func makeEntry(forContext context: Context) -> NextReminderEntry {
        if context.isPreview {
            return .sample
        }

        let snapshot = RentorySharedSnapshotStore.read()
        return NextReminderEntry(
            date: Date(),
            reminder: snapshot.upcomingReminders.first,
            activeProfileRawValue: snapshot.activeProfileRawValue
        )
    }
}

struct NextReminderWidgetEntryView: View {
    let entry: NextReminderEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallLayout
        default:
            mediumLayout
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            Spacer(minLength: 0)
            if let reminder = entry.reminder {
                Text(reminder.title)
                    .font(WidgetTheme.Typography.headline)
                    .foregroundStyle(WidgetTheme.Palette.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(relativeDescription(for: reminder.dueDate))
                    .font(WidgetTheme.Typography.footnote.weight(.semibold))
                    .foregroundStyle(WidgetTheme.urgencyTint(for: daysUntilDue(for: reminder.dueDate)))
            } else {
                allClearMessage
            }
        }
        .padding(2)
    }

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            if let reminder = entry.reminder {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(WidgetTheme.Typography.title)
                        .foregroundStyle(WidgetTheme.Palette.primary)
                        .lineLimit(2)

                    Text(reminder.propertyNickname)
                        .font(WidgetTheme.Typography.body)
                        .foregroundStyle(WidgetTheme.Palette.mutedText)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Label(reminder.kindRawValue, systemImage: kindIcon(for: reminder.kindRawValue))
                        .labelStyle(.titleAndIcon)
                        .font(WidgetTheme.Typography.footnote)
                        .foregroundStyle(WidgetTheme.Palette.secondary)

                    Spacer(minLength: 0)

                    Text(relativeDescription(for: reminder.dueDate))
                        .font(WidgetTheme.Typography.headline)
                        .foregroundStyle(WidgetTheme.urgencyTint(for: daysUntilDue(for: reminder.dueDate)))
                }
            } else {
                Spacer(minLength: 0)
                allClearMessage
                Spacer(minLength: 0)
            }
        }
        .padding(2)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("NEXT REMINDER")
                .font(WidgetTheme.Typography.caption)
                .foregroundStyle(WidgetTheme.Palette.mutedText)
                .tracking(0.6)
            Spacer(minLength: 0)
            Image(systemName: "bell.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WidgetTheme.Palette.secondary)
        }
    }

    private var allClearMessage: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("All clear")
                .font(WidgetTheme.Typography.headline)
                .foregroundStyle(WidgetTheme.Palette.primary)
            Text("Nothing due in the next three weeks.")
                .font(WidgetTheme.Typography.footnote)
                .foregroundStyle(WidgetTheme.Palette.mutedText)
                .lineLimit(2)
        }
    }

    private func daysUntilDue(for date: Date) -> Int {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: now, to: target).day ?? 0
    }

    private func relativeDescription(for date: Date) -> String {
        let days = daysUntilDue(for: date)
        switch days {
        case ..<0:
            let pastDays = -days
            return pastDays == 1 ? "Overdue 1 day" : "Overdue \(pastDays) days"
        case 0:
            return "Due today"
        case 1:
            return "Due tomorrow"
        default:
            return "Due in \(days) days"
        }
    }

    private func kindIcon(for rawValue: String) -> String {
        switch rawValue {
        case "Gas safety": return "flame.fill"
        case "Electrical safety (EICR)": return "bolt.fill"
        case "Energy performance (EPC)": return "leaf.fill"
        case "Periodic inspection": return "magnifyingglass.circle.fill"
        case "Tenancy renewal": return "doc.text.fill"
        case "Inspection": return "magnifyingglass"
        case "Repair": return "wrench.and.screwdriver"
        case "Compliance": return "checkmark.shield"
        case "Deposit": return "sterlingsign.circle"
        case "Move-in": return "key"
        case "Move-out": return "rectangle.portrait.and.arrow.right"
        default: return "checklist"
        }
    }
}

#Preview(as: .systemSmall) {
    NextReminderWidget()
} timeline: {
    NextReminderEntry.sample
    NextReminderEntry.placeholder
}

#Preview(as: .systemMedium) {
    NextReminderWidget()
} timeline: {
    NextReminderEntry.sample
    NextReminderEntry.placeholder
}
