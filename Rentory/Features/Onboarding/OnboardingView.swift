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
            body: "Start a record for a house, flat, apartment, annex, garage or any other rented space. Add rooms, notes, documents and photos as you go, so the important details are together when you need them.",
            systemImage: "house.and.flag.fill"
        ),
        OnboardingPage(
            title: "Keep the story in order",
            body: "Build a clear timeline for move-in dates, inspections, repair requests, cleaning, messages and deposit conversations. It is much easier to remember what happened when it is already written down.",
            systemImage: "point.topleft.down.curvedto.point.bottomright.up"
        ),
        OnboardingPage(
            title: "Private by design",
            body: "Rentory does not need an account. Your records stay on this device by default, and you decide when to use iCloud sync, export a backup or share a report.",
            systemImage: "lock.shield.fill"
        ),
    ]

    var body: some View {
        ZStack {
            RRBackgroundView()

            VStack(spacing: 20) {
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

                pageDeck
                    .frame(maxWidth: 640)
                    .frame(height: 460)

                compactPageIndicator

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
        .toolbar {
#if os(macOS)
            ToolbarItem(placement: .principal) {
                toolbarPageIndicator
            }
#endif
        }
    }

    @ViewBuilder
    private var pageDeck: some View {
#if os(macOS)
        pageCard(page: pages[currentPage], index: currentPage)
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
#else
        TabView(selection: $currentPage) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                pageCard(page: page, index: index)
                    .tag(index)
                    .padding(.vertical, 6)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .tint(RRColours.secondary)
#endif
    }

    private func pageCard(page: OnboardingPage, index: Int) -> some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: 20) {
                RRIconBadge(systemName: page.systemImage, tint: RRColours.secondary, size: 64)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 12) {
                    Text(page.title)
                        .font(RRTypography.largeTitle)
                        .foregroundStyle(RRColours.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(page.body)
                        .font(RRTypography.body)
                        .foregroundStyle(RRColours.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if index == pages.indices.last {
                    Text("Rentory helps you organise your own records. It does not give legal, financial or tenancy advice.")
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var compactPageIndicator: some View {
#if os(macOS)
        EmptyView()
#else
        pageIndicator
#endif
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? RRColours.secondary : RRColours.mutedText.opacity(0.35))
                    .frame(width: index == currentPage ? 24 : 9, height: 9)
                    .animation(RRTheme.quickAnimation, value: currentPage)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Welcome screen \(currentPage + 1) of \(pages.count)")
    }

#if os(macOS)
    private var toolbarPageIndicator: some View {
        HStack(spacing: 7) {
            ForEach(pages.indices, id: \.self) { index in
                Button {
                    withAnimation(RRTheme.quickAnimation) {
                        currentPage = index
                    }
                } label: {
                    Circle()
                        .fill(index == currentPage ? RRColours.secondary : RRColours.secondary.opacity(0.32))
                        .frame(width: 8, height: 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show welcome screen \(index + 1)")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
#endif
}

private struct OnboardingPage {
    let title: String
    let body: String
    let systemImage: String
}

#Preview {
    OnboardingView()
}
