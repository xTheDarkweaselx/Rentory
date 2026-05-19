//
//  WidgetTheme.swift
//  RentoryWidgets
//
//  Mirrors the subset of RR* design tokens widgets need. Widget bundles
//  can't import the main app's design system, so we keep a small,
//  self-contained palette + typography in sync with RRColours /
//  RRTypography.
//

import SwiftUI

enum WidgetTheme {
    enum Palette {
        static let primary = Color.primary
        static let mutedText = Color.secondary
        static let secondary = Color(red: 0.32, green: 0.16, blue: 0.71)
        static let success = Color(red: 0.16, green: 0.62, blue: 0.34)
        static let warning = Color(red: 0.94, green: 0.55, blue: 0.13)
        static let danger = Color(red: 0.83, green: 0.18, blue: 0.18)
    }

    enum Typography {
        static let title = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 14, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 13, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 11, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 10, weight: .medium, design: .rounded)
    }

    /// Days-until-due window thresholds. Match the colour ramps used in
    /// RemindersCard so the dashboard and the widget feel related.
    static func urgencyTint(for daysUntilDue: Int) -> Color {
        switch daysUntilDue {
        case ..<0: return Palette.danger
        case 0...3: return Palette.warning
        case 4...14: return Palette.secondary
        default: return Palette.success
        }
    }
}
