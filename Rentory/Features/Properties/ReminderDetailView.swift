//
//  ReminderDetailView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 17/05/2026.
//

import SwiftData
import SwiftUI

struct ReminderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var reminderNotificationService: ReminderNotificationService
    @AppStorage(RentoryUserProfile.storageKey) private var profileRawValue = RentoryUserProfile.defaultProfile.rawValue

    let reminder: Reminder
    let propertyPack: PropertyPack

    private var profile: RentoryUserProfile {
        RentoryUserProfile(rawValue: profileRawValue) ?? .defaultProfile
    }

    @State private var title: String
    @State private var notes: String
    @State private var kind: ReminderKind
    @State private var priority: ReminderPriority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var recurrence: ReminderRecurrence
    @State private var isCompleted: Bool
    @State private var alertContent: RRAlertContent?
    @State private var isShowingDeleteConfirmation = false

    init(reminder: Reminder, propertyPack: PropertyPack) {
        self.reminder = reminder
        self.propertyPack = propertyPack
        _title = State(initialValue: reminder.title)
        _notes = State(initialValue: reminder.notes ?? "")
        _kind = State(initialValue: reminder.kind)
        _priority = State(initialValue: reminder.priority)
        _hasDueDate = State(initialValue: reminder.dueDate != nil)
        _dueDate = State(initialValue: reminder.dueDate ?? .now)
        _recurrence = State(initialValue: reminder.recurrence)
        _isCompleted = State(initialValue: reminder.isCompleted)
    }

    var body: some View {
        Form {
            Section {
                RRSheetHeader(
                    title: "Edit reminder",
                    subtitle: "Update the details, mark complete, or remove the reminder.",
                    systemImage: reminder.kind.iconName
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Reminder") {
                TextField("Title", text: $title)
                    .rrTextInputAutocapitalizationWords()

                Picker("Kind", selection: $kind) {
                    ForEach(ReminderKind.availableCases(for: profile), id: \.self) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }

                Picker("Priority", selection: $priority) {
                    ForEach(ReminderPriority.allCases, id: \.self) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                }
            }

            Section("Due date") {
                Toggle("Has a due date", isOn: $hasDueDate)

                if hasDueDate {
                    DatePicker("Due", selection: $dueDate, displayedComponents: .date)

                    Picker("Repeat", selection: $recurrence) {
                        ForEach(ReminderRecurrence.allCases) { rule in
                            Text(rule.rawValue).tag(rule)
                        }
                    }
                }
            }

            Section("Notes") {
                TextField("Add a short note", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Toggle("Completed", isOn: $isCompleted)
            }

            Section {
                RRDestructiveButton(title: "Delete reminder") {
                    isShowingDeleteConfirmation = true
                }
            }
        }
        .navigationTitle(reminder.title)
        .rrInlineNavigationTitle()
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
        .toolbar {
            ToolbarItem(placement: .rrPrimaryAction) {
                Button("Save") {
                    saveChanges()
                }
            }
        }
        .confirmationDialog(
            "Delete reminder?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteReminder()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This reminder will be removed from this record.")
        }
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
    }

    private func saveChanges() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            alertContent = RRAlertContent(
                title: "Reminder not saved",
                message: "Add a reminder title to continue."
            )
            return
        }

        reminder.title = trimmedTitle
        reminder.notes = optionalText(notes)
        reminder.kind = kind
        reminder.priority = priority
        reminder.dueDate = hasDueDate ? dueDate : nil
        // Recurrence is only meaningful with a due date. Clearing the
        // toggle wipes any stored cadence so a re-toggle starts fresh.
        reminder.recurrence = hasDueDate ? recurrence : .none

        let now = Date.now
        let wasCompletedBefore = reminder.completedAt != nil
        let isBeingCompletedNow = isCompleted && !wasCompletedBefore

        if isBeingCompletedNow {
            reminder.completedAt = now
            // If the user marked a recurring reminder complete, spawn
            // the next occurrence on the same record. The completed
            // reminder stays as an audit row; the new one becomes the
            // live action for the next cycle. We branch on dueDate
            // existing rather than recurrence != .none because the
            // recurrence picker is hidden without a due date — but
            // defend in depth in case the picker state is preserved.
            if reminder.isRecurring,
               let currentDue = reminder.dueDate,
               let nextDue = reminder.recurrence.nextDueDate(after: currentDue) {
                let nextOccurrence = Reminder(
                    title: trimmedTitle,
                    notes: optionalText(notes),
                    dueDate: nextDue,
                    kind: kind,
                    priority: priority,
                    recurrence: reminder.recurrence,
                    linkedRoomID: reminder.linkedRoomID,
                    linkedChecklistItemID: reminder.linkedChecklistItemID,
                    linkedDocumentID: reminder.linkedDocumentID,
                    linkedTimelineEventID: reminder.linkedTimelineEventID
                )
                propertyPack.reminders.append(nextOccurrence)
            }
        } else if !isCompleted {
            reminder.completedAt = nil
        }

        propertyPack.updatedAt = now

        do {
            try modelContext.save()
            RentorySnapshotPublisher.requestRepublish()
            RRHaptics.success()
            Task { await reminderNotificationService.reschedule(context: modelContext) }
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeSaved)
        }
    }

    private func deleteReminder() {
        let reminderID = reminder.id
        modelContext.delete(reminder)
        propertyPack.updatedAt = .now

        do {
            try modelContext.save()
            RentorySnapshotPublisher.requestRepublish()
            RRHaptics.success()
            reminderNotificationService.cancel(reminderID: reminderID)
            Task { await reminderNotificationService.reschedule(context: modelContext) }
            dismiss()
        } catch {
            alertContent = RRAlertContent(
                title: "Reminder not deleted",
                message: "This reminder could not be deleted. Please try again."
            )
        }
    }
}
