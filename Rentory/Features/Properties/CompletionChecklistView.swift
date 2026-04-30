//
//  CompletionChecklistView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct CompletionChecklistView: View {
    let result: CompletionScoreResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                RRSectionHeader(
                    title: "Record progress",
                    subtitle: "This only shows how much you have added to Rentory. It does not judge the content."
                ) {
                    RRProgressPill(title: "\(result.percentage)%")
                }

                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(result.statusTitle)
                            .font(RRTypography.title)
                            .foregroundStyle(RRColours.primary)

                        Text(result.shortMessage)
                            .font(RRTypography.body)
                            .foregroundStyle(RRColours.mutedText)

                        ProgressView(value: Double(result.percentage), total: 100)
                            .tint(RRColours.secondary)
                    }
                }

                if !result.completedItems.isEmpty {
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Added")
                                .font(RRTypography.headline)
                                .foregroundStyle(RRColours.primary)

                            ForEach(result.completedItems, id: \.self) { item in
                                Label(item, systemImage: "checkmark.circle.fill")
                                    .font(RRTypography.body)
                                    .foregroundStyle(RRColours.secondary)
                            }
                        }
                    }
                }

                if !result.suggestedNextItems.isEmpty {
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Next steps")
                                .font(RRTypography.headline)
                                .foregroundStyle(RRColours.primary)

                            ForEach(result.suggestedNextItems, id: \.self) { item in
                                Label(item, systemImage: "circle")
                                    .font(RRTypography.body)
                                    .foregroundStyle(RRColours.mutedText)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(RRColours.groupedBackground.ignoresSafeArea())
        .navigationTitle("Record progress")
        .rrInlineNavigationTitle()
    }
}
