//
//  QuickAddReminderView.swift  (RentoryWatch target)
//  Rentory
//
//  Lightweight reminder capture. The user picks a property scope
//  (defaults to the favourite / first record), records a one-line
//  title via Scribble or Dictation, and chooses one of three quick
//  due-date buckets (today, tomorrow, next week). The new reminder
//  is queued in WCSession.transferUserInfo so iOS receives and
//  persists it on next reachability.
//
//  No SwiftData on the watch — the iPhone remains the source of
//  truth. Until the iPhone confirms by emitting a fresh snapshot,
//  the user sees their pending reminder count in the header.
//

import SwiftUI
import WatchConnectivity

struct QuickAddReminderView: View {
    @EnvironmentObject private var snapshotStore: WatchSnapshotStore
    @EnvironmentObject private var session: WatchSessionCoordinator

    @State private var title: String = ""
    @State private var selectedPropertyID: UUID?
    @State private var dueBucket: DueBucket = .tomorrow
    /// Track every reminder we've queued in this session so we can
    /// decrement when the iPhone confirms it landed (see
    /// WatchSessionCoordinator.confirmedReminderIDs). pendingCount is
    /// derived from this so the UI updates atomically.
    @State private var pendingReminderIDs: [UUID] = []
    @State private var lastSubmitConfirmation: String?

    private var pendingCount: Int { pendingReminderIDs.count }

    enum DueBucket: String, CaseIterable, Identifiable {
        case today, tomorrow, nextWeek
        var id: String { rawValue }

        /// Long label shown when there's room. Used by the picker's
        /// accessibility text and as the wide-screen full title.
        var title: String {
            switch self {
            case .today: return "Today"
            case .tomorrow: return "Tomorrow"
            case .nextWeek: return "Next week"
            }
        }

        /// Compact label for 40mm watch buttons where the wide title
        /// would force per-glyph compression. Combined with
        /// minimumScaleFactor in the UI so it shrinks cleanly when needed.
        var shortTitle: String {
            switch self {
            case .today: return "Today"
            case .tomorrow: return "Tom"
            case .nextWeek: return "+1w"
            }
        }

        var dueDate: Date {
            let calendar = Calendar.current
            switch self {
            case .today: return calendar.startOfDay(for: Date())
            case .tomorrow: return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? Date()
            case .nextWeek: return calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: Date())) ?? Date()
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if snapshotStore.snapshot.properties.isEmpty {
                    emptyState
                } else {
                    titleField
                    propertyPicker
                    duePicker
                    submitButton
                    if let confirmation = lastSubmitConfirmation {
                        Text(confirmation)
                            .font(WatchTheme.Typography.footnote)
                            .foregroundStyle(WatchTheme.Palette.success)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
        .navigationTitle("New reminder")
        .onAppear {
            if selectedPropertyID == nil {
                selectedPropertyID = snapshotStore.snapshot.properties.first?.id
            }
        }
        .onReceive(session.$confirmedReminderIDs) { confirmedIDs in
            // The iPhone has acknowledged one or more of our queued
            // reminders. Drop them from the local list (so the
            // "Queued to iPhone (N waiting)" string reflects reality)
            // and tell the session to forget them too so the set
            // doesn't accumulate forever.
            for id in confirmedIDs where pendingReminderIDs.contains(id) {
                pendingReminderIDs.removeAll { $0 == id }
                session.consumeConfirmation(for: id)
            }
            if pendingReminderIDs.isEmpty, lastSubmitConfirmation != nil {
                lastSubmitConfirmation = "All sent to iPhone"
            } else if !confirmedIDs.isEmpty {
                lastSubmitConfirmation = "Queued to iPhone (\(pendingCount) waiting)"
            }
        }
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TITLE")
                .font(WatchTheme.Typography.caption)
                .tracking(0.5)
                .foregroundStyle(WatchTheme.Palette.mutedText)
            TextField("e.g. Boiler service", text: $title)
                .textFieldStyle(.plain)
                .font(WatchTheme.Typography.body)
        }
    }

    private var propertyPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("RECORD")
                .font(WatchTheme.Typography.caption)
                .tracking(0.5)
                .foregroundStyle(WatchTheme.Palette.mutedText)
            Picker("Property", selection: $selectedPropertyID) {
                ForEach(snapshotStore.snapshot.properties) { property in
                    Text(property.nickname).tag(Optional(property.id))
                }
            }
            .pickerStyle(.navigationLink)
            .labelsHidden()
        }
    }

    private var duePicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DUE")
                .font(WatchTheme.Typography.caption)
                .tracking(0.5)
                .foregroundStyle(WatchTheme.Palette.mutedText)
            HStack(spacing: 4) {
                ForEach(DueBucket.allCases) { bucket in
                    Button {
                        dueBucket = bucket
                    } label: {
                        Text(bucket.shortTitle)
                            .font(WatchTheme.Typography.footnote)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(dueBucket == bucket ? WatchTheme.Palette.secondary : Color.gray.opacity(0.2))
                            )
                            .foregroundStyle(dueBucket == bucket ? Color.white : WatchTheme.Palette.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(bucket.title)
                }
            }
        }
    }

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            Label("Queue to iPhone", systemImage: "paperplane.fill")
                .font(WatchTheme.Typography.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(WatchTheme.Palette.secondary)
        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || selectedPropertyID == nil)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "house.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(WatchTheme.Palette.secondary)
            Text("No records yet")
                .font(WatchTheme.Typography.headline)
            Text("Add a property on your iPhone to start adding reminders here.")
                .font(WatchTheme.Typography.footnote)
                .foregroundStyle(WatchTheme.Palette.mutedText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    private func submit() {
        guard let propertyID = selectedPropertyID else { return }
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let pending = PendingReminder(
            id: UUID(),
            propertyID: propertyID,
            title: trimmed,
            dueDate: dueBucket.dueDate,
            createdAt: Date()
        )

        if let data = try? pending.encoded() {
            if WCSession.isSupported() {
                WCSession.default.transferUserInfo([
                    "kind": "pending-reminder",
                    "payload": data
                ])
                pendingReminderIDs.append(pending.id)
                lastSubmitConfirmation = "Queued to iPhone (\(pendingCount) waiting)"
                title = ""
            } else {
                lastSubmitConfirmation = "Watch connectivity unavailable"
            }
        }
    }
}

struct PendingReminder: Codable, Equatable, Identifiable {
    let id: UUID
    let propertyID: UUID
    let title: String
    let dueDate: Date
    let createdAt: Date

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}
