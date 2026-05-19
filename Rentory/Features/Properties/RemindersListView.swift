//
//  RemindersListView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 17/05/2026.
//

import SwiftData
import SwiftUI

struct RemindersListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let propertyPack: PropertyPack

    @State private var isShowingAddSheet = false
    @State private var alertContent: RRAlertContent?

    private var openReminders: [Reminder] {
        propertyPack.reminders
            .filter { !$0.isCompleted }
            .sorted { lhs, rhs in
                let lhsDate = lhs.dueDate ?? .distantFuture
                let rhsDate = rhs.dueDate ?? .distantFuture
                if lhsDate != rhsDate {
                    return lhsDate < rhsDate
                }
                return lhs.createdAt < rhs.createdAt
            }
    }

    private var completedReminders: [Reminder] {
        propertyPack.reminders
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private var openGroups: [(ReminderUrgency, [Reminder])] {
        let now = Date.now
        let order: [ReminderUrgency] = [.overdue, .dueSoon, .upcoming, .undated]
        return order.compactMap { urgency in
            let items = openReminders.filter { ReminderService.urgency(for: $0, on: now) == urgency }
            return items.isEmpty ? nil : (urgency, items)
        }
    }

    @AppStorage(AppColourTheme.storageKey) private var appColourThemeRawValue = AppColourTheme.defaultLook.rawValue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                if propertyPack.reminders.isEmpty {
                    RREmptyStateView(
                        symbolName: "checklist",
                        title: "No reminders yet",
                        message: "Track what needs doing so nothing slips. Things like submitting the deposit form, chasing a repair, or attending an inspection all fit here.",
                        buttonTitle: "Add a reminder",
                        buttonAction: { isShowingAddSheet = true }
                    )
                } else {
                    ForEach(openGroups, id: \.0) { urgency, items in
                        sectionView(title: title(for: urgency), tint: tint(for: urgency), reminders: items)
                    }

                    if !completedReminders.isEmpty {
                        sectionView(title: "Completed", tint: RRColours.success, reminders: completedReminders)
                    }
                }
            }
            .frame(maxWidth: DeviceLayout.contentWidth(for: horizontalSizeClass, maximum: 980), alignment: .leading)
            .padding(RRTheme.screenPadding)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(RRBackgroundView())
        .navigationTitle("All reminders")
        .rrInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .rrPrimaryAction) {
                Button {
                    isShowingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add reminder")
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            AddReminderView(propertyPack: propertyPack)
                .rrAdaptiveSheetPresentation()
        }
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
    }

    @ViewBuilder
    private func sectionView(title: String, tint: Color, reminders: [Reminder]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(RRTypography.headline)
                    .foregroundStyle(tint)

                Spacer()

                Text("\(reminders.count)")
                    .font(RRTypography.footnote.weight(.semibold))
                    .foregroundStyle(RRColours.mutedText)
            }

            VStack(spacing: 0) {
                ForEach(Array(reminders.enumerated()), id: \.element.id) { index, reminder in
                    if index > 0 {
                        Divider()
                            .background(RRColours.border)
                    }
                    NavigationLink {
                        ReminderDetailView(reminder: reminder, propertyPack: propertyPack)
                    } label: {
                        reminderRow(reminder: reminder)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(RRColours.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    @ViewBuilder
    private func reminderRow(reminder: Reminder) -> some View {
        let urgency = ReminderService.urgency(for: reminder)
        HStack(spacing: 12) {
            Image(systemName: reminder.kind.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(RRColours.secondary)
                .frame(width: 28, height: 28)
                .background(RRColours.cardHighlight, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(RRTypography.headline)
                    .foregroundStyle(reminder.isCompleted ? RRColours.mutedText : RRColours.primary)
                    .strikethrough(reminder.isCompleted)
                    .lineLimit(2)

                rowSubtitle(reminder: reminder, urgency: urgency)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(RRColours.mutedText)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .id(appColourThemeRawValue)
    }

    @ViewBuilder
    private func rowSubtitle(reminder: Reminder, urgency: ReminderUrgency) -> some View {
        if reminder.isCompleted, let completedAt = reminder.completedAt {
            Text("Completed \(formattedDate(completedAt))")
                .font(RRTypography.footnote)
                .foregroundStyle(RRColours.success)
        } else if let dueDate = reminder.dueDate {
            Text("Due \(formattedDate(dueDate))")
                .font(RRTypography.footnote)
                .foregroundStyle(tint(for: urgency))
        } else {
            Text(reminder.kind.rawValue)
                .font(RRTypography.footnote)
                .foregroundStyle(RRColours.mutedText)
        }
    }

    private func title(for urgency: ReminderUrgency) -> String {
        switch urgency {
        case .overdue: return "Overdue"
        case .dueSoon: return "Due this week"
        case .upcoming: return "Later"
        case .undated: return "No due date"
        case .completed: return "Completed"
        }
    }

    private func tint(for urgency: ReminderUrgency) -> Color {
        switch urgency {
        case .overdue: return RRColours.danger
        case .dueSoon: return RRColours.warning
        case .upcoming, .undated: return RRColours.mutedText
        case .completed: return RRColours.success
        }
    }

    private func formattedDate(_ date: Date) -> String {
        Self.formatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "en_GB")
        return formatter
    }()
}
