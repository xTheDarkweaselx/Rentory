//
//  UpgradePromptView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct UpgradePromptContent: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
}

struct UpgradePromptView: View {
    let title: String
    let message: String
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

    var body: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(RRTypography.title)
                    .foregroundStyle(RRColours.primary)

                Text(message)
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)

                VStack(spacing: 12) {
                    RRPrimaryButton(title: "Unlock Rentory", action: primaryAction)
                    RRSecondaryButton(title: "Not now", action: secondaryAction)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
