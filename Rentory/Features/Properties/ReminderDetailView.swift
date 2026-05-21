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

        let now = Date.now
        if isCompleted && reminder.completedAt == nil {
            reminder.completedAt = now
        } else if !isCompleted {
            reminder.completedAt = nil
        }

        propertyPack.updatedAt = now

        do {
            try modelContext.save()
            RentorySnapshotPublisher.requestRepublish()
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
