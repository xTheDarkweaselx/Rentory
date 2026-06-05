//
//  CalendarMirrorService.swift
//  Rentory
//
//  Opt-in one-way mirror that writes Rentory reminders to a dedicated
//  "Rentory reminders" calendar in the user's Calendar database.
//
//  Access level: full calendar access (`requestFullAccessToEvents`,
//  iOS 17 / macOS 14+). Full access is required because the
//  reconciliation step below reads back the events Rentory itself
//  created in order to update and de-duplicate them — write-only
//  access cannot read events at all. Rentory only ever creates,
//  updates, or removes events in its own dedicated "Rentory reminders"
//  calendar; it never touches the user's other calendars.
//
//  Why one-way?
//    - Two-way sync needs change tokens, conflict rules, and a real
//      Calendar UI. We don't want to be a calendar app.
//    - One-way mirror is still useful: Rentory reminders surface in
//      Calendar, on the Watch face, and Apple's smart suggestions.
//    - Local-first stays intact — events live on-device and only
//      replicate to iCloud Calendar if the user already has it on.
//
//  Reconciliation model (idempotent):
//    - Compute the desired set of events from the current Reminder
//      records (one event per uncompleted reminder with a due date).
//    - Fetch all events in our dedicated calendar across the next
//      twelve months.
//    - For each desired event, upsert by reminderID stored in the
//      event's `notes` text using the marker
//      "[Rentory:<UUID>]".
//    - Remove any event in our calendar whose marker UUID doesn't
//      match a desired reminder.
//
//  Persistence:
//    - The calendar's identifier is stashed in UserDefaults so we
//      survive Calendar app deletions. If the stored id no longer
//      resolves we just create a fresh calendar.
//    - `isEnabledByUser` is a UserDefaults flag the Settings UI binds
//      against.
//

import Combine
import EventKit
import Foundation
import SwiftData
import SwiftUI

@MainActor
final class CalendarMirrorService: ObservableObject {
    static let isEnabledStorageKey = "rentory.calendarMirror.enabled"
    static let storedCalendarIDKey = "rentory.calendarMirror.calendarIdentifier"
    static let calendarTitle = "Rentory reminders"

    private let eventStore: EKEventStore
    private let userDefaults: UserDefaults
    private let calendar: Calendar
    private let reminderIDMarker = "[Rentory:"

    @Published private(set) var authorizationStatus: EKAuthorizationStatus

