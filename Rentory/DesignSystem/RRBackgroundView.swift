//
//  RRBackgroundView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RRBackgroundView: View {
    var body: some View {
        ZStack {
            RRColours.background
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    RRColours.background,
                    RRColours.groupedBackground.opacity(0.94),
                    RRColours.cardHighlight.opacity(0.55),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(RRColours.secondary.opacity(0.08))
                .frame(width: 320, height: 320)
                .blur(radius: 48)
                .offset(x: -140, y: -260)

            Circle()
                .fill(RRColours.success.opacity(0.06))
                .frame(width: 260, height: 260)
                .blur(radius: 44)
                .offset(x: 160, y: 280)
        }
    }
}
