//
//  AddActionView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 17/05/2026.
//

import SwiftData
import SwiftUI

struct AddActionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(RentoryUserProfile.storageKey) private var profileRawValue = RentoryUserProfile.defaultProfile.rawValue

    let propertyPack: PropertyPack

    private var profile: RentoryUserProfile {
        RentoryUserProfile(rawValue: profileRawValue) ?? .defaultProfile
    }

    @State private var title = ""
    @State private var notes = ""
    @State private var kind: ActionKind = .custom
    @State private var priority: ActionPriority = .normal
    @State private var hasDueDate = true
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var validationMessage: String?
    @State private var alertContent: RRAlertContent?

    var body: some View {
        NavigationStack {
            ZStack {
                RRBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Add action",
                            subtitle: "Track something that needs doing — a repair to chase, an inspection to attend, a date to remember.",
                            systemImage: "checklist"
                        )

                        if let validationMessage {
                            RRGlassPanel {
                                Text(validationMessage)
                                    .font(RRTypography.footnote.weight(.semibold))
                                    .foregroundStyle(RRColours.danger)
                            }
                        }

                        RRGlassPanel {
                            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                                RRSectionHeader(
                                    title: "Action details",
                                    subtitle: "What needs doing, and when?"
                                )

                                VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                                    Text("Title")
                                        .font(RRTypography.footnote.weight(.semibold))
                                        .foregroundStyle(RRColours.mutedText)

                                    TextField("Action title", text: $title)
                                        .textFieldStyle(.roundedBorder)
                                        .rrTextInputAutocapitalizationWords()
                                }

                                VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                                    Text("Kind")
                                        .font(RRTypography.footnote.weight(.semibold))
                                        .foregroundStyle(RRColours.mutedText)

                                    Picker("Kind", selection: $kind) {
                                        ForEach(ActionKind.availableCases(for: profile), id: \.self) { kind in
                                            Text(kind.rawValue).tag(kind)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }

                                VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                                    Text("Priority")
                                        .font(RRTypography.footnote.weight(.semibold))
                                        .foregroundStyle(RRColours.mutedText)

                                    Picker("Priority", selection: $priority) {
                                        ForEach(ActionPriority.allCases, id: \.self) { priority in
                                            Text(priority.rawValue).tag(priority)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }

                                Toggle("Has a due date", isOn: $hasDueDate)
                                    .tint(RRColours.secondary)

                                if hasDueDate {
                                    DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                                }
                            }
                        }

                        RRGlassPanel {
                            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                                RRSectionHeader(title: "Notes")

                                TextField("Add a short note (optional)", text: $notes, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...6)
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
            .navigationTitle("Add action")
            .rrInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .rrPrimaryAction) {
                    Button("Save") {
                        saveAction()
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

            RRPrimaryButton(title: "Save action") {
                saveAction()
            }
            .frame(maxWidth: PlatformLayout.prefersFooterButtons ? 150 : .infinity)
        }
    }

    private func saveAction() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            validationMessage = "Add an action title to continue."
            return
        }

        let action = ActionItem(
            title: trimmedTitle,
            notes: optionalText(notes),
            dueDate: hasDueDate ? dueDate : nil,
            kind: kind,
            priority: priority
        )

        propertyPack.actions.append(action)
        propertyPack.updatedAt = .now

        do {
            try modelContext.save()
            Task { await ActionNotificationScheduler.scheduleOrCancel(for: action) }
            dismiss()
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeSaved)
        }
    }
}
