//
//  RRConditionBadge.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RRConditionBadge: View {
    let condition: EvidenceCondition

    private var tint: Color {
        switch condition {
        case .good:
            return RRColours.success
        case .fair:
            return RRColours.warning.opacity(0.75)
        case .poor:
            return RRColours.warning
        case .damaged, .missing:
            return RRColours.danger
        case .notChecked, .notApplicable:
            return RRColours.mutedText.opacity(0.9)
        }
    }

    private var symbolName: String {
        switch condition {
        case .good:
            return "checkmark.circle.fill"
        case .fair:
            return "circle.lefthalf.filled"
        case .poor:
            return "exclamationmark.circle.fill"
        case .damaged:
            return "wrench.and.screwdriver.fill"
        case .missing:
            return "minus.circle.fill"
        case .notApplicable:
            return "slash.circle.fill"
        case .notChecked:
            return "questionmark.circle.fill"
        }
    }

    var body: some View {
        Label(condition.rawValue, systemImage: symbolName)
            .font(RRTypography.caption.weight(.semibold))
            .foregroundStyle(RRColours.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tint.opacity(0.24), lineWidth: 1)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Condition: \(condition.rawValue)")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        RRConditionBadge(condition: .notChecked)
        RRConditionBadge(condition: .good)
        RRConditionBadge(condition: .damaged)
    }
    .padding()
}
