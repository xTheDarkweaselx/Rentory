//
//  AddReminderView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 17/05/2026.
//

import SwiftData
import SwiftUI
import UserNotifications

struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var reminderNotificationService: ReminderNotificationService
    @AppStorage(RentoryUserProfile.storageKey) private var profileRawValue = RentoryUserProfile.defaultProfile.rawValue
    /// Two-step gate on the notifications offer:
    ///   0 — never offered; show the inline dialog next time.
    ///   1 — user declined the dialog once; on the next reminder save
    ///       silently request .provisional permission so they at least
    ///       get quiet Notification-Center delivery without another
    ///       system dialog.
    ///   2 — we've done both paths; leave the user alone.
    @AppStorage("rentory.notificationsOfferStep") private var notificationsOfferStep = 0

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
    @State private var recurrence: ReminderRecurrence = .none
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

                                    VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                                        Text("Repeat")
                                            .font(RRTypography.footnote.weight(.semibold))
                                            .foregroundStyle(RRColours.mutedText)

                                        Picker("Repeat", selection: $recurrence) {
                                            ForEach(ReminderRecurrence.allCases) { rule in
                                                Text(rule.rawValue).tag(rule)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                    }
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
            priority: priority,
            // Recurrence is only meaningful when there's a due date —
            // otherwise the picker is hidden and the value is whatever
            // the user last selected before clearing the toggle.
            recurrence: hasDueDate ? recurrence : .none
        )

        propertyPack.reminders.append(reminder)
        propertyPack.updatedAt = .now

        do {
            try modelContext.save()
            RentorySnapshotPublisher.requestRepublish()
            RRHaptics.success()
            Task { await reminderNotificationService.reschedule(context: modelContext) }

            // Two-step nudge: dialog first time, silent provisional
            // permission second time, then stop. See notificationsOfferStep.
            if shouldShowNotificationDialog {
                isShowingNotificationOffer = true
            } else if shouldSilentlyRequestProvisional {
                Task {
                    await silentlyRequestProvisionalNotifications()
                    dismiss()
                }
            } else {
                dismiss()
            }
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeSaved)
        }
    }

    /// First-pass nudge: show the explicit confirmation dialog. Skipped
    /// if the user has already opted in elsewhere or iOS has hard-
    /// denied the permission (re-asking would just no-op in iOS).
    private var shouldShowNotificationDialog: Bool {
        guard notificationsOfferStep == 0 else { return false }
        guard !reminderNotificationService.isEnabledByUser else { return false }
        let status = reminderNotificationService.authorizationStatus
        return status != .denied
    }

    /// Second-pass nudge: after the user declined the dialog once, ask
    /// for `.provisional` silently on their next reminder save so they
    /// still get quiet Notification-Center delivery without seeing
    /// another system permission popup.
    private var shouldSilentlyRequestProvisional: Bool {
        guard notificationsOfferStep == 1 else { return false }
        guard !reminderNotificationService.isEnabledByUser else { return false }
        let status = reminderNotificationService.authorizationStatus
        return status == .notDetermined
    }

    private func acceptNotificationOffer() {
        Task {
            reminderNotificationService.isEnabledByUser = true
            _ = await reminderNotificationService.requestAuthorization()
            await reminderNotificationService.reschedule(context: modelContext)
            // Bump to 2 so we don't take the provisional path on the
            // next save — the user explicitly accepted, no more nudges.
            notificationsOfferStep = 2
            dismiss()
        }
    }

    private func declineNotificationOffer() {
        notificationsOfferStep = 1
        dismiss()
    }

    private func silentlyRequestProvisionalNotifications() async {
        let granted = await reminderNotificationService.requestProvisionalAuthorization()
        if granted {
            reminderNotificationService.isEnabledByUser = true
            await reminderNotificationService.reschedule(context: modelContext)
        }
        notificationsOfferStep = 2
    }
}
