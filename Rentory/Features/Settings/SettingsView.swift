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

    @State private var appLockToggleIsOn = false

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
            }
            .navigationTitle("Settings")
            .onAppear {
                appLockToggleIsOn = appSecurityState.isAppLockEnabled
            }
            .onChange(of: appSecurityState.isAppLockEnabled) { _, newValue in
                appLockToggleIsOn = newValue
            }
            .alert("App Lock", isPresented: alertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(appSecurityState.alertMessage ?? "")
            }
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { appSecurityState.alertMessage != nil },
            set: { newValue in
                if !newValue {
                    appSecurityState.alertMessage = nil
                }
            }
        )
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSecurityState())
}
