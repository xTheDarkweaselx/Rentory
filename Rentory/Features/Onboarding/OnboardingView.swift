//
//  OnboardingView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Record your rented home",
            body: "Create a private record with rooms, photos, documents and notes.",
            systemImage: "house.and.flag.fill"
        ),
        OnboardingPage(
            title: "Everything in one place",
            body: "Keep move-in details, documents and timeline events together.",
            systemImage: "square.grid.2x2.fill"
        ),
        OnboardingPage(
            title: "Private by design",
            body: "No account needed. Your records stay on your device by default.",
            systemImage: "lock.shield.fill"
        ),
    ]

    var body: some View {
        ZStack {
            RRBackgroundView()

            VStack(spacing: 24) {
                Spacer(minLength: 12)

                VStack(spacing: 12) {
                    Text("Rentory")
                        .font(RRTypography.largeTitle)
                        .foregroundStyle(RRColours.primary)

                    Text("A calm, private place for your rental records.")
                        .font(RRTypography.body)
                        .foregroundStyle(RRColours.mutedText)
                        .multilineTextAlignment(.center)
                }

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        RRGlassPanel {
                            VStack(alignment: .leading, spacing: 20) {
                                RRProgressPill(title: page.title)
                                    .accessibilityHidden(true)

                                RRIconBadge(systemName: page.systemImage, tint: RRColours.secondary, size: 64)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 10) {
                                    Text(page.title)
                                        .font(RRTypography.largeTitle)
                                        .foregroundStyle(RRColours.primary)

                                    Text(page.body)
                                        .font(RRTypography.body)
                                        .foregroundStyle(RRColours.mutedText)
                                }

                                if index == pages.indices.last {
                                    Text("Rentory helps you organise your own records. It does not give legal, financial or tenancy advice.")
                                        .font(RRTypography.footnote)
                                        .foregroundStyle(RRColours.mutedText)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tag(index)
                        .padding(.vertical, 6)
                    }
                }
                .modifier(OnboardingTabStyle())
                .frame(maxWidth: 640)
                .frame(height: 420)

                RRPrimaryButton(title: currentPage == pages.indices.last ? "Get started" : "Continue") {
                    if currentPage == pages.indices.last {
                        hasCompletedOnboarding = true
                    } else {
                        withAnimation(RRTheme.quickAnimation) {
                            currentPage += 1
                        }
                    }
                }
                .accessibilityHint(currentPage == pages.indices.last ? "Opens your rental records." : "Moves to the next screen.")

                Spacer()
            }
            .frame(maxWidth: 700)
            .padding(RRTheme.screenPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct OnboardingPage {
    let title: String
    let body: String
    let systemImage: String
}

private struct OnboardingTabStyle: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.tabViewStyle(.page(indexDisplayMode: .always))
        #else
        content
        #endif
    }
}

#Preview {
    OnboardingView()
}
