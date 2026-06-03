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
    // The store + session coordinator are app-lifetime singletons that own
    // themselves (see WatchSnapshotStore.shared / WatchSessionCoordinator.shared).
    // Injecting `.shared` directly into the environment lets every view
    // observe them through @EnvironmentObject without the @StateObject /
    // singleton double-retention anti-pattern.
    @StateObject private var deepLinkRouter = WatchDeepLinkRouter()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(WatchSnapshotStore.shared)
                .environmentObject(WatchSessionCoordinator.shared)
                .environmentObject(deepLinkRouter)
                .onOpenURL { url in
                    deepLinkRouter.handle(url)
                }
        }
    }
}
