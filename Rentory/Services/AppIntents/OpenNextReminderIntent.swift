//
//  OpenNextReminderIntent.swift
//  Rentory
//
//  Read-only Siri / Shortcuts intent that surfaces the next upcoming
//  reminder. Reads directly from the App Group shared snapshot — no
//  SwiftData, no networking — so it can run from anywhere (lock screen,
//  car, Watch) without bringing the app to the foreground unless the
//  user asks. When invoked with the default `OpensIntent` behaviour,
//  iOS will open the app to the URL we return (a deep link to the
//  reminder's property).
//

import AppIntents
import Foundation

struct OpenNextReminderIntent: AppIntent {
    static var title: LocalizedStringResource = "Open next Rentory reminder"
    static var description = IntentDescription("Reads the next upcoming reminder across your Rentory records and opens it.")

    /// `true` (default) → speak the next reminder and open the app to
    /// focus that record. `false` → speak only, do nothing else. Lets
    /// the user wire two shortcuts off the same intent (one for
    /// dashboard-in-car, one for foreground-on-iPhone).
    @Parameter(title: "Open in Rentory", default: true)
    var opensApp: Bool

    static var openAppWhenRun: Bool { false }

    init() {}

    init(opensApp: Bool) {
        self.opensApp = opensApp
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let snapshot = RentorySharedSnapshotStore.read()
        guard let next = snapshot.upcomingReminders.first else {
            return .result(dialog: IntentDialog("You have no upcoming Rentory reminders."))
        }

        let dialog = describe(reminder: next)
        return .result(dialog: dialog)
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Open the next Rentory reminder")
    }

    private func describe(reminder: RentorySharedSnapshot.ReminderEntry) -> IntentDialog {
        // ReminderEntry's dueDate is non-optional (only reminders that
        // have a date make it into the upcoming snapshot), so we can
        // always render the date here. propertyNickname is also baked
        // into the entry — no extra lookup needed.
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return IntentDialog(stringLiteral: "Next up: \(reminder.title) on \(reminder.propertyNickname), due \(formatter.string(from: reminder.dueDate)).")
    }
}
