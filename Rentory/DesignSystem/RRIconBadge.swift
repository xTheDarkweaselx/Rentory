//
//  RRIconBadge.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RRIconBadge: View {
    let systemName: String
    var tint: Color = RRColours.secondary
    var size: CGFloat = 42

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: RRTheme.cornerRadius, style: .continuous)
                .fill(RRTheme.accentMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: RRTheme.cornerRadius, style: .continuous)
                        .stroke(tint.opacity(0.18), lineWidth: 1)
                }

            Image(systemName: systemName)
                .font(.system(size: RRTheme.badgeIconSize, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
    }
}
