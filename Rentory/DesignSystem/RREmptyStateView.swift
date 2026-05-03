//
//  RREmptyStateView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RREmptyStateView: View {
    let symbolName: String
    let title: String
    let message: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    let secondaryButtonTitle: String?
    let secondaryButtonAction: (() -> Void)?

    init(
        symbolName: String,
        title: String,
        message: String,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil,
        secondaryButtonTitle: String? = nil,
        secondaryButtonAction: (() -> Void)? = nil
    ) {
        self.symbolName = symbolName
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
        self.secondaryButtonTitle = secondaryButtonTitle
        self.secondaryButtonAction = secondaryButtonAction
    }

    var body: some View {
        RRGlassPanel {
            VStack(spacing: 18) {
                RRIconBadge(systemName: symbolName, tint: RRColours.secondary, size: 60)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text(title)
                        .font(RRTypography.title)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(RRTypography.body)
                        .foregroundStyle(RRColours.mutedText)
                        .multilineTextAlignment(.center)
                }

                if let buttonTitle, let buttonAction {
                    RRPrimaryButton(title: buttonTitle, action: buttonAction)
                }

                if let secondaryButtonTitle, let secondaryButtonAction {
                    RRSecondaryButton(title: secondaryButtonTitle, action: secondaryButtonAction)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    RREmptyStateView(
        symbolName: "house",
        title: "No rental records yet",
        message: "Create your first record when you are ready.",
        buttonTitle: "Get started",
        buttonAction: {}
    )
    .padding()
    .background(RRColours.groupedBackground)
}
