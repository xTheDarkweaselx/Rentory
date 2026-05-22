//
//  WatchDeepLinkRouter.swift  (RentoryWatch target)
//  Rentory
//
//  Translates complication taps into a pendingPropertyID + tab switch
//  for the watch UI. Mirrors the iOS RentoryDeepLinkRouter contract so
//  the URL grammar stays in sync (rentory://property/<UUID>).
//

import Combine
import Foundation

@MainActor
final class WatchDeepLinkRouter: ObservableObject {
    /// The Records tab is index 1; the Reminders tab is 0; Quick Add is 2.
    /// Setting `targetTab` switches the tab on the next render; the
    /// `@AppStorage("rentory.watch.selectedTab")` binding in ContentView
    /// picks it up via the helper hook below.
    @Published var targetTab: Int?

    /// Property the records tab should push to once it's visible.
    /// PropertyListView consumes via `.onReceive` and clears it.
    @Published var pendingPropertyID: UUID?

    func handle(_ url: URL) {
        guard url.scheme?.lowercased() == "rentory" else { return }
        guard let host = url.host?.lowercased() else { return }
        guard let uuid = UUID(uuidString: url.lastPathComponent) else { return }

        switch host {
        case "property", "record":
            targetTab = 1
            pendingPropertyID = uuid
        case "reminder":
            // We don't currently have a reminder detail addressable by
            // its own UUID on the watch — the row IDs match snapshot
            // entries, not Reminder UUIDs. Jumping to the Reminders tab
            // is the best we can do here.
            targetTab = 0
        default:
            break
        }
    }

    func clearPendingTab() {
        targetTab = nil
    }

    func clearPendingPropertyID() {
        pendingPropertyID = nil
    }
}
