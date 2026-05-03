//
//  RRSuccessView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 01/05/2026.
//

import SwiftUI

struct RRSuccessView<ActionContent: View>: View {
    let title: String
    let message: String
    var systemImage: String = "checkmark.circle.fill"
    @ViewBuilder private let actionContent: ActionContent

    init(
        title: String,
        message: String,
        systemImage: String = "checkmark.circle.fill",
        @ViewBuilder actionContent: () -> ActionContent = { EmptyView() }
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionContent = actionContent()
    }

    var body: some View {
        RRGlassPanel {
            VStack(spacing: 18) {
                RRIconBadge(systemName: systemImage, tint: RRColours.success, size: 64)
                    .accessibilityHidden(true)

                VStack(spacing: RRTheme.smallSpacing) {
                    Text(title)
                        .font(RRTypography.largeTitle)
                        .foregroundStyle(RRColours.primary)

                    Text(message)
                        .font(RRTypography.body)
                        .foregroundStyle(RRColours.mutedText)
                        .multilineTextAlignment(.center)
                }

                actionContent
            }
            .frame(maxWidth: .infinity)
        }
    }
}
