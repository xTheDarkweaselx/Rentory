//
//  RentoryAppShortcuts.swift
//  Rentory
//
//  Surfaces the three app actions in the Shortcuts app and as Siri
//  suggestions. Phrases are intentionally short and natural — the long
//  multi-clause phrasings Apple's docs suggest don't transcribe well in
//  practice. Each shortcut is bound to its corresponding intent so a
//  user-built shortcut can chain them with other system actions.
//

import AppIntents

struct RentoryAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // AppIntents requires every utterance to contain the
        // `\(.applicationName)` macro — Apple uses it to route Siri's
        // speech recogniser at the right app. The phrases below all
        // include it, even where the natural sentence wouldn't, so the
        // build-time metadata exporter accepts them.
        AppShortcut(
            intent: AddReminderIntent(),
            phrases: [
                "Add a \(.applicationName) reminder",
                "Remind me in \(.applicationName)",
                "Save a reminder in \(.applicationName)"
            ],
            shortTitle: "Add reminder",
            systemImageName: "checklist"
        )

        AppShortcut(
            intent: OpenNextReminderIntent(),
            phrases: [
                "What's next in \(.applicationName)",
                "Next \(.applicationName) reminder",
                "Show my next \(.applicationName) action"
            ],
            shortTitle: "Next reminder",
            systemImageName: "calendar.badge.clock"
        )

        AppShortcut(
            intent: LogRentPaymentIntent(),
            phrases: [
                "Log rent in \(.applicationName)",
                "Record rent payment in \(.applicationName)",
                "Save a rent payment in \(.applicationName)"
            ],
            shortTitle: "Log rent",
            systemImageName: "sterlingsign.circle"
        )
    }
}
