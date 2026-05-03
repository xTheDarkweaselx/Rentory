//
//  RRGlassCard.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RRGlassCard<Content: View>: View {
    var padding: CGFloat = RRTheme.screenPadding
    var showsShadow = true
    private let content: Content

    init(
        padding: CGFloat = RRTheme.screenPadding,
        showsShadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.showsShadow = showsShadow
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RRTheme.cardMaterial, in: RoundedRectangle(cornerRadius: RRTheme.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: RRTheme.cardRadius, style: .continuous)
                    .stroke(RRColours.border.opacity(RRTheme.borderOpacity), lineWidth: 1)
            }
            .shadow(
                color: Color.black.opacity(showsShadow ? RRTheme.softShadowOpacity : 0),
                radius: showsShadow ? 20 : 0,
                x: 0,
                y: showsShadow ? 10 : 0
            )
    }
}
