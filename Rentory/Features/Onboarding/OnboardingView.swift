//
//  OnboardingView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage(RentoryUserProfile.storageKey) private var profileRawValue = RentoryUserProfile.defaultProfile.rawValue
    @EnvironmentObject private var entitlementManager: EntitlementManager

    @State private var currentPage = 0
    @State private var isShowingLandlordPaywall = false

    private let informationalPages: [OnboardingPage] = [
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

    private var totalSteps: Int { informationalPages.count + 1 }
    private var isOnProfileStep: Bool { currentPage == informationalPages.count }

    private var selectedProfile: RentoryUserProfile {
        RentoryUserProfile(rawValue: profileRawValue) ?? .defaultProfile
    }

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
                    .frame(minHeight: 480, maxHeight: .infinity)

                compactPageIndicator

                RRPrimaryButton(title: isOnProfileStep ? "Get started" : "Continue") {
                    if isOnProfileStep {
                        hasCompletedOnboarding = true
                    } else {
                        withAnimation(RRTheme.quickAnimation) {
                            currentPage += 1
                        }
                    }
                }
                .accessibilityHint(isOnProfileStep ? "Opens your rental records." : "Moves to the next screen.")

                Spacer()
            }
            .frame(maxWidth: 700)
            .padding(RRTheme.screenPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $isShowingLandlordPaywall) {
            LimitReachedView(
                title: FeatureAccessService.landlordProfilePrompt.title,
                message: FeatureAccessService.landlordProfilePrompt.message
            )
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
        Group {
            if isOnProfileStep {
                profilePickerCard
            } else {
                pageCard(page: informationalPages[currentPage], index: currentPage)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
#else
        TabView(selection: $currentPage) {
            ForEach(Array(informationalPages.enumerated()), id: \.offset) { index, page in
                pageCard(page: page, index: index)
                    .tag(index)
                    .padding(.vertical, 6)
            }

            profilePickerCard
                .tag(informationalPages.count)
                .padding(.vertical, 6)
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

                if index == informationalPages.indices.last {
                    Text("Rentory helps you organise your own records. It does not give legal, financial or tenancy advice.")
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var profilePickerCard: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: 18) {
                RRIconBadge(systemName: "person.crop.circle.badge.questionmark", tint: RRColours.secondary, size: 56)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 10) {
                    Text("How will you use Rentory?")
                        .font(RRTypography.largeTitle)
                        .foregroundStyle(RRColours.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Pick the profile that fits how you'll use the app. You can switch at any time in Settings.")
                        .font(RRTypography.body)
                        .foregroundStyle(RRColours.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    profileChoiceRow(.renter)
                    profileChoiceRow(.landlord)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func profileChoiceRow(_ profile: RentoryUserProfile) -> some View {
        let isSelected = selectedProfile == profile && !isLocked(for: profile)
        let locked = isLocked(for: profile)

        Button {
            handleProfileTap(profile)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: profile.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .foregroundStyle(isSelected ? .white : RRColours.secondary)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? RRColours.secondary : RRColours.cardHighlight)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(profile.rawValue)
                            .font(RRTypography.headline)
                            .foregroundStyle(RRColours.primary)

                        if locked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(RRColours.warning)
                        } else if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(RRColours.success)
                        }
                    }

                    Text(profile.shortSummary)
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if isSelected {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(profile.featureHighlights, id: \.self) { highlight in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(RRColours.success)
                                        .padding(.top, 2)
                                    Text(highlight)
                                        .font(RRTypography.caption)
                                        .foregroundStyle(RRColours.primary)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }

                    if locked {
                        Text("Lifetime unlock required")
                            .font(RRTypography.caption.weight(.semibold))
                            .foregroundStyle(RRColours.warning)
                    }
                }

                Spacer(minLength: 8)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? RRColours.cardHighlight : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? RRColours.secondary : RRColours.border, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(profile.rawValue) profile\(locked ? ", locked" : isSelected ? ", selected" : "")")
        .accessibilityHint(locked ? "Shows the lifetime unlock prompt." : "Selects \(profile.rawValue) mode.")
    }

    private func handleProfileTap(_ profile: RentoryUserProfile) {
        if isLocked(for: profile) {
            isShowingLandlordPaywall = true
            return
        }
        profileRawValue = profile.rawValue
    }

    private func isLocked(for profile: RentoryUserProfile) -> Bool {
        profile == .landlord && !FeatureAccessService.canSwitchToLandlordProfile(isUnlocked: entitlementManager.isUnlocked)
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
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? RRColours.secondary : RRColours.mutedText.opacity(0.35))
                    .frame(width: index == currentPage ? 24 : 9, height: 9)
                    .animation(RRTheme.quickAnimation, value: currentPage)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Welcome screen \(currentPage + 1) of \(totalSteps)")
    }

#if os(macOS)
    private var toolbarPageIndicator: some View {
        HStack(spacing: 7) {
            ForEach(0..<totalSteps, id: \.self) { index in
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
        .environmentObject(EntitlementManager())
}
