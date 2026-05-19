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
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchSnapshotStore.shared)
        .environmentObject(WatchSessionCoordinator.shared)
}
