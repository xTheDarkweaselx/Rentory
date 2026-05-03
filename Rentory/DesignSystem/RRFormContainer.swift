//
//  RRFormContainer.swift
//  Rentory
//
//  Created by OpenAI on 03/05/2026.
//

import SwiftUI

struct RRFormContainer<Content: View>: View {
    var maxWidth: CGFloat = PlatformLayout.preferredFormMaxWidth
    private let content: Content

    init(
        maxWidth: CGFloat = PlatformLayout.preferredFormMaxWidth,
        @ViewBuilder content: () -> Content
    ) {
        self.maxWidth = maxWidth
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                content
            }
            .frame(maxWidth: maxWidth, alignment: .leading)
            .padding(.horizontal, PlatformLayout.formHorizontalPadding)
            .padding(.vertical, PlatformLayout.formVerticalPadding)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .scrollIndicators(.hidden)
        .background(RRBackgroundView())
    }
}
