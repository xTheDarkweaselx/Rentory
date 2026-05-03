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
        .buttonStyle(RRPrimaryButtonStyle())
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
        .buttonStyle(RRSecondaryButtonStyle())
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
        .buttonStyle(RRDestructiveButtonStyle())
            .disabled(isDisabled)
    }
}

private struct RRPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.white)
            .background(
                RoundedRectangle(cornerRadius: RRTheme.buttonRadius, style: .continuous)
                    .fill(Color.accentColor.opacity(configuration.isPressed ? 0.82 : 0.94))
            )
            .overlay {
                RoundedRectangle(cornerRadius: RRTheme.buttonRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: Color.accentColor.opacity(configuration.isPressed ? 0.08 : 0.18), radius: 16, x: 0, y: 10)
            .opacity(configuration.isPressed ? 0.96 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

private struct RRSecondaryButtonStyle: ButtonStyle {
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
            .opacity(configuration.isPressed ? 0.94 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

private struct RRDestructiveButtonStyle: ButtonStyle {
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
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}
