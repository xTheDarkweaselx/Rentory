//
//  RRFormContainer.swift
//  Rentory
//
//  Created by OpenAI on 03/05/2026.
//

import SwiftUI

struct RRFormContainer<Content: View>: View {
    @Environment(\.rrUsesEmbeddedNavigationLayout) private var usesEmbeddedNavigationLayout

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
        .background(formBackground)
    }

    /// When this form is embedded inside the wide Settings panel (which
    /// already paints its own RRBackgroundView), drawing a second one
    /// here stacks a nested rounded rectangle behind the sub-page
    /// content — the "box within a box" artifact. Skip it when embedded
    /// so the sub-page sits flat on the panel's background.
    @ViewBuilder
    private var formBackground: some View {
        if usesEmbeddedNavigationLayout {
            Color.clear
        } else {
            RRBackgroundView()
        }
    }
}
