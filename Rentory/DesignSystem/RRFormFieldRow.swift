//
//  RRFormFieldRow.swift
//  Rentory
//
//  Created by OpenAI on 03/05/2026.
//

import SwiftUI

struct RRFormFieldRow<Content: View>: View {
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(RRTypography.footnote.weight(.semibold))
                .foregroundStyle(RRColours.primary)

            content

            if let message, !message.isEmpty {
                Text(message)
                    .font(RRTypography.caption)
                    .foregroundStyle(RRColours.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
