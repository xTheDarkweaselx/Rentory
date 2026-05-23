//
//  RentoryApp.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI
import UserNotifications

@main
struct RentoryApp: App {
    @StateObject private var appSecurityState = AppSecurityState()
    @StateObject private var entitlementManager = EntitlementManager()
    @StateObject private var iCloudSyncService = ICloudSyncService()
    @StateObject private var reminderNotificationService = ReminderNotificationService()
    // WatchSyncService owns a WCSession.default.delegate and must therefore
    // be a single per-app instance. On macOS / iPad multi-window, hosting it
    // on RootView would create a fresh instance per scene and race delegate
    // assignment. Keep it here at the App scope.
    @StateObject private var watchSyncService = WatchSyncService()
    @StateObject private var deepLinkRouter = RentoryDeepLinkRouter()
    @StateObject private var notificationDelegate = RentoryNotificationDelegate()
    @StateObject private var calendarMirrorService = CalendarMirrorService()
    @AppStorage(AppAppearance.storageKey) private var appAppearanceRawValue = AppAppearance.deviceDefault.rawValue
    @AppStorage(AppColourTheme.storageKey) private var appColourThemeRawValue = AppColourTheme.defaultLook.rawValue

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
            Reminder.self,
            ItemComment.self,
            Tenancy.self,
            Tenant.self,
            RentPayment.self,
            PropertyExpense.self,
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
                    .environmentObject(reminderNotificationService)
                    .environmentObject(watchSyncService)
                    .environmentObject(deepLinkRouter)
                    .environmentObject(calendarMirrorService)
                    .modelContainer(sharedModelContainer)
                    .onOpenURL { url in
                        deepLinkRouter.handle(url)
                    }
                    .task {
                        // Wire the notification delegate exactly once.
                        // Setting it any later means notifications tapped
                        // before this point would land on the system
                        // default behaviour (no router hop).
                        notificationDelegate.attach(router: deepLinkRouter)
                        UNUserNotificationCenter.current().delegate = notificationDelegate
                    }
                    .preferredColorScheme(selectedAppearance.preferredColorScheme)
                    .tint(RRColours.secondary(for: selectedColourTheme))
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

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRawValue) ?? .deviceDefault
    }

    private var selectedColourTheme: AppColourTheme {
        AppColourTheme(rawValue: appColourThemeRawValue) ?? .defaultLook
    }
}
