//
//  ComplianceCard.swift
//  Rentory
//
//  Created by Adam Ibrahim on 19/05/2026.
//

import SwiftUI

/// A landlord-only summary of compliance reminders: gas safety, electrical
/// (EICR), energy performance (EPC), periodic inspections and tenancy
/// renewals. Mirrors `RemindersCard`'s shape but filters to landlord-only
/// reminder kinds, so landlords can see compliance status independently of
/// the broader reminder backlog.
struct ComplianceCard: View {
    let propertyPack: PropertyPack
    let onSelectReminder: (Reminder) -> Void
    let onViewAllReminders: () -> Void
    let onAddReminder: () -> Void

    @AppStorage(AppColourTheme.storageKey) private var appColourThemeRawValue = AppColourTheme.defaultLook.rawValue

    private var complianceReminders: [Reminder] {
        propertyPack.reminders.filter { $0.kind.isLandlordOnly }
    }

    private var openCompliance: [Reminder] {
        complianceReminders.filter { !$0.isCompleted }
    }

    private var overdue: [Reminder] {
        openCompliance.filter { reminder in
            guard let dueDate = reminder.dueDate else { return false }
            return dueDate < .now
        }
    }

    private var dueSoon: [Reminder] {
        let cutoff = Date.now.addingTimeInterval(ReminderService.dueSoonWindow)
        return openCompliance.filter { reminder in
            guard let dueDate = reminder.dueDate else { return false }
            return dueDate >= .now && dueDate <= cutoff
        }
    }

    private var upcomingPreview: [Reminder] {
        let sortedOverdue = overdue.sorted { ($0.dueDate ?? .distantPast) < ($1.dueDate ?? .distantPast) }
        let sortedDueSoon = dueSoon.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        let combined = sortedOverdue + sortedDueSoon
        if !combined.isEmpty {
            return Array(combined.prefix(3))
        }
        // No overdue/due-soon: show the next 3 future-dated open compliance
        // reminders, so landlords can preview their next renewal.
        return openCompliance
            .filter { ($0.dueDate ?? .distantPast) >= .now }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                header

                if complianceReminders.isEmpty {
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
            Text("Compliance")
                .font(RRTypography.footnote.weight(.semibold))
                .foregroundStyle(RRColours.mutedText)
                .textCase(.uppercase)

            Text(statusTitle)
                .font(RRTypography.title)
                .foregroundStyle(statusColour)

            Text(statusMessage)
                .font(RRTypography.body)
                .foregroundStyle(RRColours.mutedText)
        }
    }

    @ViewBuilder
    private var emptyBody: some View {
        Text("No compliance reminders yet. Add gas safety, EICR, EPC, periodic inspection or tenancy renewal dates to stay ahead.")
            .font(RRTypography.footnote)
            .foregroundStyle(RRColours.mutedText)
            .fixedSize(horizontal: false, vertical: true)

        RRSecondaryButton(title: "Add a compliance reminder", action: onAddReminder)
    }

    @ViewBuilder
    private var populatedBody: some View {
        if !overdue.isEmpty || !dueSoon.isEmpty {
            countPills
        }

        if !upcomingPreview.isEmpty {
            Divider().background(RRColours.border)
            previewList
        }

        if openCompliance.isEmpty {
            RRSecondaryButton(title: "Add a compliance reminder", action: onAddReminder)
        } else {
            RRSecondaryButton(title: "View all reminders", action: onViewAllReminders)
        }
    }

    private var countPills: some View {
        HStack(spacing: 8) {
            if !overdue.isEmpty {
                countPill(value: overdue.count, label: "overdue", colour: RRColours.danger)
            }
            if !dueSoon.isEmpty {
                countPill(value: dueSoon.count, label: "due this week", colour: RRColours.warning)
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

    private var previewList: some View {
        VStack(spacing: 0) {
            ForEach(Array(upcomingPreview.enumerated()), id: \.element.id) { index, reminder in
                if index > 0 {
                    Divider().background(RRColours.border)
                }
                previewRow(for: reminder)
            }
        }
    }

    private func previewRow(for reminder: Reminder) -> some View {
        Button {
            onSelectReminder(reminder)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: reminder.kind.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(RRColours.secondary)
                    .frame(width: 28, height: 28)
                    .background(RRColours.cardHighlight, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(RRTypography.headline)
                        .foregroundStyle(RRColours.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        Text(reminder.kind.rawValue)
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.mutedText)

                        if reminder.dueDate != nil {
                            Text("•")
                                .font(RRTypography.footnote)
                                .foregroundStyle(RRColours.mutedText)
                            datePill(for: reminder)
                        }
                    }
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
        .accessibilityLabel("\(reminder.title), \(reminder.kind.rawValue), \(accessibilityDate(for: reminder))")
        .accessibilityHint("Opens the reminder.")
    }

    private func datePill(for reminder: Reminder) -> some View {
        let urgency = ReminderService.urgency(for: reminder)
        let tint = urgencyTint(for: urgency)
        return Text(relativeDate(for: reminder))
            .font(RRTypography.footnote.weight(.semibold))
            .foregroundStyle(tint)
    }

    // MARK: - Copy helpers

    private var statusTitle: String {
        if complianceReminders.isEmpty {
            return "Nothing tracked"
        }
        if !overdue.isEmpty {
            return overdue.count == 1 ? "1 overdue" : "\(overdue.count) overdue"
        }
        if !dueSoon.isEmpty {
            return dueSoon.count == 1 ? "1 due this week" : "\(dueSoon.count) due this week"
        }
        if openCompliance.isEmpty {
            return "All up to date"
        }
        return "All on track"
    }

    private var statusMessage: String {
        if complianceReminders.isEmpty {
            return "Stay ahead of renewals with a few quick reminders."
        }
        if !overdue.isEmpty {
            return "Renewals overdue. Sort these as soon as you can."
        }
        if !dueSoon.isEmpty {
            return "Renewals due in the next 7 days."
        }
        if openCompliance.isEmpty {
            return "No open compliance items. History is kept for the record."
        }
        return "Nothing overdue or due this week."
    }

    private var statusColour: Color {
        if !overdue.isEmpty { return RRColours.danger }
        if !dueSoon.isEmpty { return RRColours.warning }
        if openCompliance.isEmpty && !complianceReminders.isEmpty { return RRColours.success }
        return RRColours.primary
    }

    private func urgencyTint(for urgency: ReminderUrgency) -> Color {
        switch urgency {
        case .overdue: return RRColours.danger
        case .dueSoon: return RRColours.warning
        case .upcoming, .undated: return RRColours.mutedText
        case .completed: return RRColours.success
        }
    }

    private func relativeDate(for reminder: Reminder) -> String {
        guard let dueDate = reminder.dueDate else { return "No date" }
        return Self.relativeFormatter.localizedString(for: dueDate, relativeTo: .now)
    }

    private func accessibilityDate(for reminder: Reminder) -> String {
        guard let dueDate = reminder.dueDate else { return "no due date" }
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
