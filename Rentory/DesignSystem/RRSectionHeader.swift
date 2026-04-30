//
//  RRSectionHeader.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RRSectionHeader<TrailingContent: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let trailingContent: TrailingContent

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailingContent: () -> TrailingContent = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailingContent = trailingContent()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(RRTypography.title)
                    .foregroundStyle(RRColours.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                }
            }

            Spacer(minLength: 12)

            trailingContent
        }
    }
}

#Preview {
    RRSectionHeader(title: "Rental records", subtitle: "Your records stay on your device") {
        RRProgressPill(title: "Getting started")
    }
    .padding()
}
