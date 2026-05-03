//
//  DocumentRowView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct DocumentRowView: View {
    let document: DocumentRecord

    var body: some View {
        RRGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    RRIconBadge(systemName: "doc.text", tint: RRColours.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(document.displayName)
                            .font(RRTypography.headline)
                            .foregroundStyle(RRColours.primary)

                        Text(document.documentType.rawValue)
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.mutedText)
                    }
                }

                if let documentDate = document.documentDate {
                    Text("Dated \(documentDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                }

                HStack(spacing: 10) {
                    Text("Added \(document.addedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(RRTypography.caption)
                        .foregroundStyle(RRColours.mutedText)

                    if document.includeInExport {
                        RRProgressPill(title: "Included in report", tint: RRColours.secondary)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Opens this document.")
    }

    private var accessibilitySummary: String {
        var parts = [document.displayName, document.documentType.rawValue]
        if let documentDate = document.documentDate {
            parts.append("Dated \(documentDate.formatted(date: .abbreviated, time: .omitted))")
        }
        if document.includeInExport {
            parts.append("Included in report")
        }
        return parts.joined(separator: ", ")
    }
}
