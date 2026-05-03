//
//  PrivacyCoverView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct PrivacyCoverView: View {
    var body: some View {
        ZStack {
            RRBackgroundView()

            RRGlassPanel {
                VStack(spacing: 12) {
                    RRIconBadge(systemName: "shield", tint: RRColours.secondary, size: 58)
                        .accessibilityHidden(true)

                    Text("Rentory")
                        .font(RRTypography.largeTitle)
                        .foregroundStyle(RRColours.primary)

                    Text("Your records stay private.")
                        .font(RRTypography.body)
                        .foregroundStyle(RRColours.mutedText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(RRTheme.screenPadding)
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PrivacyCoverView()
}
