//
//  PurchaseSettingsView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import StoreKit
import SwiftUI

struct PurchaseSettingsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.rrUsesEmbeddedNavigationLayout) private var usesEmbeddedNavigationLayout
    @EnvironmentObject private var entitlementManager: EntitlementManager

    @State private var isShowingPaywall = false
    @State private var successAlertContent: RRAlertContent?

    private var statusText: String {
        entitlementManager.isUnlocked ? "Lifetime unlock active" : "Free version"
    }

    var body: some View {
        Group {
            if PlatformLayout.isPhone && horizontalSizeClass != .regular {
                compactView
            } else if usesEmbeddedNavigationLayout {
                RRFormContainer(maxWidth: 920) {
                    RRResponsiveFormGrid(items: detailGridItems)
                }
            } else {
                RRMacSheetContainer(maxWidth: 920, minHeight: PlatformLayout.isMac ? 620 : nil) {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Rentory Unlock",
                            subtitle: "Manage your lifetime unlock and restore earlier purchases.",
                            systemImage: "sparkles"
                        )

                        RRResponsiveFormGrid(items: detailGridItems)
                    }
                }
            }
        }
        .navigationTitle("Rentory unlock")
        .rrInlineNavigationTitle()
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
                .environmentObject(entitlementManager)
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

    private var detailGridItems: [RRResponsiveFormGridItem] {
        [
            RRResponsiveFormGridItem {
                statusPanel
            },
            RRResponsiveFormGridItem {
                purchasePanel
            },
        ]
    }

    private var compactView: some View {
        Form {
            Section("Status") {
                LabeledContent("Current status", value: statusText)
                actionButtons
            }

            Section {
                Text("Lifetime unlock is a one-time purchase. Your rental records stay on your device, and no account is needed.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }
        }
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
    }

    private var statusPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Current status")
                    .font(RRTypography.headline)

                Text(statusText)
                    .font(RRTypography.title)
                    .foregroundStyle(RRColours.primary)

                Text("Lifetime unlock is a one-time purchase. Your rental records stay on your device, and no account is needed.")
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)
            }
        }
    }

    private var purchasePanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Purchase options")
                    .font(RRTypography.headline)

                if entitlementManager.isLoadingProducts && entitlementManager.lifetimeUnlockProduct == nil {
                    Text("Loading unlock option…")
                        .font(RRTypography.body)
                        .foregroundStyle(RRColours.mutedText)
                } else if let product = entitlementManager.lifetimeUnlockProduct {
                    PurchaseRowView(product: product)
                } else {
                    Text("The lifetime unlock is not available in the current StoreKit setup.")
                        .font(RRTypography.body)
                        .foregroundStyle(RRColours.mutedText)
                }

                actionButtons
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: RRTheme.controlSpacing) {
            if !entitlementManager.isUnlocked {
                RRPrimaryButton(title: "Unlock Rentory") {
                    isShowingPaywall = true
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
