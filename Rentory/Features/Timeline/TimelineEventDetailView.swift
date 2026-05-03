//
//  TimelineEventDetailView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI

struct TimelineEventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let event: TimelineEvent
    let propertyPack: PropertyPack

    @State private var title: String
    @State private var eventType: TimelineEventType
    @State private var eventDate: Date
    @State private var notes: String
    @State private var includeInReport: Bool
    @State private var alertContent: RRAlertContent?
    @State private var isShowingDeleteConfirmation = false

    init(event: TimelineEvent, propertyPack: PropertyPack) {
        self.event = event
        self.propertyPack = propertyPack
        _title = State(initialValue: event.title)
        _eventType = State(initialValue: event.eventType)
        _eventDate = State(initialValue: event.eventDate)
        _notes = State(initialValue: event.notes ?? "")
        _includeInReport = State(initialValue: event.includeInExport)
    }

    var body: some View {
        Form {
            Section {
                RRSheetHeader(
                    title: "Edit event",
                    subtitle: "Keep the details clear and easy to review later.",
                    systemImage: "calendar"
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Event") {
                TextField("Event title", text: $title)
                    .rrTextInputAutocapitalizationWords()

                Picker("Type", selection: $eventType) {
                    ForEach(TimelineEventType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }

                DatePicker("Date", selection: $eventDate, displayedComponents: .date)
            }

            Section("Notes") {
                TextField("Add a short note", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Toggle("Include in report", isOn: $includeInReport)
            }

            Section {
                RRDestructiveButton(title: "Delete event") {
                    isShowingDeleteConfirmation = true
                }
            }
        }
        .navigationTitle(event.title)
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
        .rrConfirmationDialog(DialogCopy.deleteTimelineEvent, isPresented: $isShowingDeleteConfirmation) {
            deleteEvent()
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
            alertContent = RRAlertContent(title: "Event not saved", message: "Add an event title to continue.")
            return
        }

        event.title = trimmedTitle
        event.eventType = eventType
        event.eventDate = eventDate
        event.notes = optionalText(notes)
        event.includeInExport = includeInReport
        propertyPack.updatedAt = .now

        do {
            try modelContext.save()
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeSaved)
        }
    }

    private func deleteEvent() {
        modelContext.delete(event)
        propertyPack.updatedAt = .now

        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertContent = RRAlertContent(
                title: "Event not deleted",
                message: "This event could not be deleted. Please try again."
            )
        }
    }
}
