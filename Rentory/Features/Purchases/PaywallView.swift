//
//  PaywallView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var successAlertContent: RRAlertContent?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RRSheetHeader(
                        title: "Unlock Rentory",
                        subtitle: "One-time purchase. Create more records, add more photos and export full reports.",
                        systemImage: "sparkles"
                    )

                    PurchaseRowView(product: entitlementManager.products.first)

                    paywallSection(
                        title: "What’s included",
                        items: [
                            "Unlimited rental records",
                            "Unlimited rooms",
                            "Unlimited photos",
                            "Full report export",
                            "App Lock",
                            "No account needed",
                        ]
                    )

                    paywallSection(
                        title: "Free version",
                        items: [
                            "Create one rental record",
                            "Add up to two rooms",
                            "Add up to twenty photos",
                            "Keep using your existing records",
                            "Try the main features before unlocking",
                        ]
                    )

                    paywallSection(
                        title: "Private by design",
                        items: [
                            "No account needed",
                            "Your rental records stay on your device by default",
                            "No advertising trackers",
                        ]
                    )

                    RRGlassCard {
                        Text("Your rental records stay on your device by default.")
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.mutedText)
                    }

                    VStack(spacing: 12) {
                        RRPrimaryButton(
                            title: entitlementManager.purchaseInProgress ? "Unlocking…" : "Unlock for life",
                            isDisabled: entitlementManager.purchaseInProgress || entitlementManager.isUnlocked
                        ) {
                            Task {
                                await entitlementManager.purchaseLifetimeUnlock()
                                if entitlementManager.isUnlocked {
                                    dismiss()
                                }
                            }
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
                .padding(RRTheme.screenPadding)
            }
            .background(RRBackgroundView())
            .navigationTitle("Unlock Rentory")
            .rrInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") {
                        dismiss()
                    }
                }
            }
            .task {
                if entitlementManager.products.isEmpty {
                    await entitlementManager.loadProducts()
                }
            }
            .overlay {
                if entitlementManager.isLoadingProducts || entitlementManager.purchaseInProgress {
                    ZStack {
                        Color.black.opacity(0.12)
                            .ignoresSafeArea()

                        RRLoadingView(
                            title: entitlementManager.purchaseInProgress ? "Checking purchase" : "Loading unlock options",
                            message: "Please wait a moment."
                        )
                        .padding(24)
                    }
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
                    dismissButton: .cancel(Text(content.buttonTitle)) {
                        dismiss()
                    }
                )
            }
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

    private func paywallSection(title: String, items: [String]) -> some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)

                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(RRColours.success)
                            .accessibilityHidden(true)

                        Text(item)
                            .font(RRTypography.body)
                            .foregroundStyle(RRColours.primary)
                    }
                }
            }
        }
    }
}
