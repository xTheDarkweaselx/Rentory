//
//  RestoreUnlockBanner.swift
//  Rentory
//
//  Shown when the user's profile is .landlord but EntitlementManager.isUnlocked
//  is false — typically after a StoreKit transaction was revoked or the
//  cached unlock got cleared. Surfaces a Restore Purchase CTA so the user
//  can recover without rooting through Settings.
//

import SwiftUI

struct RestoreUnlockBanner: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var isShowingPaywall = false

    var body: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(RRColours.warning)
                        .padding(.top, 2)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Landlord unlock needs restoring")
                            .font(RRTypography.headline)
                            .foregroundStyle(RRColours.primary)
                        Text("Rentory could not verify your lifetime unlock just now. Restore the purchase to keep using landlord mode, or switch back to Renter from Settings.")
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.mutedText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: RRTheme.controlSpacing) {
                        restoreButton
                        viewUnlockOptionsButton
                    }

                    VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                        restoreButton
                        viewUnlockOptionsButton
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Landlord unlock needs restoring. Restore your purchase from this banner.")
    }

    private var restoreButton: some View {
        RRPrimaryButton(
            title: entitlementManager.purchaseInProgress ? "Restoring…" : "Restore purchase",
            isDisabled: entitlementManager.purchaseInProgress
        ) {
            Task {
                await entitlementManager.restorePurchases()
            }
        }
    }

    private var viewUnlockOptionsButton: some View {
        RRSecondaryButton(title: "Unlock options") {
            isShowingPaywall = true
        }
    }
}
