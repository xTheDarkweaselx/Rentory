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
            ZStack {
                RRBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Add event",
                            subtitle: "Keep useful dates, updates and notes together in your record.",
                            systemImage: "calendar.badge.plus"
                        )

                        if let validationMessage {
                            validationCard(validationMessage)
                        }

                        RRGlassPanel {
                            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                                RRSectionHeader(
                                    title: "Event details",
                                    subtitle: "Add the date and the kind of update you want to remember."
                                )

                                VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                                    Text("Event title")
                                        .font(RRTypography.footnote.weight(.semibold))
                                        .foregroundStyle(RRColours.mutedText)

                                    TextField("Event title", text: $title)
                                        .textFieldStyle(.roundedBorder)
                                        .rrTextInputAutocapitalizationWords()
                                }

                                VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                                    Text("Type")
                                        .font(RRTypography.footnote.weight(.semibold))
                                        .foregroundStyle(RRColours.mutedText)

                                    Picker("Type", selection: $eventType) {
                                        ForEach(TimelineEventType.allCases, id: \.self) { type in
                                            Text(type.rawValue).tag(type)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }

                                DatePicker("Date", selection: $eventDate, displayedComponents: .date)
                            }
                        }

                        RRGlassPanel {
                            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                                RRSectionHeader(title: "Notes and report")

                                TextField("Add a short note", text: $notes, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...6)

                                Toggle("Include in report", isOn: $includeInReport)
                                    .tint(RRColours.secondary)
                            }
                        }

                        if !PlatformLayout.isMac {
                            RRGlassPanel {
                                ViewThatFits(in: .horizontal) {
                                    HStack(spacing: RRTheme.controlSpacing) {
                                        Spacer()
                                        actionButtons
                                    }

                                    VStack(spacing: RRTheme.controlSpacing) {
                                        actionButtons
                                    }
                                }
                            }
                            .tint(RRColours.secondary)
                        }
                    }
                    .frame(maxWidth: PlatformLayout.preferredDialogWidth, alignment: .leading)
                    .padding(RRTheme.screenPadding)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Add event")
            .rrInlineNavigationTitle()
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
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
    }

    private var actionButtons: some View {
        Group {
            RRSecondaryButton(title: "Cancel") {
                dismiss()
            }
            .frame(maxWidth: PlatformLayout.prefersFooterButtons ? 150 : .infinity)

            RRPrimaryButton(title: "Save event") {
                saveEvent()
            }
            .frame(maxWidth: PlatformLayout.prefersFooterButtons ? 150 : .infinity)
        }
    }

    private func validationCard(_ message: String) -> some View {
        RRGlassPanel {
            Text(message)
                .font(RRTypography.footnote.weight(.semibold))
                .foregroundStyle(RRColours.danger)
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
