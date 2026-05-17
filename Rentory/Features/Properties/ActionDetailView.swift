//
//  ActionDetailView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 17/05/2026.
//

import SwiftData
import SwiftUI

struct ActionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let action: ActionItem
    let propertyPack: PropertyPack

    @State private var title: String
    @State private var notes: String
    @State private var kind: ActionKind
    @State private var priority: ActionPriority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var isCompleted: Bool
    @State private var alertContent: RRAlertContent?
    @State private var isShowingDeleteConfirmation = false

    init(action: ActionItem, propertyPack: PropertyPack) {
        self.action = action
        self.propertyPack = propertyPack
        _title = State(initialValue: action.title)
        _notes = State(initialValue: action.notes ?? "")
        _kind = State(initialValue: action.kind)
        _priority = State(initialValue: action.priority)
        _hasDueDate = State(initialValue: action.dueDate != nil)
        _dueDate = State(initialValue: action.dueDate ?? .now)
        _isCompleted = State(initialValue: action.isCompleted)
    }

    var body: some View {
        Form {
            Section {
                RRSheetHeader(
                    title: "Edit action",
                    subtitle: "Update the details, mark complete, or remove the action.",
                    systemImage: action.kind.iconName
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Action") {
                TextField("Title", text: $title)
                    .rrTextInputAutocapitalizationWords()

                Picker("Kind", selection: $kind) {
                    ForEach(ActionKind.allCases, id: \.self) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }

                Picker("Priority", selection: $priority) {
                    ForEach(ActionPriority.allCases, id: \.self) { priority in
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
                RRDestructiveButton(title: "Delete action") {
                    isShowingDeleteConfirmation = true
                }
            }
        }
        .navigationTitle(action.title)
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
            "Delete action?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteAction()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action will be removed from this record.")
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
                title: "Action not saved",
                message: "Add an action title to continue."
            )
            return
        }

        action.title = trimmedTitle
        action.notes = optionalText(notes)
        action.kind = kind
        action.priority = priority
        action.dueDate = hasDueDate ? dueDate : nil

        let now = Date.now
        if isCompleted && action.completedAt == nil {
            action.completedAt = now
        } else if !isCompleted {
            action.completedAt = nil
        }

        propertyPack.updatedAt = now

        do {
            try modelContext.save()
            Task { await ActionNotificationScheduler.scheduleOrCancel(for: action) }
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeSaved)
        }
    }

    private func deleteAction() {
        let actionID = action.id
        modelContext.delete(action)
        propertyPack.updatedAt = .now

        do {
            try modelContext.save()
            ActionNotificationScheduler.cancel(for: actionID)
            dismiss()
        } catch {
            alertContent = RRAlertContent(
                title: "Action not deleted",
                message: "This action could not be deleted. Please try again."
            )
        }
    }
}
