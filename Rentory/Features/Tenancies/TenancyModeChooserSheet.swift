//
//  TenancyModeChooserSheet.swift
//  Rentory
//
//  Created by Adam Ibrahim on 19/05/2026.
//

import SwiftUI

/// A tiny "help me decide" sheet that picks between Standard and
/// Comprehensive tenancy modes based on a single question. The user can
/// also just tap one of the mode cards directly, or close the sheet to
/// leave the mode unchanged.
struct TenancyModeChooserSheet: View {
    @Binding var mode: TenancyMode
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppColourTheme.storageKey) private var appColourThemeRawValue = AppColourTheme.defaultLook.rawValue

    var body: some View {
        NavigationStack {
            ZStack {
                RRBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Pick a tenancy mode",
                            subtitle: "Standard is quick; Comprehensive covers more. You can change mode any time.",
                            systemImage: "questionmark.circle"
                        )

                        questionPanel
                        modeCard(.standard)
                        modeCard(.comprehensive)
                    }
                    .frame(maxWidth: PlatformLayout.preferredDialogWidth, alignment: .leading)
                    .padding(RRTheme.screenPadding)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Tenancy mode")
            .rrInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .id(appColourThemeRawValue)
    }

    private var questionPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                RRSectionHeader(
                    title: "Quick answer",
                    subtitle: "Will this tenancy have more than one tenant, OR do you need to track signed-on dates, a break clause, or attach an inventory document?"
                )

                HStack(spacing: 12) {
                    quickAnswerButton(
                        title: "No",
                        message: "Use Standard",
                        action: { pick(.standard) }
                    )
                    quickAnswerButton(
                        title: "Yes",
                        message: "Use Comprehensive",
                        action: { pick(.comprehensive) }
                    )
                }

                Text("Tap a mode below to pick it directly.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }
        }
    }

    private func quickAnswerButton(title: String, message: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(RRTypography.headline)
                    .foregroundStyle(.white)
                Text(message)
                    .font(RRTypography.footnote)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(RRColours.secondary)
            )
        }
        .buttonStyle(.plain)
    }

    private func modeCard(_ candidate: TenancyMode) -> some View {
        let isSelected = mode == candidate
        return Button {
            pick(candidate)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: candidate == .standard ? "doc.text" : "doc.text.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : RRColours.secondary)
                    .frame(width: RRTheme.tileIconSize, height: RRTheme.tileIconSize)
                    .background(
                        RoundedRectangle(cornerRadius: RRTheme.inlineBannerRadius, style: .continuous)
                            .fill(isSelected ? RRColours.secondary : RRColours.cardHighlight)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(candidate.rawValue)
                            .font(RRTypography.headline)
                            .foregroundStyle(RRColours.primary)
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(RRColours.success)
                        }
                    }
                    Text(candidate.summary)
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
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
    }

    private func pick(_ newMode: TenancyMode) {
        mode = newMode
        dismiss()
    }
}
