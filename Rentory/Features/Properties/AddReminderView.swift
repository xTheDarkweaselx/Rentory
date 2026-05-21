//
//  AddReminderView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 17/05/2026.
//

import SwiftData
import SwiftUI

struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var reminderNotificationService: ReminderNotificationService
    @AppStorage(RentoryUserProfile.storageKey) private var profileRawValue = RentoryUserProfile.defaultProfile.rawValue
    /// Once-per-user gate so the inline notifications offer only fires
    /// the first time the user saves a reminder, not on every subsequent
    /// add. Stored in user defaults via @AppStorage.
    @AppStorage("rentory.hasOfferedNotificationsAfterFirstReminder") private var hasOfferedNotificationsPrompt = false

    let propertyPack: PropertyPack

    private var profile: RentoryUserProfile {
        RentoryUserProfile(rawValue: profileRawValue) ?? .defaultProfile
    }

    @State private var title = ""
    @State private var notes = ""
    @State private var kind: ReminderKind = .custom
    @State private var priority: ReminderPriority = .normal
    @State private var hasDueDate = true
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var validationMessage: String?
    @State private var alertContent: RRAlertContent?
    @State private var isShowingNotificationOffer = false

    var body: some View {
        NavigationStack {
            ZStack {
                RRBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Add reminder",
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
                                        ForEach(ReminderKind.availableCases(for: profile), id: \.self) { kind in
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
                                        ForEach(ReminderPriority.allCases, id: \.self) { priority in
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
            .navigationTitle("Add reminder")
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
        .confirmationDialog(
            "Get notified when a reminder is due?",
            isPresented: $isShowingNotificationOffer,
            titleVisibility: .visible
        ) {
            Button("Turn on notifications") {
                acceptNotificationOffer()
            }
            Button("Not now", role: .cancel) {
                declineNotificationOffer()
            }
        } message: {
            Text("Rentory can send a heads-up at 9 am on the day a reminder is due. Notifications are scheduled locally — never through a server.")
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

        let reminder = Reminder(
            title: trimmedTitle,
            notes: optionalText(notes),
            dueDate: hasDueDate ? dueDate : nil,
            kind: kind,
            priority: priority
        )

        propertyPack.reminders.append(reminder)
        propertyPack.updatedAt = .now

        do {
            try modelContext.save()
            RentorySnapshotPublisher.requestRepublish()
            Task { await reminderNotificationService.reschedule(context: modelContext) }

            // If this looks like the user's first reminder AND they haven't
            // been offered notifications yet AND iOS hasn't already
            // declined for them, surface a one-shot inline offer before
            // dismissing. Otherwise dismiss immediately.
            if shouldOfferNotifications {
                isShowingNotificationOffer = true
            } else {
                dismiss()
            }
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeSaved)
        }
    }

    /// We only ask once per user (`hasOfferedNotificationsPrompt`) and we
    /// don't ask if the user has already opted in elsewhere or iOS denied
    /// the permission previously (re-asking from a different surface is
    /// pointless — iOS will silently no-op).
    private var shouldOfferNotifications: Bool {
        guard !hasOfferedNotificationsPrompt else { return false }
        guard !reminderNotificationService.isEnabledByUser else { return false }
        let status = reminderNotificationService.authorizationStatus
        return status != .denied
    }

    private func acceptNotificationOffer() {
        Task {
            reminderNotificationService.isEnabledByUser = true
            _ = await reminderNotificationService.requestAuthorization()
            await reminderNotificationService.reschedule(context: modelContext)
            hasOfferedNotificationsPrompt = true
            dismiss()
        }
    }

    private func declineNotificationOffer() {
        hasOfferedNotificationsPrompt = true
        dismiss()
    }
}
