//
//  ReportShareView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct ReportShareView: View {
    let reportURL: URL

    var body: some View {
        ShareLink(item: reportURL) {
            Label("Share report", systemImage: "square.and.arrow.up")
        }
        .accessibilityHint("Opens the share sheet.")
    }
}
