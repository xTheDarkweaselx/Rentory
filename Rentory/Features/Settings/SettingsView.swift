//
//  SettingsView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSecurityState: AppSecurityState
    @EnvironmentObject private var entitlementManager: EntitlementManager

    @State private var appLockToggleIsOn = false
    @State private var upgradePromptContent: UpgradePromptContent?

    private let iCloudStatusService = ICloudSyncStatusService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Privacy & security") {
                    ForEach(PrivacyNoticeContent.sections) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.title)
                                .font(RRTypography.headline)

                            Text(section.body)
                                .font(RRTypography.footnote)
                                .foregroundStyle(RRColours.mutedText)
                        }
                        .padding(.vertical, 4)
                    }

                    Text(SecurityPolicy.localFirstStatement)
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                }

                Section("App Lock") {
                    Text("Use Face ID, Touch ID or your passcode to help keep your rental records private.")
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)

                    Toggle("Lock Rentory", isOn: $appLockToggleIsOn)
                        .disabled(appSecurityState.isAuthenticating)
                        .accessibilityHint("Uses Face ID, Touch ID or your passcode.")
                        .onChange(of: appLockToggleIsOn) { oldValue, newValue in
                            guard oldValue != newValue else {
                                return
                            }

                            guard !(newValue && !appSecurityState.isAppLockEnabled && !FeatureAccessService.canUseAppLock(isUnlocked: entitlementManager.isUnlocked)) else {
                                upgradePromptContent = FeatureAccessService.appLockLimitPrompt
                                appLockToggleIsOn = appSecurityState.isAppLockEnabled
                                return
                            }

                            Task {
                                let didChange = await appSecurityState.setAppLockEnabled(newValue)

                                if !didChange {
                                    appLockToggleIsOn = appSecurityState.isAppLockEnabled
                                }
                            }
                        }
                }

                Section("Important") {
                    Text(SecurityPolicy.appBoundaryStatement)
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)

                    NavigationLink {
                        ICloudSyncSettingsView()
                    } label: {
                        LabeledContent("iCloud Sync", value: iCloudSettingsValue)
                    }
                    .accessibilityHint("Check iCloud availability and backup options.")

                    NavigationLink("Backups") {
                        BackupsSettingsView()
                    }
                    .accessibilityHint("Export or import a Rentory backup.")

                    NavigationLink {
                        PurchaseSettingsView()
                    } label: {
                        LabeledContent("Rentory unlock", value: entitlementManager.isUnlocked ? "Lifetime unlock active" : "Free version")
                    }
                    .accessibilityHint("View purchase status and unlock options.")

                    RRSecondaryButton(title: "Reset welcome screens") {
                        hasCompletedOnboarding = false
                        dismiss()
                    }
                    .accessibilityHint("Shows the welcome screens again.")

                    NavigationLink("Privacy & Data") {
                        PrivacyAndDataSettingsView()
                    }
                    .accessibilityHint("Manage temporary reports and deletion options.")
                }

#if DEBUG
                Section("Developer") {
                    NavigationLink("Demo data") {
                        DeveloperDemoSettingsView()
                    }
                    .accessibilityHint("Load or clear fake sample data for testing and screenshots.")
                }
#endif
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(RRBackgroundView())
            .onAppear {
                appLockToggleIsOn = appSecurityState.isAppLockEnabled
            }
            .onChange(of: appSecurityState.isAppLockEnabled) { _, newValue in
                appLockToggleIsOn = newValue
            }
            .alert(item: $appSecurityState.alertContent) { content in
                Alert(
                    title: Text(content.title),
                    message: Text(content.message),
                    dismissButton: .cancel(Text(content.buttonTitle))
                )
            }
            .sheet(item: $upgradePromptContent) { content in
                LimitReachedView(title: content.title, message: content.message)
            }
        }
    }

    private var iCloudSettingsValue: String {
        switch iCloudStatusService.currentStatus() {
        case .available:
            return "Off"
        case .unavailable:
            return "Unavailable"
        case .checking, .unknown:
            return "Off"
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSecurityState())
        .environmentObject(EntitlementManager())
}
