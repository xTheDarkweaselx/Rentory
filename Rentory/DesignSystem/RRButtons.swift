//
//  RRButtons.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RRPrimaryButton: View {
    let title: String
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RRTypography.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
        }
        .buttonStyle(RRPrimaryButtonStyle(isDisabled: isDisabled))
            .disabled(isDisabled)
    }
}

struct RRSecondaryButton: View {
    let title: String
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RRTypography.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
        }
        .buttonStyle(RRSecondaryButtonStyle(isDisabled: isDisabled))
            .disabled(isDisabled)
    }
}

struct RRDestructiveButton: View {
    let title: String
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Text(title)
                .font(RRTypography.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
        }
        .buttonStyle(RRDestructiveButtonStyle(isDisabled: isDisabled))
            .disabled(isDisabled)
    }
}

// Each style takes `isDisabled` as a plain stored property and drops
// the control's opacity + suppresses the press feedback when it's set
// — without this, a disabled `RRDestructiveButton` looked identical to
// an enabled one and silently swallowed taps. We pass `isDisabled`
// through explicitly instead of reading `@Environment(\.isEnabled)`
// from inside a nested view because the project's
// SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor + the ButtonStyle
// protocol's nonisolated requirement made the nested-view pattern
// finicky to declare cleanly.

private struct RRPrimaryButtonStyle: ButtonStyle {
    var isDisabled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.white)
            .background(
                RoundedRectangle(cornerRadius: RRTheme.buttonRadius, style: .continuous)
                    .fill(RRColours.secondary.opacity(configuration.isPressed ? 0.82 : 0.94))
            )
            .overlay {
                RoundedRectangle(cornerRadius: RRTheme.buttonRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: RRColours.secondary.opacity(configuration.isPressed ? 0.08 : 0.18), radius: 16, x: 0, y: 10)
            .opacity(isDisabled ? 0.45 : (configuration.isPressed ? 0.96 : 1))
            .scaleEffect(!isDisabled && configuration.isPressed ? 0.99 : 1)
    }
}

private struct RRSecondaryButtonStyle: ButtonStyle {
    var isDisabled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(RRColours.primary)
            .background(
                RoundedRectangle(cornerRadius: RRTheme.buttonRadius, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay {
                RoundedRectangle(cornerRadius: RRTheme.buttonRadius, style: .continuous)
                    .stroke(RRColours.border.opacity(0.24), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.04 : 0.08), radius: 14, x: 0, y: 8)
            .opacity(isDisabled ? 0.45 : (configuration.isPressed ? 0.94 : 1))
            .scaleEffect(!isDisabled && configuration.isPressed ? 0.99 : 1)
    }
}

private struct RRDestructiveButtonStyle: ButtonStyle {
    var isDisabled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(RRColours.danger)
            .background(
                RoundedRectangle(cornerRadius: RRTheme.buttonRadius, style: .continuous)
                    .fill(RRColours.danger.opacity(0.08))
            )
            .overlay {
                RoundedRectangle(cornerRadius: RRTheme.buttonRadius, style: .continuous)
                    .stroke(RRColours.danger.opacity(0.18), lineWidth: 1)
            }
            .opacity(isDisabled ? 0.45 : (configuration.isPressed ? 0.9 : 1))
            .scaleEffect(!isDisabled && configuration.isPressed ? 0.99 : 1)
    }
}
