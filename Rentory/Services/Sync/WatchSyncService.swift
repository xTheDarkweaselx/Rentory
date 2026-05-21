//
//  WatchSyncService.swift
//  Rentory
//
//  iOS side of the watch bridge. Ships the latest shared snapshot to
//  the paired Apple Watch via WCSession.updateApplicationContext (the
//  "latest-only, guaranteed delivery" channel — cheap to call on every
//  publish), and accepts quick-add reminders the watch queues back via
//  transferUserInfo.
//
//  Stays local-first: nothing leaves the device pair. If no watch is
//  paired or the session isn't reachable, calls are no-ops.
//
//  WatchConnectivity is only available on iOS (and watchOS). The main
//  Rentory target also builds for macOS and visionOS, where the
//  framework is absent — there we compile a no-op stub so the rest of
//  the app keeps building. Watch features are inherently
//  iPhone-paired, so no user-facing capability is lost on those
//  platforms.
//

import Foundation
import Combine
import SwiftData

struct PendingReminderPayload: Codable, Equatable {
    let id: UUID
    let propertyID: UUID
    let title: String
    let dueDate: Date
    let createdAt: Date
}

#if canImport(WatchConnectivity)
import WatchConnectivity

@MainActor
final class WatchSyncService: NSObject, ObservableObject {
    @Published private(set) var isWatchAppInstalled: Bool = false
    @Published private(set) var isReachable: Bool = false
    @Published private(set) var lastSendError: String?

    private let session: WCSession?
    private var pendingReminderHandler: ((PendingReminderPayload) -> Void)?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    /// Last snapshot we tried (or were unable) to send. Used to retry
    /// once the session activates if `send(_:)` was called during the
    /// cold-launch window before WCSession finished activating.
    private var pendingSnapshot: RentorySharedSnapshot?

    override init() {
        if WCSession.isSupported() {
            self.session = WCSession.default
        } else {
            self.session = nil
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
        super.init()
        activateIfNeeded()
    }

    /// Provide a callback the service will invoke whenever a pending
    /// reminder arrives from the watch. Called on the main actor.
    func setPendingReminderHandler(_ handler: @escaping (PendingReminderPayload) -> Void) {
        self.pendingReminderHandler = handler
    }

    /// Push the latest snapshot to the watch. Idempotent and cheap;
    /// safe to call from every snapshot publish.
    func send(_ snapshot: RentorySharedSnapshot) {
        // Always retain the most recent snapshot so a cold-launch publish
        // that lands before the session activates can be replayed once
        // activationDidCompleteWith fires.
        pendingSnapshot = snapshot

        guard let session else { return }
        guard session.activationState == .activated else { return }
        guard session.isPaired, session.isWatchAppInstalled else { return }
        do {
            let data = try encoder.encode(snapshot)
            try session.updateApplicationContext(["snapshot": data])
            lastSendError = nil
        } catch {
            lastSendError = error.localizedDescription
        }
    }

    private func resendPendingSnapshotIfNeeded() {
        guard let pendingSnapshot else { return }
        send(pendingSnapshot)
    }

    private func activateIfNeeded() {
        guard let session else { return }
        session.delegate = self
        if session.activationState != .activated {
            session.activate()
        }
        refreshState()
    }

    private func refreshState() {
        guard let session else { return }
        self.isWatchAppInstalled = session.isPaired && session.isWatchAppInstalled
        self.isReachable = session.isReachable
    }

    fileprivate func handleIncoming(_ payload: [String: Any]) {
        guard let kind = payload["kind"] as? String,
              kind == "pending-reminder",
              let data = payload["payload"] as? Data,
              let decoded = try? decoder.decode(PendingReminderPayload.self, from: data) else {
            return
        }
        Task { @MainActor in
            self.pendingReminderHandler?(decoded)
        }
    }
}

extension WatchSyncService: @preconcurrency WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.refreshState()
            if activationState == .activated {
                self.resendPendingSnapshotIfNeeded()
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            self.refreshState()
        }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            session.activate()
            self.refreshState()
        }
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.refreshState()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.refreshState()
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleIncoming(userInfo)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleIncoming(applicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncoming(message)
    }
}

#else

@MainActor
final class WatchSyncService: NSObject, ObservableObject {
    @Published private(set) var isWatchAppInstalled: Bool = false
    @Published private(set) var isReachable: Bool = false
    @Published private(set) var lastSendError: String?

    override init() {
        super.init()
    }

    func setPendingReminderHandler(_ handler: @escaping (PendingReminderPayload) -> Void) {
        _ = handler
    }

    func send(_ snapshot: RentorySharedSnapshot) {
        _ = snapshot
    }
}

#endif

/// Convert a watch-originated pending reminder into a persisted
/// Reminder on the paired PropertyPack. Returns the saved Reminder or
/// nil if the property could not be resolved.
@MainActor
enum WatchPendingReminderApplier {
    @discardableResult
    static func apply(_ payload: PendingReminderPayload, in context: ModelContext) -> Reminder? {
        let descriptor = FetchDescriptor<PropertyPack>(
            predicate: #Predicate { $0.id == payload.propertyID }
        )
        guard let pack = (try? context.fetch(descriptor))?.first else { return nil }

        let reminder = Reminder(
            id: payload.id,
            title: payload.title,
            dueDate: payload.dueDate,
            kind: .custom,
            priority: .normal,
            createdAt: payload.createdAt
        )
        pack.reminders.append(reminder)
        try? context.save()
        return reminder
    }
}