    init(
        eventStore: EKEventStore = EKEventStore(),
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.eventStore = eventStore
        self.userDefaults = userDefaults
        self.calendar = calendar
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    var isEnabledByUser: Bool {
        get { userDefaults.bool(forKey: Self.isEnabledStorageKey) }
        set { userDefaults.set(newValue, forKey: Self.isEnabledStorageKey) }
    }

    /// Asks for full calendar access. The user sees a system prompt the
    /// first time; subsequent calls return the cached decision. Full
    /// access (rather than write-only) is required because
    /// `mirror(context:)` reads back the events it created in order to
    /// reconcile them — write-only access cannot read events.
    @discardableResult
    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            return granted
        } catch {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            return false
        }
    }

    /// Reconciles the dedicated calendar against the current reminders
    /// in the SwiftData store. Cheap to call — quietly no-ops when the
    /// toggle is off or permission isn't granted. Designed to be safe
    /// to call on every scene-active and after every reminder save.
    func mirror(context: ModelContext) async {
        guard isEnabledByUser else { return }
        let status = EKEventStore.authorizationStatus(for: .event)
        // Full access is required: the reconciliation below reads existing
        // events to upsert and de-duplicate them, which write-only access
        // cannot do. `.authorized` is the pre-iOS 17 spelling of the same
        // full-access grant, accepted here for older systems.
        guard status == .fullAccess || status == .authorized else { return }

        guard let calendar = ensureDedicatedCalendar() else { return }

        let reminders = (try? context.fetch(FetchDescriptor<Reminder>())) ?? []
        let activeReminders = reminders.filter { reminder in
            reminder.completedAt == nil && reminder.dueDate != nil
        }

        do {
            let predicate = predicateForDedicatedCalendarWindow(eventStore: eventStore, calendar: calendar)
            let existingEvents = eventStore.events(matching: predicate)
                .filter { $0.calendar.calendarIdentifier == calendar.calendarIdentifier }

            // Bucket existing events by the reminderID embedded in
            // their notes so we can upsert without duplicates.
            var existingByID: [UUID: EKEvent] = [:]
            var orphaned: [EKEvent] = []
            for event in existingEvents {
                if let id = parseReminderID(from: event.notes) {
                    existingByID[id] = event
                } else {
                    orphaned.append(event)
                }
            }

            let desiredIDs = Set(activeReminders.map(\.id))

            // Update / create.
            for reminder in activeReminders {
                guard let dueDate = reminder.dueDate else { continue }
                let event = existingByID[reminder.id] ?? EKEvent(eventStore: eventStore)
                event.calendar = calendar
                event.title = reminder.title
                event.startDate = self.calendar.startOfDay(for: dueDate)
                event.endDate = self.calendar.date(byAdding: .day, value: 1, to: event.startDate) ?? event.startDate
                event.isAllDay = true
                event.notes = makeNotes(for: reminder)
                try? eventStore.save(event, span: .thisEvent, commit: false)
            }

            // Drop events whose reminderID no longer exists, plus any
            // orphans we couldn't tag back to a reminder.
            for (id, event) in existingByID where !desiredIDs.contains(id) {
                try? eventStore.remove(event, span: .thisEvent, commit: false)
            }
            for event in orphaned {
                try? eventStore.remove(event, span: .thisEvent, commit: false)
            }

            try? eventStore.commit()
        }
    }

    /// Disables the mirror and removes the dedicated calendar (and
    /// everything inside it). Called from Settings when the user
    /// flips the toggle off.
    func disableAndCleanup() {
        isEnabledByUser = false
        guard let calendar = resolveStoredCalendar() else { return }
        try? eventStore.removeCalendar(calendar, commit: true)
        userDefaults.removeObject(forKey: Self.storedCalendarIDKey)
    }

    // MARK: - Calendar discovery / creation

    private func ensureDedicatedCalendar() -> EKCalendar? {
        if let resolved = resolveStoredCalendar() {
            return resolved
        }

        // Create a fresh calendar bound to the user's default
        // calendar source. Local source when available; iCloud
        // source otherwise. Falls back to defaultCalendarForNewEvents
        // when no writable source exists.
        guard let source = preferredCalendarSource() else { return nil }
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = Self.calendarTitle
        calendar.source = source
        do {
            try eventStore.saveCalendar(calendar, commit: true)
            userDefaults.set(calendar.calendarIdentifier, forKey: Self.storedCalendarIDKey)
            return calendar
        } catch {
            return nil
        }
    }

    private func resolveStoredCalendar() -> EKCalendar? {
        guard let identifier = userDefaults.string(forKey: Self.storedCalendarIDKey) else { return nil }
        return eventStore.calendar(withIdentifier: identifier)
    }

    private func preferredCalendarSource() -> EKSource? {
        // Local first — keeps mirroring strictly device-local. Falls
        // back to iCloud if local isn't writable (rare on iOS but the
        // simulator sometimes ships without a local source).
        if let local = eventStore.sources.first(where: { $0.sourceType == .local }) {
            return local
        }
        if let cloud = eventStore.sources.first(where: { $0.sourceType == .calDAV && $0.title.contains("iCloud") }) {
            return cloud
        }
        return eventStore.defaultCalendarForNewEvents?.source
    }

    // MARK: - Reminder ID marker plumbing

    /// Twelve-month window — wide enough to cover yearly recurring
    /// reminders, narrow enough not to scan years of unrelated events.
    private func predicateForDedicatedCalendarWindow(eventStore: EKEventStore, calendar: EKCalendar) -> NSPredicate {
        let now = Date()
        let oneYearOut = self.calendar.date(byAdding: .year, value: 1, to: now) ?? now
        let oneMonthBack = self.calendar.date(byAdding: .month, value: -1, to: now) ?? now
        return eventStore.predicateForEvents(withStart: oneMonthBack, end: oneYearOut, calendars: [calendar])
    }

    private func makeNotes(for reminder: Reminder) -> String {
        Self.makeNotes(body: reminder.notes, reminderID: reminder.id)
    }

    private func parseReminderID(from notes: String?) -> UUID? {
        Self.parseReminderID(from: notes)
    }

    // MARK: - Pure helpers (exposed for tests)

    /// Builds the notes string Rentory writes onto each mirrored
    /// event. The marker is appended on its own line so the user's
    /// reminder notes remain readable and can be edited inside iOS
    /// Calendar without breaking the round-trip.
    nonisolated static func makeNotes(body: String?, reminderID: UUID) -> String {
        let marker = "[Rentory:\(reminderID.uuidString)]"
        guard let body, !body.isEmpty else { return marker }
        return "\(body)\n\n\(marker)"
    }

    /// Extracts the Rentory reminder UUID embedded in an event's
    /// notes. Returns nil for notes that don't carry our marker, so
    /// the reconciler can drop orphans cleanly.
    nonisolated static func parseReminderID(from notes: String?) -> UUID? {
        guard let notes else { return nil }
        guard let openRange = notes.range(of: "[Rentory:") else { return nil }
        let after = notes[openRange.upperBound...]
        guard let closeIndex = after.firstIndex(of: "]") else { return nil }
        return UUID(uuidString: String(after[..<closeIndex]))
    }
}
