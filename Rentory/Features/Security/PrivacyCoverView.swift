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
            RRColours.groupedBackground.ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "shield")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(RRColours.secondary)
                    .accessibilityHidden(true)

                Text("Rentory")
                    .font(RRTypography.largeTitle)
                    .foregroundStyle(RRColours.primary)

                Text("Your records stay private.")
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    PrivacyCoverView()
}
