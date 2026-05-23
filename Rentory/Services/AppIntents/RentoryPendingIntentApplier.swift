//
//  RentoryPendingIntentApplier.swift
//  Rentory
//
//  Drains the App Group pending-intent queue and applies each envelope
//  to SwiftData. Called from RootView on scene-active so any intents
//  triggered while the app was suspended land as real records the next
//  time the user opens the app. Mirrors the WatchPendingReminderApplier
//  pattern so the iPhone has one consistent shape for "background
//  source asked us to write this — please make it real".
//

import Foundation
import SwiftData

@MainActor
enum RentoryPendingIntentApplier {
    /// Reads every queued envelope, applies the ones we can resolve to
    /// an existing PropertyPack, saves the context once, and clears the
    /// applied envelopes from the queue. Envelopes whose property no
    /// longer exists are dropped (the user must have deleted the
    /// record between queuing and launch) — we don't keep them around
    /// to avoid an unbounded queue of dead refs.
    @discardableResult
    static func applyAll(in context: ModelContext) -> Int {
        let envelopes = RentoryPendingIntentStore.readAll()
        guard !envelopes.isEmpty else { return 0 }

        var applied: Set<UUID> = []
        var didChange = false

        for envelope in envelopes {
            switch envelope.payload {
            case .addReminder(let propertyID, let title, let dueDate, let createdAt):
                if applyReminder(propertyID: propertyID, title: title, dueDate: dueDate, createdAt: createdAt, in: context) {
                    didChange = true
                }
                applied.insert(envelope.id)

            case .logRentPayment(let propertyID, let amount, let paidDate, let currencyCode, _):
                if applyRentPayment(propertyID: propertyID, amount: amount, paidDate: paidDate, currencyCode: currencyCode, in: context) {
                    didChange = true
                }
                applied.insert(envelope.id)
            }
        }

        if didChange {
            try? context.save()
            RentorySnapshotPublisher.requestRepublish()
        }

        try? RentoryPendingIntentStore.remove(ids: applied)
        return applied.count
    }

    // MARK: - Per-kind appliers

    private static func applyReminder(
        propertyID: UUID,
        title: String,
        dueDate: Date?,
        createdAt: Date,
        in context: ModelContext
    ) -> Bool {
        guard let pack = fetchPropertyPack(id: propertyID, in: context) else { return false }
        let reminder = Reminder(
            title: title,
            dueDate: dueDate,
            kind: .custom,
            priority: .normal,
            createdAt: createdAt
        )
        pack.reminders.append(reminder)
        pack.updatedAt = .now
        RentoryActivityLog.record(
            kind: .record,
            title: "Reminder added via shortcut",
            message: "“\(title)” attached to \(pack.nickname)."
        )
        return true
    }

    private static func applyRentPayment(
        propertyID: UUID,
        amount: Double,
        paidDate: Date,
        currencyCode: String,
        in context: ModelContext
    ) -> Bool {
        guard let pack = fetchPropertyPack(id: propertyID, in: context) else { return false }
        // We attach the payment to the most-recent tenancy on the
        // property — that matches what the user means when they say
        // "log a rent payment in Rentory": the active arrangement.
        let tenancy = pack.tenancies
            .sorted(by: { $0.createdAt > $1.createdAt })
            .first
        guard let tenancy else { return false }

        let payment = RentPayment(
            dueDate: paidDate,
            paidDate: paidDate,
            amount: amount,
            currencyCode: currencyCode,
            status: .paid,
            notes: "Logged via Siri / Shortcuts"
        )
        tenancy.rentPayments.append(payment)
        pack.updatedAt = .now
        RentoryActivityLog.record(
            kind: .record,
            title: "Rent payment logged via shortcut",
            message: "\(formatted(amount: amount, currencyCode: currencyCode)) on \(pack.nickname)."
        )
        return true
    }

    private static func fetchPropertyPack(id: UUID, in context: ModelContext) -> PropertyPack? {
        let descriptor = FetchDescriptor<PropertyPack>(predicate: #Predicate { $0.id == id })
        return (try? context.fetch(descriptor))?.first
    }

    private static func formatted(amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }
}
