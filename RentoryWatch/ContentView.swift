//
//  ContentView.swift  (RentoryWatch target)
//  Rentory
//
//  Top-level Watch navigation. Three tabs is the sweet spot — far
//  enough that the user can't accidentally swipe out of useful
//  content, narrow enough that the user always knows where they are.
//  Each tab is shallow (max one push); back-navigation is one swipe.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var snapshotStore: WatchSnapshotStore
    @EnvironmentObject private var deepLinkRouter: WatchDeepLinkRouter
    @AppStorage("rentory.watch.selectedTab") private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                UpcomingRemindersView()
            }
            .tabItem { Label("Reminders", systemImage: "bell.fill") }
            .tag(0)

            NavigationStack {
                PropertyListView()
            }
            .tabItem { Label("Records", systemImage: "house.fill") }
            .tag(1)

            NavigationStack {
                QuickAddReminderView()
            }
            .tabItem { Label("Add", systemImage: "plus.circle.fill") }
            .tag(2)
        }
        .onReceive(deepLinkRouter.$targetTab) { newTab in
            // A complication tap (or any rentory:// URL) asks us to
            // focus a specific tab. Switch and clear the request so a
            // subsequent manual tab switch isn't immediately overwritten.
            guard let newTab else { return }
            selectedTab = newTab
            deepLinkRouter.clearPendingTab()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchSnapshotStore.shared)
        .environmentObject(WatchSessionCoordinator.shared)
}
