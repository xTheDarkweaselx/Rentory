//
//  ExportPreviewSummaryView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct ExportPreviewSummaryView: View {
    let options: ExportOptions

    var body: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Preview")
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)

                ForEach(summaryLines, id: \.self) { line in
                    Text(line)
                        .font(RRTypography.body)
                        .foregroundStyle(RRColours.mutedText)
                }
            }
        }
    }

    private var summaryLines: [String] {
        [
            options.includePhotos ? "Photos will be included" : "Photos will not be included",
            options.includeFullAddress ? "Full address will be included" : "Full address will not be included",
            options.includeDepositDetails ? "Deposit details will be included" : "Deposit details will not be included",
            options.includeDocumentsList ? "Documents list will be included" : "Documents list will not be included",
            options.includeTimeline ? "Timeline will be included" : "Timeline will not be included",
        ]
    }
}
