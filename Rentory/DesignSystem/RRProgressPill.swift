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
        Text(title)
            .font(RRTypography.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            }
    }
}

#Preview {
    RRProgressPill(title: "Getting started")
        .padding()
}
