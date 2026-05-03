//
//  CompletionScoreCard.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct CompletionScoreCard: View {
    let result: CompletionScoreResult
    let viewProgressAction: () -> Void

    var body: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(result.statusTitle)
                            .font(RRTypography.title)
                            .foregroundStyle(RRColours.primary)

                        Text(result.shortMessage)
                            .font(RRTypography.body)
                            .foregroundStyle(RRColours.mutedText)
                    }

                    Spacer(minLength: 12)

                    Text("\(result.percentage)%")
                        .font(RRTypography.title)
                        .foregroundStyle(RRColours.secondary)
                }

                ProgressView(value: Double(result.percentage), total: 100)
                    .tint(RRColours.secondary)
                    .accessibilityLabel("Record progress, \(result.percentage) percent")

                if !result.suggestedNextItems.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(result.suggestedNextItems.prefix(2)), id: \.self) { item in
                            Label(item, systemImage: "checklist")
                                .font(RRTypography.footnote)
                                .foregroundStyle(RRColours.mutedText)
                        }
                    }
                }

                RRSecondaryButton(title: "View progress", action: viewProgressAction)
            }
            .accessibilityElement(children: .contain)
        }
    }
}
