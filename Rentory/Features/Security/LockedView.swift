//
//  LockedView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct LockedView: View {
    let isAvailable: Bool
    let isAuthenticating: Bool
    let unlockAction: () -> Void

    var body: some View {
        ZStack {
            RRColours.groupedBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: isAvailable ? "lock.shield" : "lock.slash")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(RRColours.secondary)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text(isAvailable ? "Rentory is locked" : "App Lock is not available")
                        .font(RRTypography.largeTitle)
                        .foregroundStyle(RRColours.primary)

                    Text(
                        isAvailable
                            ? "Unlock to view your rental records."
                            : "You can still use Rentory, but this device does not currently support Face ID, Touch ID or passcode unlock for the app."
                    )
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)
                    .multilineTextAlignment(.center)
                }

                if isAvailable {
                    RRPrimaryButton(title: isAuthenticating ? "Unlocking…" : "Unlock", isDisabled: isAuthenticating, action: unlockAction)
                        .accessibilityHint("Uses Face ID, Touch ID or your passcode.")
                }
            }
            .padding(24)
        }
        .accessibilityElement(children: .contain)
    }
}
