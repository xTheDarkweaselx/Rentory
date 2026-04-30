//
//  ReportReadyView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct ReportReadyView: View {
    let reportURL: URL

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.badge.checkmark")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(RRColours.secondary)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Report ready")
                    .font(RRTypography.largeTitle)
                    .foregroundStyle(RRColours.primary)

                Text("Your report has been created on this device. Choose where to save or share it.")
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)
                    .multilineTextAlignment(.center)
            }

            ReportShareView(reportURL: reportURL)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityHint("Opens the share sheet.")

            Spacer()
        }
        .padding(24)
        .background(RRColours.groupedBackground.ignoresSafeArea())
        .navigationTitle("Report ready")
        .rrInlineNavigationTitle()
    }
}
