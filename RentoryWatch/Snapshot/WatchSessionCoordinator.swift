//
//  WatchSessionCoordinator.swift  (RentoryWatch target)
//  Rentory
//
//  Owns the watchOS side of the WatchConnectivity bridge. Activates the
//  default WCSession on launch, listens for incoming snapshot messages /
//  application context, decodes them, and hands them to
//  WatchSnapshotStore.shared.apply(_:).
//
//  Three transport channels are accepted, in order of preference:
//    - userInfo (FIFO, guaranteed delivery, large payloads OK)
//    - applicationContext (latest-only, also guaranteed)
//    - message (live, only when companion + watch are both active)
//
//  The Watch never pushes data back at the iPhone; it's read-only.
//

import Foundation
import Combine
import WatchConnectivity

@MainActor
final class WatchSessionCoordinator: NSObject, ObservableObject {
    static let shared = WatchSessionCoordinator()

    @Published private(set) var isReachable: Bool = false
    @Published private(set) var activationState: WCSessionActivationState = .notActivated
    /// Reminder UUIDs the iPhone has confirmed it persisted. The
    /// QuickAdd view observes this and decrements its local "Queued
    /// to iPhone (N waiting)" counter when an ID it tracked lands.
    @Published private(set) var confirmedReminderIDs: Set<UUID> = []

    private let session: WCSession?

    private override init() {
        if WCSession.isSupported() {
            self.session = WCSession.default
        } else {
            self.session = nil
        }
        super.init()
        guard let session else { return }
        session.delegate = self
        session.activate()
        self.isReachable = session.isReachable
        self.activationState = session.activationState
        consumeReceivedApplicationContextIfAvailable()
    }

    func requestRefresh() {
        guard let session, session.isReachable else { return }
        session.sendMessage(["request": "snapshot"], replyHandler: nil, errorHandler: nil)
    }

    private func consumeReceivedApplicationContextIfAvailable() {
        guard let session else { return }
        let context = session.receivedApplicationContext
        applyIfSnapshot(context)
    }

    private func applyIfSnapshot(_ payload: [String: Any]) {
        guard let data = payload["snapshot"] as? Data else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(RentorySharedSnapshot.self, from: data) else { return }
        Task { @MainActor in
            WatchSnapshotStore.shared.apply(snapshot)
        }
    }

    /// Handles `{ "kind": "confirmed-reminder", "id": "<uuid>" }`
    /// payloads sent back by the iPhone after it persists a pending
    /// reminder. Records the ID so the QuickAdd view can decrement
    /// its local pending counter. We retain a small recent history
    /// rather than firing-and-forgetting so a view that mounts a tick
    /// late still sees the confirmation.
    private func recordConfirmationIfPresent(_ payload: [String: Any]) {
        guard payload["kind"] as? String == "confirmed-reminder",
              let raw = payload["id"] as? String,
              let uuid = UUID(uuidString: raw) else { return }
        Task { @MainActor in
            self.confirmedReminderIDs.insert(uuid)
        }
    }

    /// Called by the QuickAdd view after it has consumed a confirmed
    /// ID so the set doesn't grow unbounded.
    func consumeConfirmation(for id: UUID) {
        confirmedReminderIDs.remove(id)
    }
}

extension WatchSessionCoordinator: @preconcurrency WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.activationState = activationState
            self.isReachable = session.isReachable
            self.consumeReceivedApplicationContextIfAvailable()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        applyIfSnapshot(applicationContext)
        recordConfirmationIfPresent(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        applyIfSnapshot(userInfo)
        recordConfirmationIfPresent(userInfo)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        applyIfSnapshot(message)
        recordConfirmationIfPresent(message)
    }
}
