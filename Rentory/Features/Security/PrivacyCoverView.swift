//
//  PrivacyCoverView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct PrivacyCoverView: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RRBackgroundView()

                VStack(spacing: 28) {
                    Spacer(minLength: 24)

                    RRGlassPanel(padding: panelPadding(for: proxy.size)) {
                        ViewThatFits(in: .horizontal) {
                            coverContent(isWide: true)
                            coverContent(isWide: false)
                        }
                    }
                    .frame(maxWidth: min(proxy.size.width - 40, 760))

                    Text("Rentory hides your records while the app is away from the screen.")
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: min(proxy.size.width - 48, 520))

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(RRTheme.screenPadding)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func coverContent(isWide: Bool) -> some View {
        Group {
            if isWide {
                HStack(spacing: 28) {
                    coverIcon
                    coverText(alignment: .leading, textAlignment: .leading)
                }
            } else {
                VStack(spacing: 18) {
                    coverIcon
                    coverText(alignment: .center, textAlignment: .center)
                }
            }
        }
    }

    private var coverIcon: some View {
        ZStack {
            Circle()
                .fill(RRColours.secondary.opacity(0.14))
                .frame(width: 118, height: 118)

            RRIconBadge(systemName: "shield.lefthalf.filled", tint: RRColours.secondary, size: 74)
                .accessibilityHidden(true)
        }
        .frame(width: 130, height: 130)
    }

    private func coverText(alignment: HorizontalAlignment, textAlignment: TextAlignment) -> some View {
        VStack(alignment: alignment, spacing: 12) {
            Text("Rentory is private")
                .font(RRTypography.largeTitle)
                .foregroundStyle(RRColours.primary)

            Text("Your rental records are covered until you return to the app.")
                .font(RRTypography.body)
                .foregroundStyle(RRColours.mutedText)
                .multilineTextAlignment(textAlignment)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 420, alignment: frameAlignment(for: alignment))
    }

    private func panelPadding(for size: CGSize) -> CGFloat {
        size.width > 620 ? 36 : 28
    }

    private func frameAlignment(for alignment: HorizontalAlignment) -> Alignment {
        alignment == .leading ? .leading : .center
    }
}

#Preview {
    PrivacyCoverView()
}
