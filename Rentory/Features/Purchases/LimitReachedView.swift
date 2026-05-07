//
//  LimitReachedView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct LimitReachedView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let message: String

    @State private var isShowingPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                RRColours.groupedBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "lock.open.display")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(RRColours.secondary)
                        .accessibilityHidden(true)

                    UpgradePromptView(
                        title: title,
                        message: message,
                        primaryAction: {
                            isShowingPaywall = true
                        },
                        secondaryAction: {
                            dismiss()
                        }
                    )
                }
                .padding(24)
                .frame(maxWidth: 560)
            }
            .navigationTitle("Unlock Rentory")
            .rrInlineNavigationTitle()
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
        }
    }
}
