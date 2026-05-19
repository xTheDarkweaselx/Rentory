//
//  RentoryWatchApp.swift  (RentoryWatch target)
//  Rentory
//
//  Watch app entry point. Activates the WatchConnectivity coordinator
//  on launch so snapshot transfers from the paired iPhone are received
//  even before the user opens a specific view. Single-scene app —
//  ContentView owns the tab navigation.
//
//  No networking, no analytics. Mirrors the iPhone app's local-first
//  stance.
//

import SwiftUI

@main
struct RentoryWatchApp: App {
    @StateObject private var snapshotStore = WatchSnapshotStore.shared
    @StateObject private var session = WatchSessionCoordinator.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(snapshotStore)
                .environmentObject(session)
        }
    }
}
