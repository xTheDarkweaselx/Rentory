//
//  RRProgressDialog.swift
//  Rentory
//
//  Created by OpenAI on 10/05/2026.
//

import SwiftUI

struct RRProgressDialog: View {
    let title: String
    let message: String
    let progress: Double
    let cancelTitle: String
    let cancelAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.16)
                .ignoresSafeArea()

            RRGlassPanel {
                VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                    HStack(alignment: .top, spacing: RRTheme.controlSpacing) {
                        RRIconBadge(systemName: "wand.and.stars", tint: RRColours.secondary, size: 44)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                            Text(title)
                                .font(RRTypography.headline)
                                .foregroundStyle(RRColours.primary)

                            Text(message)
                                .font(RRTypography.body)
                                .foregroundStyle(RRColours.mutedText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    ProgressView(value: min(max(progress, 0), 1))
                        .progressViewStyle(.linear)
                        .tint(RRColours.secondary)

                    HStack {
                        Spacer()

                        RRSecondaryButton(title: cancelTitle) {
                            cancelAction()
                        }
                        .frame(maxWidth: 180)
                    }
                }
            }
            .frame(maxWidth: 440)
            .padding(24)
        }
    }
}
