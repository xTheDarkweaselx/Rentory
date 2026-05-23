//
//  RentoryPendingIntentStore.swift
//  Rentory
//
//  Tiny append-only queue persisted in the App Group container that
//  background AppIntents drop their captured payloads into. The main
//  app drains the queue on next launch (see
//  `RentoryPendingIntentApplier`) and translates each entry into the
//  matching SwiftData write. The intent process therefore never touches
//  SwiftData directly — it just writes a tiny JSON record — which keeps
//  the local-first contract intact and dodges all the ModelContainer
//  isolation pain you get when AppIntents try to share the app's store.
//
//  File layout in the App Group container:
//    Library/Rentory/pending-intents.json   (an array of envelopes)
//
//  Concurrency: AppIntents run in a separate process, so two intents
//  firing quickly could otherwise stomp on each other. We use a
//  cooperative file lock by reading + appending + writing inside a
//  `NSFileCoordinator` block.
//

import Foundation

/// Payload shapes for intents that can't write SwiftData themselves.
/// Each case captures the minimum data needed to recreate the user's
/// action when the app launches.
nonisolated enum RentoryPendingIntent: Codable, Equatable {
    case addReminder(propertyID: UUID, title: String, dueDate: Date?, createdAt: Date)
    case logRentPayment(propertyID: UUID, amount: Double, paidDate: Date, currencyCode: String, createdAt: Date)
}

/// Envelope wrapping each pending intent with an id and timestamp so
/// the applier can sort and dedupe.
nonisolated struct RentoryPendingIntentEnvelope: Codable, Equatable, Identifiable {
    let id: UUID
    let queuedAt: Date
    let payload: RentoryPendingIntent
}

// Whole queue is `nonisolated` — AppIntents (which run in a separate
// nonisolated process) need to enqueue from any actor context. Pure
// filesystem I/O against an App Group container; no shared state.
nonisolated enum RentoryPendingIntentStore {
    static let appGroupIdentifier = "group.com.fusionstudios.rentory"
    static let queueRelativePath = "Library/Rentory/pending-intents.json"

    /// Append a new envelope onto the queue. Safe to call from any
    /// process; uses NSFileCoordinator to serialise reads + writes
    /// across the app and the intent extension.
    static func enqueue(_ payload: RentoryPendingIntent) throws {
        let envelope = RentoryPendingIntentEnvelope(id: UUID(), queuedAt: .now, payload: payload)
        try mutate { existing in
            existing.append(envelope)
        }
    }

    /// Returns the queued envelopes in queued-at order. Doesn't clear
    /// the queue — call `clearAll(matching:)` after a successful apply.
    static func readAll() -> [RentoryPendingIntentEnvelope] {
        guard let url = queueURL() else { return [] }
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var result: [RentoryPendingIntentEnvelope] = []
        var coordinatorError: NSError?
        coordinator.coordinate(readingItemAt: url, options: [], error: &coordinatorError) { coordinatedURL in
            guard let data = try? Data(contentsOf: coordinatedURL) else { return }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let envelopes = try? decoder.decode([RentoryPendingIntentEnvelope].self, from: data) {
                result = envelopes
            }
        }
        return result
    }

    /// Removes the envelopes whose ids match the supplied set. Used by
    /// the applier after it's translated each one into a SwiftData
    /// write so we don't process the same entry twice.
    static func remove(ids: Set<UUID>) throws {
        guard !ids.isEmpty else { return }
        try mutate { existing in
            existing.removeAll { ids.contains($0.id) }
        }
    }

    // MARK: - Private

    /// Locates the App Group container's queue file URL. Returns nil
    /// when the App Group entitlement is missing (e.g. on a simulator
    /// build that hasn't been signed with the group), in which case
    /// enqueueing silently no-ops so we don't crash Siri.
    private static func queueURL() -> URL? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            return nil
        }
        let url = container.appendingPathComponent(queueRelativePath, isDirectory: false)
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        return url
    }

    /// Read-modify-write block coordinated by NSFileCoordinator so two
    /// processes don't clobber each other. The mutator receives the
    /// current array (possibly empty) and may modify it in place.
    private static func mutate(_ mutator: (inout [RentoryPendingIntentEnvelope]) -> Void) throws {
        guard let url = queueURL() else { return }
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinatorError: NSError?
        var thrown: Error?
        coordinator.coordinate(writingItemAt: url, options: [], error: &coordinatorError) { coordinatedURL in
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            var envelopes: [RentoryPendingIntentEnvelope] = []
            if let data = try? Data(contentsOf: coordinatedURL),
               let decoded = try? decoder.decode([RentoryPendingIntentEnvelope].self, from: data) {
                envelopes = decoded
            }

            mutator(&envelopes)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            do {
                let data = try encoder.encode(envelopes)
                try data.write(to: coordinatedURL, options: [.atomic])
            } catch {
                thrown = error
            }
        }
        if let coordinatorError {
            throw coordinatorError
        }
        if let thrown {
            throw thrown
        }
    }
}
