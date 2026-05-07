//
//  RRSheetHeader.swift
//  Rentory
//
//  Created by Adam Ibrahim on 01/05/2026.
//

import SwiftUI

struct RRSheetHeader: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    var showsCloseButton = false
    var closeLabel = "Close"
    var closeAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: RRTheme.cardSpacing) {
            if let systemImage {
                RRIconBadge(systemName: systemImage, tint: RRColours.secondary, size: 48)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                Text(title)
                    .font(RRTypography.title)
                    .foregroundStyle(RRColours.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(RRTypography.body)
                        .foregroundStyle(RRColours.mutedText)
                }
            }

            Spacer(minLength: RRTheme.controlSpacing)

            if showsCloseButton, let closeAction {
                Button(action: closeAction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(RRColours.primary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityLabel(closeLabel)
            }
        }
        .padding(RRTheme.cardSpacing)
        .background(
            RRTheme.cardMaterial,
            in: RoundedRectangle(cornerRadius: RRTheme.cardRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: RRTheme.cardRadius, style: .continuous)
                .stroke(RRColours.border.opacity(0.2), lineWidth: 1)
        }
    }
}
