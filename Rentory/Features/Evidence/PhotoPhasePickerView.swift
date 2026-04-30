//
//  PhotoPhasePickerView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct PhotoPhasePickerView: View {
    let onSelectPhase: (EvidencePhase) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            RRSectionHeader(
                title: "Add a photo",
                subtitle: "Choose where this photo belongs in your record."
            )

            VStack(spacing: 12) {
                ForEach(EvidencePhase.allCases, id: \.self) { phase in
                    Button {
                        onSelectPhase(phase)
                    } label: {
                        RRCard {
                            HStack {
                                Text(phase.rawValue)
                                    .font(RRTypography.headline)
                                    .foregroundStyle(RRColours.primary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(RRColours.mutedText)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
    }
}
