//
//  RRFormSection.swift
//  Rentory
//
//  Created by OpenAI on 03/05/2026.
//

import SwiftUI

struct RRFormSection<Content: View>: View {
    let title: String
    var message: String?
    private let content: Content

    init(
        title: String,
        message: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.message = message
        self.content = content()
    }

    var body: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(RRTypography.title)
                        .foregroundStyle(RRColours.primary)

                    if let message, !message.isEmpty {
                        Text(message)
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.mutedText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                content
            }
        }
    }
}
