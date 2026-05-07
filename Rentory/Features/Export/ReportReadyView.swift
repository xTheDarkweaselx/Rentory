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
        RRMacSheetContainer(maxWidth: 760, minHeight: PlatformLayout.isMac ? 520 : nil) {
            VStack(spacing: 24) {
                Spacer()

                RRSuccessView(
                    title: "Report ready",
                    message: "Your report has been created on this device. You can share it now or keep it here for later.",
                    systemImage: "doc.badge.checkmark"
                ) {
                    ReportShareView(reportURL: reportURL)
                        .buttonStyle(.glassProminent)
                        .accessibilityHint("Opens the share sheet.")
                }

                Spacer()
            }
        }
        .navigationTitle("Report ready")
        .rrInlineNavigationTitle()
    }
}
