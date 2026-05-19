//
//  RemindersCard.swift
//  Rentory
//
//  Created by Adam Ibrahim on 17/05/2026.
//

import SwiftUI

struct RemindersCard: View {
    let propertyPack: PropertyPack
    let onSelectReminder: (Reminder) -> Void
    let onViewAllReminders: () -> Void
    let onAddReminder: () -> Void

    private var pulse: ReminderOverview {
        ReminderService.overview(for: propertyPack)
    }

    @AppStorage(AppColourTheme.storageKey) private var appColourThemeRawValue = AppColourTheme.defaultLook.rawValue

    var body: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                header(for: pulse)

                if pulse.overdueCount + pulse.dueSoonCount > 0 {
                    countPills(for: pulse)
                }

                if !pulse.upcomingItems.isEmpty {
                    Divider()
                        .background(RRColours.border)
                    upcomingList(items: pulse.upcomingItems)
                }

                footerButton(for: pulse)
            }
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder
    private func header(for pulse: ReminderOverview) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reminders")
                .font(RRTypography.footnote.weight(.semibold))
                .foregroundStyle(RRColours.mutedText)
                .textCase(.uppercase)

            Text(pulse.statusTitle)
                .font(RRTypography.title)
                .foregroundStyle(statusColor(for: pulse))

            Text(pulse.shortMessage)
                .font(RRTypography.body)
                .foregroundStyle(RRColours.mutedText)
        }
    }

    @ViewBuilder
    private func countPills(for pulse: ReminderOverview) -> some View {
        HStack(spacing: 8) {
            if pulse.overdueCount > 0 {
                countPill(value: pulse.overdueCount, label: "overdue", colour: RRColours.danger)
            }
            if pulse.dueSoonCount > 0 {
                countPill(value: pulse.dueSoonCount, label: "due this week", colour: RRColours.warning)
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

    @ViewBuilder
    private func upcomingList(items: [ReminderSnapshot]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, snapshot in
                if index > 0 {
                    Divider()
                        .background(RRColours.border)
                }
                pulseRow(snapshot: snapshot)
            }
        }
    }

    private func pulseRow(snapshot: ReminderSnapshot) -> some View {
        Button {
            if let actionItem = propertyPack.reminders.first(where: { $0.id == snapshot.id }) {
                onSelectReminder(actionItem)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: snapshot.kind.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(RRColours.secondary)
                    .frame(width: 28, height: 28)
                    .background(RRColours.cardHighlight, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.title)
                        .font(RRTypography.headline)
                        .foregroundStyle(RRColours.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    datePill(snapshot: snapshot)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(RRColours.mutedText)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(snapshot.title), \(accessibilityDateDescription(for: snapshot))")
        .accessibilityHint("Opens the reminder.")
        .id(appColourThemeRawValue)
    }

    private func datePill(snapshot: ReminderSnapshot) -> some View {
        let tint = urgencyTint(for: snapshot.urgency)
        return HStack(spacing: 4) {
            Image(systemName: "calendar")
                .font(.system(size: 10, weight: .semibold))
            Text(relativeDateDescription(for: snapshot))
                .font(RRTypography.footnote.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.18), in: Capsule())
        .foregroundStyle(tint)
    }

    @ViewBuilder
    private func footerButton(for pulse: ReminderOverview) -> some View {
        if pulse.totalOpenCount > 0 {
            RRSecondaryButton(title: "View all reminders", action: onViewAllReminders)
        } else {
            RRSecondaryButton(title: "Add a reminder", action: onAddReminder)
        }
    }

    // MARK: - Helpers

    private func statusColor(for pulse: ReminderOverview) -> Color {
        if pulse.overdueCount > 0 { return RRColours.danger }
        if pulse.dueSoonCount > 0 { return RRColours.warning }
        return RRColours.primary
    }

    private func urgencyTint(for urgency: ReminderUrgency) -> Color {
        switch urgency {
        case .overdue:
            return RRColours.danger
        case .dueSoon:
            return RRColours.warning
        case .upcoming, .undated:
            return RRColours.mutedText
        case .completed:
            return RRColours.success
        }
    }

    private func relativeDateDescription(for snapshot: ReminderSnapshot) -> String {
        guard let dueDate = snapshot.dueDate else {
            return "No date"
        }
        return Self.relativeFormatter.localizedString(for: dueDate, relativeTo: .now)
    }

    private func accessibilityDateDescription(for snapshot: ReminderSnapshot) -> String {
        guard let dueDate = snapshot.dueDate else {
            return "no due date"
        }
        return "due \(Self.accessibleFormatter.string(from: dueDate))"
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "en_GB")
        return formatter
    }()

    private static let accessibleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "en_GB")
        return formatter
    }()
}
