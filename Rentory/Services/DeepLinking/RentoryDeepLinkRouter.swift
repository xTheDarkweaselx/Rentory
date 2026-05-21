//
//  RentoryDeepLinkRouter.swift
//  Rentory
//
//  Single place to translate widget taps and notification taps into a
//  property/reminder selection. Holds a one-shot `pendingPropertyID`
//  that the list / split view observes and consumes when it becomes
//  non-nil.
//
//  URL grammar (handled by .onOpenURL in RootView):
//    rentory://property/<UUID>   — focus this property
//    rentory://record/<UUID>     — alias for /property
//    rentory://reminder/<UUID>   — focus the reminder's property
//
//  Notifications carry `userInfo["reminderID"] = uuidString`; the
//  notification delegate translates that into the same router call so
//  every deep-link path shares one resolver.
//

import Foundation
import Combine

@MainActor
final class RentoryDeepLinkRouter: ObservableObject {
    /// Property the UI should select / push to when the next render
    /// happens. Consumers should call `clearPending()` after handling.
    @Published var pendingPropertyID: UUID?

    func handle(_ url: URL) {
        guard url.scheme?.lowercased() == "rentory" else { return }
        guard let host = url.host?.lowercased() else { return }
        let lastPath = url.lastPathComponent
        guard let uuid = UUID(uuidString: lastPath) else { return }

        switch host {
        case "property", "record":
            pendingPropertyID = uuid
        case "reminder":
            // Look up the reminder's property from the snapshot so we
            // can focus the right record. If we can't resolve it the
            // tap still opens the app (no-op).
            let snapshot = RentorySharedSnapshotStore.read()
            if let match = snapshot.upcomingReminders.first(where: { $0.id == uuid }) {
                pendingPropertyID = match.propertyID
            }
        default:
            break
        }
    }

    func handleNotificationUserInfo(_ userInfo: [AnyHashable: Any]) {
        guard let raw = userInfo["reminderID"] as? String,
              let uuid = UUID(uuidString: raw) else { return }
        let snapshot = RentorySharedSnapshotStore.read()
        if let match = snapshot.upcomingReminders.first(where: { $0.id == uuid }) {
            pendingPropertyID = match.propertyID
        }
    }

    func clearPending() {
        pendingPropertyID = nil
    }
}
