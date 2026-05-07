//
//  PaywallView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var successAlertContent: RRAlertContent?

    var body: some View {
        NavigationStack {
            RRMacSheetContainer(maxWidth: 920, minHeight: PlatformLayout.isMac ? 680 : nil) {
                VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                    RRSheetHeader(
                        title: "Unlock Rentory",
                        subtitle: "One-time purchase. Create more records, add more photos and export full reports.",
                        systemImage: "sparkles",
                        showsCloseButton: true,
                        closeAction: { dismiss() }
                    )

                    RRResponsiveFormGrid(items: [
                        RRResponsiveFormGridItem(span: .fullWidth) {
                            lifetimeUnlockPanel
                        },
                        RRResponsiveFormGridItem {
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
                        },
                        RRResponsiveFormGridItem {
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
                        },
                        RRResponsiveFormGridItem {
                            paywallSection(
                                title: "Private by design",
                                items: [
                                    "No account needed",
                                    "Your rental records stay on your device by default",
                                    "No advertising trackers",
                                ]
                            )
                        },
                        RRResponsiveFormGridItem(span: .fullWidth) {
                            RRGlassCard {
                                Text("Your rental records stay on your device by default.")
                                    .font(RRTypography.footnote)
                                    .foregroundStyle(RRColours.mutedText)
                            }
                        },
                        RRResponsiveFormGridItem(span: .fullWidth) {
                            VStack(spacing: 12) {
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
                        },
                    ])
                }
            }
            .navigationTitle("Unlock Rentory")
            .rrInlineNavigationTitle()
            .onChange(of: entitlementManager.isUnlocked) { _, isUnlocked in
                if isUnlocked {
                    dismiss()
                }
            }
            .overlay {
                if entitlementManager.purchaseInProgress {
                    ZStack {
                        Color.black.opacity(0.12)
                            .ignoresSafeArea()

                        RRLoadingView(
                            title: "Checking purchase",
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

    private var lifetimeUnlockPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                Text("Lifetime unlock")
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)

                if entitlementManager.isLoadingProducts && entitlementManager.lifetimeUnlockOffer == nil {
                    RRLoadingView(
                        title: "Loading unlock option",
                        message: "Please wait a moment."
                    )
                } else if let offer = entitlementManager.lifetimeUnlockOffer {
                    VStack(alignment: .leading, spacing: 12) {
                        PurchaseRowView(
                            product: entitlementManager.products.first(where: { $0.id == offer.productID }),
                            fallbackPriceText: offer.displayPrice
                        )

                        RRPrimaryButton(
                            title: entitlementManager.purchaseInProgress ? "Unlocking…" : "Unlock for life",
                            isDisabled: entitlementManager.purchaseInProgress || entitlementManager.isUnlocked
                        ) {
                            Task {
                                await entitlementManager.purchaseLifetimeUnlock()
                            }
                        }
                    }
                } else {
                    unavailableProductPanel(
                        title: "Unlock option is unavailable",
                        message: "Rentory could not find the lifetime unlock in the current StoreKit setup. Re-select `Rentory.storekit` in the Run scheme, then run the app again."
                    )
                }
            }
        }
    }

    private func unavailableProductPanel(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(RRTypography.headline)
                .foregroundStyle(RRColours.primary)

            Text(message)
                .font(RRTypography.body)
                .foregroundStyle(RRColours.mutedText)
        }
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
