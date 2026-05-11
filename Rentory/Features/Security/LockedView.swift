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
        GeometryReader { proxy in
            ZStack {
                RRBackgroundView()

                VStack(spacing: 28) {
                    Spacer(minLength: 24)

                    RRGlassPanel(padding: panelPadding(for: proxy.size)) {
                        ViewThatFits(in: .horizontal) {
                            lockContent(isWide: true)
                            lockContent(isWide: false)
                        }
                    }
                    .frame(maxWidth: min(proxy.size.width - 40, 780))

                    Text(isAvailable ? unlockHint : "You can continue using Rentory, but app lock is not available on this device.")
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: min(proxy.size.width - 48, 560))

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(RRTheme.screenPadding)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func lockContent(isWide: Bool) -> some View {
        Group {
            if isWide {
                HStack(spacing: 30) {
                    lockIcon
                    lockText(alignment: .leading, textAlignment: .leading)
                }
            } else {
                VStack(spacing: 20) {
                    lockIcon
                    lockText(alignment: .center, textAlignment: .center)
                }
            }
        }
    }

    private var unlockHint: String {
        #if os(macOS)
        "Use Touch ID to continue. If Touch ID needs your password, macOS will ask for it."
        #else
        "Use Face ID or Touch ID to continue."
        #endif
    }

    private var unavailableMessage: String {
        #if os(macOS)
        "This Mac does not currently have Touch ID set up for app unlock."
        #else
        "Face ID or Touch ID is not available for Rentory on this device."
        #endif
    }

    private var lockIcon: some View {
        ZStack {
            Circle()
                .fill(RRColours.secondary.opacity(0.14))
                .frame(width: 124, height: 124)

            RRIconBadge(systemName: isAvailable ? "lock.shield" : "lock.slash", tint: RRColours.secondary, size: 78)
                .accessibilityHidden(true)
        }
        .frame(width: 138, height: 138)
    }

    private func lockText(alignment: HorizontalAlignment, textAlignment: TextAlignment) -> some View {
        VStack(alignment: alignment, spacing: 16) {
            VStack(alignment: alignment, spacing: 10) {
                Text(isAvailable ? "Rentory is locked" : "App Lock is not available")
                    .font(RRTypography.largeTitle)
                    .foregroundStyle(RRColours.primary)
                    .multilineTextAlignment(textAlignment)

                Text(
                    isAvailable
                        ? "Unlock to view your rental records."
                        : unavailableMessage
                )
                .font(RRTypography.body)
                .foregroundStyle(RRColours.mutedText)
                .multilineTextAlignment(textAlignment)
                .fixedSize(horizontal: false, vertical: true)
            }

            if isAvailable {
                RRPrimaryButton(title: isAuthenticating ? "Unlocking..." : "Unlock", isDisabled: isAuthenticating, action: unlockAction)
                    .frame(maxWidth: 260)
                    .accessibilityHint("Uses Face ID, Touch ID or your passcode.")
            }
        }
        .frame(maxWidth: 440, alignment: frameAlignment(for: alignment))
    }

    private func panelPadding(for size: CGSize) -> CGFloat {
        size.width > 620 ? 38 : 28
    }

    private func frameAlignment(for alignment: HorizontalAlignment) -> Alignment {
        alignment == .leading ? .leading : .center
    }
}
