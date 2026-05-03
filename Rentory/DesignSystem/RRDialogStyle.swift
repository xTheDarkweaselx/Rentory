//
//  RRDialogStyle.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RRDialogStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: 420)
            .padding(RRTheme.screenPadding)
            .background(RRTheme.panelMaterial, in: RoundedRectangle(cornerRadius: RRTheme.panelRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: RRTheme.panelRadius, style: .continuous)
                    .stroke(RRColours.border.opacity(0.24), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(RRTheme.strongShadowOpacity), radius: 24, x: 0, y: 12)
    }
}

extension View {
    func rrDialogStyle() -> some View {
        modifier(RRDialogStyle())
    }
}
