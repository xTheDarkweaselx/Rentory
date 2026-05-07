//
//  RootView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appSecurityState: AppSecurityState
    @EnvironmentObject private var iCloudSyncService: ICloudSyncService

    var body: some View {
        ZStack {
            mainContent

            if appSecurityState.shouldShowPrivacyCover {
                PrivacyCoverView()
                    .transition(.opacity)
                    .zIndex(1)
            }

            if appSecurityState.isAppLockEnabled && appSecurityState.isLocked {
                LockedView(
                    isAvailable: appSecurityState.isAppLockAvailable,
                    isAuthenticating: appSecurityState.isAuthenticating
                ) {
                    Task {
                        await appSecurityState.unlockApp()
                    }
                }
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: appSecurityState.isLocked)
        .animation(.easeInOut(duration: 0.2), value: appSecurityState.shouldShowPrivacyCover)
        .onChange(of: scenePhase) { _, newPhase in
            appSecurityState.handleScenePhaseChange(newPhase)

            Task {
                switch newPhase {
                case .active:
                    await iCloudSyncService.refreshStatus()
                    await iCloudSyncService.syncIfNeededForSceneActive(context: modelContext)
                case .background:
                    await iCloudSyncService.syncBeforeBackground(context: modelContext)
                case .inactive:
                    break
                @unknown default:
                    break
                }
            }
        }
        .task {
            try? FileStorageService().cleanupOldTemporaryExports()
            await iCloudSyncService.refreshStatus()
            await iCloudSyncService.syncIfNeededForSceneActive(context: modelContext)
        }
        .alert(item: $appSecurityState.alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
        .alert(item: $iCloudSyncService.alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if hasCompletedOnboarding {
            if PlatformLayout.prefersSplitView(for: horizontalSizeClass) {
                PropertiesSplitView()
            } else {
                PropertiesListView()
            }
        } else {
            OnboardingView()
        }
    }
}

#Preview("Onboarding") {
    RootView()
        .environmentObject(AppSecurityState())
        .environmentObject(ICloudSyncService())
}
