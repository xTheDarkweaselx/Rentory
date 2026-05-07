//
//  PurchaseRowView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import StoreKit
import SwiftUI

struct PurchaseRowView: View {
    let product: Product?
    let fallbackPriceText: String?

    private var priceText: String {
        product?.displayPrice ?? fallbackPriceText ?? "Price unavailable"
    }

    var body: some View {
        RRCard {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Lifetime unlock")
                        .font(RRTypography.headline)
                        .foregroundStyle(RRColours.primary)

                    Text("One-time purchase")
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                }

                Spacer(minLength: 12)

                Text(priceText)
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Lifetime unlock, \(priceText)")
    }
}
