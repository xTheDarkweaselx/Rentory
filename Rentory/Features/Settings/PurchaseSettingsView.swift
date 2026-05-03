//
//  PurchaseSettingsView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct PurchaseSettingsView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager

    @State private var isShowingPaywall = false
    @State private var successAlertContent: RRAlertContent?

    private var statusText: String {
        entitlementManager.isUnlocked ? "Lifetime unlock active" : "Free version"
    }

    var body: some View {
        Form {
            Section("Status") {
                LabeledContent("Current status", value: statusText)

                if entitlementManager.isUnlocked {
                    RRSecondaryButton(
                        title: entitlementManager.purchaseInProgress ? "Restoring…" : "Restore purchase",
                        isDisabled: entitlementManager.purchaseInProgress
                    ) {
                        Task {
                            await entitlementManager.restorePurchases()
                            if entitlementManager.isUnlocked {
                                successAlertContent = DialogCopy.purchaseRestored
                            }
                        }
                    }
                } else {
                    RRPrimaryButton(title: "Unlock Rentory") {
                        isShowingPaywall = true
                    }

                    RRSecondaryButton(
                        title: entitlementManager.purchaseInProgress ? "Restoring…" : "Restore purchase",
                        isDisabled: entitlementManager.purchaseInProgress
                    ) {
                        Task {
                            await entitlementManager.restorePurchases()
                            if entitlementManager.isUnlocked {
                                successAlertContent = DialogCopy.purchaseRestored
                            }
                        }
                    }
                }
            }

            Section {
                Text("Lifetime unlock is a one-time purchase. Your rental records stay on your device, and no account is needed.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }
        }
        .navigationTitle("Rentory unlock")
        .rrInlineNavigationTitle()
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
                .environmentObject(entitlementManager)
        }
        .task {
            if entitlementManager.products.isEmpty {
                await entitlementManager.loadProducts()
            }
        }
        .alert(item: errorBinding) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .cancel(Text(error.recoveryActionTitle ?? "OK")) {
                    entitlementManager.clearLastError()
                }
            )
        }
        .alert(item: $successAlertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
    }

    private var errorBinding: Binding<UserFacingError?> {
        Binding(
            get: { entitlementManager.lastError },
            set: { newValue in
                if newValue == nil {
                    entitlementManager.clearLastError()
                }
            }
        )
    }
}
