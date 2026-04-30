//
//  RRErrorStateView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RRErrorStateView: View {
    let symbolName: String
    let title: String
    let message: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?

    init(
        symbolName: String = "exclamationmark.circle",
        title: String,
        message: String,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.symbolName = symbolName
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }

    var body: some View {
        RRCard {
            VStack(spacing: 18) {
                Image(systemName: symbolName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(RRColours.warning)
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
                    RRSecondaryButton(title: buttonTitle, action: buttonAction)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .accessibilityElement(children: .combine)
    }
}
