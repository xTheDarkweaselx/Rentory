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
    @StateObject private var entitlementManager = EntitlementManager()
    @StateObject private var iCloudSyncService = ICloudSyncService()

    // Rentory is local-first. User evidence must remain on device by default.
    // Do not add networking, analytics, account creation or third-party data collection without an explicit architecture decision.
    private let sharedModelContainer: ModelContainer? = {
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
                configurations: [
                    ModelConfiguration(
                        schema: schema,
                        isStoredInMemoryOnly: false,
                        cloudKitDatabase: .none
                    ),
                ]
            )
        } catch {
            assertionFailure("Rentory could not open its saved data. Falling back to temporary storage.")

            do {
                return try ModelContainer(
                    for: schema,
                    configurations: [
                        ModelConfiguration(
                            schema: schema,
                            isStoredInMemoryOnly: true,
                            cloudKitDatabase: .none
                        ),
                    ]
                )
            } catch {
                return nil
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            if let sharedModelContainer {
                RootView()
                    .environmentObject(appSecurityState)
                    .environmentObject(entitlementManager)
                    .environmentObject(iCloudSyncService)
                    .modelContainer(sharedModelContainer)
            } else {
                RRErrorStateView(
                    symbolName: "exclamationmark.triangle",
                    title: "Rentory could not open",
                    message: "Please close the app and try again."
                )
            }
        }
        #if os(macOS) || targetEnvironment(macCatalyst)
        .defaultSize(width: PlatformLayout.preferredWindowWidth, height: PlatformLayout.preferredWindowHeight)
        .windowResizability(.contentMinSize)
        #endif
    }
}
