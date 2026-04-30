//
//  OnboardingView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    RRColours.groupedBackground,
                    RRColours.background,
                    RRColours.cardBackground.opacity(0.8),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Spacer()

                RRCard {
                    VStack(alignment: .leading, spacing: 18) {
                        RRProgressPill(title: "Private by design")
                            .accessibilityHidden(true)

                        Text("Rentory")
                            .font(RRTypography.largeTitle)

                        Text("Create a private record of your rented home.")
                            .font(RRTypography.body)
                            .foregroundStyle(RRColours.mutedText)

                        Text("Your records stay on your device by default, so you can keep everything together in one calm, organised place.")
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.mutedText)

                        RRPrimaryButton(title: "Get started") {
                            hasCompletedOnboarding = true
                        }
                        .accessibilityHint("Opens your rental records.")
                    }
                }

                Spacer()
            }
            .frame(maxWidth: 560)
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    OnboardingView()
}
