//
//  RRLoadingView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RRLoadingView: View {
    let title: String
    let message: String?

    init(title: String, message: String? = nil) {
        self.title = title
        self.message = message
    }

    var body: some View {
        RRGlassPanel {
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)

                VStack(spacing: 8) {
                    Text(title)
                        .font(RRTypography.headline)
                        .foregroundStyle(RRColours.primary)
                        .multilineTextAlignment(.center)

                    if let message {
                        Text(message)
                            .font(RRTypography.body)
                            .foregroundStyle(RRColours.mutedText)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .accessibilityElement(children: .combine)
        .rrDialogStyle()
    }
}
