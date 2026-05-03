//
//  RRProgressPill.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RRProgressPill: View {
    let title: String
    var tint: Color = RRColours.secondary

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)

            Text(title)
                .font(RRTypography.caption.weight(.semibold))
        }
        .foregroundStyle(RRColours.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(tint.opacity(0.22), lineWidth: 1)
        }
    }
}

#Preview {
    RRProgressPill(title: "Getting started")
        .padding()
}
