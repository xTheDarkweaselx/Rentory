//
//  AddReminderIntent.swift
//  Rentory
//
//  Siri / Shortcuts entry point for queuing a new reminder on a Rentory
//  record. Runs as a background intent (doesn't open the app) and just
//  drops a payload into the shared App Group queue. The next time the
//  user opens Rentory, `RentoryPendingIntentApplier` reads the queue
//  and writes the actual Reminder via SwiftData. We keep the
//  intent-process work tiny because Apple gives intents a stricter
//  resource budget and SwiftData containers don't share cleanly across
//  processes — this lets us honour the "local-first, no networking"
//  rule without any platform tricks.
//

import AppIntents
import Foundation

struct AddReminderIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Rentory reminder"
    static var description = IntentDescription("Queue a reminder on one of your Rentory records. Saves locally — no networking — and shows up the next time you open the app.")

    @Parameter(title: "Record")
    var property: RentoryPropertyEntity

    @Parameter(title: "Title")
    var title: String

    @Parameter(title: "Due date", default: nil)
    var dueDate: Date?

    init() {}

    init(property: RentoryPropertyEntity, title: String, dueDate: Date? = nil) {
        self.property = property
        self.title = title
        self.dueDate = dueDate
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AddReminderIntentError.emptyTitle
        }

        let payload = RentoryPendingIntent.addReminder(
            propertyID: property.id,
            title: trimmed,
            dueDate: dueDate,
            createdAt: .now
        )

        try RentoryPendingIntentStore.enqueue(payload)

        let confirmation: String
        if let dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            confirmation = "Saved \(trimmed) on \(property.nickname) for \(formatter.string(from: dueDate))."
        } else {
            confirmation = "Saved \(trimmed) on \(property.nickname)."
        }
        return .result(dialog: IntentDialog(stringLiteral: confirmation))
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$title) to \(\.$property) for \(\.$dueDate)")
    }
}

enum AddReminderIntentError: Error, CustomLocalizedStringResourceConvertible {
    case emptyTitle

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .emptyTitle:
            return "Reminder title can't be empty."
        }
    }
}
