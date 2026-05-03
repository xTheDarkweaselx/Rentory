//
//  RRCard.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RRCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        RRGlassCard(content: { content })
    }
}

#Preview {
    RRCard {
        Text("Card")
    }
    .padding()
    .background(RRColours.groupedBackground)
}
