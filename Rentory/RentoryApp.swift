//
//  RentoryApp.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI

@main
struct RentoryApp: App {
    @StateObject private var appSecurityState = AppSecurityState()

    // Rentory is local-first. User evidence must remain on device by default.
    // Do not add networking, analytics, account creation or third-party data collection without an explicit architecture decision.
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PropertyPack.self,
            RoomRecord.self,
            ChecklistItemRecord.self,
            EvidencePhoto.self,
            DocumentRecord.self,
            TimelineEvent.self,
        ])

        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appSecurityState)
        }
        .modelContainer(sharedModelContainer)
    }
}
