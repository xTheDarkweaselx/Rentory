//
//  UpcomingRemindersView.swift  (RentoryWatch target)
//  Rentory
//
//  Vertical list of upcoming reminders sourced from the snapshot.
//  Designed for glanceability: each row leads with the urgency tint,
//  shows the title + property nickname, and tapping pushes a detail
//  view rather than expanding inline.
//

import SwiftUI

struct UpcomingRemindersView: View {
    @EnvironmentObject private var snapshotStore: WatchSnapshotStore
    @EnvironmentObject private var session: WatchSessionCoordinator

    var body: some View {
        Group {
            if snapshotStore.snapshot.upcomingReminders.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(snapshotStore.snapshot.upcomingReminders) { reminder in
                        NavigationLink(value: reminder) {
                            row(for: reminder)
                        }
                    }
                }
                .listStyle(.carousel)
            }
        }
        .navigationTitle("Reminders")
        .navigationDestination(for: RentorySharedSnapshot.ReminderEntry.self) { reminder in
            ReminderDetailView(reminder: reminder)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    session.requestRefresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Request refresh from iPhone")
            }
        }
    }

    private func row(for reminder: RentorySharedSnapshot.ReminderEntry) -> some View {
        let days = WatchTheme.daysUntilDue(for: reminder.dueDate)
        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: WatchTheme.kindIcon(for: reminder.kindRawValue))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(WatchTheme.urgencyTint(for: days))
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(WatchTheme.Typography.headline)
                    .foregroundStyle(WatchTheme.Palette.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(reminder.propertyNickname)
                    .font(WatchTheme.Typography.footnote)
                    .foregroundStyle(WatchTheme.Palette.mutedText)
                    .lineLimit(1)
                Text(WatchTheme.relativeDescription(for: reminder.dueDate))
                    .font(WatchTheme.Typography.caption)
                    .foregroundStyle(WatchTheme.urgencyTint(for: days))
            }
        }
        .padding(.vertical, 2)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(WatchTheme.Palette.success)
            Text("All clear")
                .font(WatchTheme.Typography.title)
            Text("Nothing due in the next three weeks.")
                .font(WatchTheme.Typography.footnote)
                .foregroundStyle(WatchTheme.Palette.mutedText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct ReminderDetailView: View {
    let reminder: RentorySharedSnapshot.ReminderEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: WatchTheme.kindIcon(for: reminder.kindRawValue))
                        .foregroundStyle(WatchTheme.urgencyTint(for: WatchTheme.daysUntilDue(for: reminder.dueDate)))
                    Text(reminder.kindRawValue)
                        .font(WatchTheme.Typography.footnote)
                        .foregroundStyle(WatchTheme.Palette.mutedText)
                }
                Text(reminder.title)
                    .font(WatchTheme.Typography.title)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                Text(reminder.propertyNickname)
                    .font(WatchTheme.Typography.body)
                    .foregroundStyle(WatchTheme.Palette.mutedText)
                Divider()
                LabeledRow(label: "Due", value: WatchTheme.relativeDescription(for: reminder.dueDate))
                LabeledRow(label: "Date", value: reminder.dueDate.formatted(date: .abbreviated, time: .omitted))
                LabeledRow(label: "Priority", value: reminder.priorityRawValue)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
        .navigationTitle("Detail")
    }
}

private struct LabeledRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label.uppercased())
                .font(WatchTheme.Typography.caption)
                .tracking(0.5)
                .foregroundStyle(WatchTheme.Palette.mutedText)
            Spacer(minLength: 4)
            Text(value)
                .font(WatchTheme.Typography.body)
                .foregroundStyle(WatchTheme.Palette.primary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    NavigationStack {
        UpcomingRemindersView()
    }
    .environmentObject(WatchSnapshotStore.shared)
    .environmentObject(WatchSessionCoordinator.shared)
}
