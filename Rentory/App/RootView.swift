//
//  RootView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var appSecurityState: AppSecurityState

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
        }
        .task {
            try? FileStorageService().cleanupOldTemporaryExports()
        }
        .alert(item: $appSecurityState.alertContent) { content in
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
}
