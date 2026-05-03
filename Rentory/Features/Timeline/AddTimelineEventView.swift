//
//  AddTimelineEventView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 01/05/2026.
//

import SwiftData
import SwiftUI

struct AddTimelineEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let propertyPack: PropertyPack

    @State private var title = ""
    @State private var eventType: TimelineEventType = .other
    @State private var eventDate = Date()
    @State private var notes = ""
    @State private var includeInReport = true
    @State private var validationMessage: String?
    @State private var alertContent: RRAlertContent?

    var body: some View {
        NavigationStack {
            RRMacSheetContainer {
                Form {
                    Section {
                        RRSheetHeader(
                            title: "Add event",
                            subtitle: "Keep useful dates, updates and notes together in your record.",
                            systemImage: "calendar.badge.plus"
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        if let validationMessage {
                            Text(validationMessage)
                                .font(RRTypography.footnote)
                                .foregroundStyle(RRColours.danger)
                        }
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
                }
                .navigationTitle("Add event")
                .rrInlineNavigationTitle()
                .scrollContentBackground(.hidden)
                .background(RRBackgroundView())
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .rrPrimaryAction) {
                        Button("Save") {
                            saveEvent()
                        }
                    }
                }
            }
        }
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
    }

    private func saveEvent() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            validationMessage = "Add an event title to continue."
            return
        }

        let event = TimelineEvent(
            title: trimmedTitle,
            type: eventType,
            eventDate: eventDate,
            notes: optionalText(notes),
            includeInExport: includeInReport
        )

        propertyPack.timelineEvents.append(event)
        propertyPack.updatedAt = .now

        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeSaved)
        }
    }
}
