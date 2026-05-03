//
//  RRGlassPanel.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RRGlassPanel<Content: View>: View {
    var padding: CGFloat = 24
    private let content: Content

    init(
        padding: CGFloat = 24,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RRTheme.panelMaterial, in: RoundedRectangle(cornerRadius: RRTheme.panelRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: RRTheme.panelRadius, style: .continuous)
                    .stroke(RRColours.border.opacity(0.22), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(RRTheme.strongShadowOpacity), radius: 26, x: 0, y: 14)
    }
}
