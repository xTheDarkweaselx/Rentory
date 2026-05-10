//
//  RRColours.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum RRColours {
    static let primary = Color.primary
    static var secondary: Color { palette.secondary }
    static var background: Color { palette.background }
    static var groupedBackground: Color { palette.groupedBackground }
    static var cardBackground: Color { palette.cardBackground }
    static var cardHighlight: Color { palette.cardHighlight }
    static var success: Color { palette.success }
    static var warning: Color { palette.warning }
    static let danger = Color.red.opacity(0.75)
    static let mutedText = Color.secondary
    static let border = Color.primary.opacity(0.08)

    private static var palette: RRColourPalette {
        switch AppColourTheme.current {
        case .defaultLook:
            return .defaultLook
        case .appIcon:
            return .appIcon
        }
    }
}

private struct RRColourPalette {
    let secondary: Color
    let background: Color
    let groupedBackground: Color
    let cardBackground: Color
    let cardHighlight: Color
    let success: Color
    let warning: Color

    static let defaultLook = RRColourPalette(
        secondary: Color.accentColor,
        background: platformBackground,
        groupedBackground: platformGroupedBackground,
        cardBackground: platformCardBackground,
        cardHighlight: Color.white.opacity(0.22),
        success: Color.green.opacity(0.8),
        warning: Color.orange.opacity(0.8)
    )

    static let appIcon = RRColourPalette(
        secondary: Color(red: 0.96, green: 0.30, blue: 0.22),
        background: platformBackground,
        groupedBackground: Color(red: 1.00, green: 0.72, blue: 0.33).opacity(0.18),
        cardBackground: Color(red: 1.00, green: 0.52, blue: 0.34).opacity(0.14),
        cardHighlight: Color(red: 1.00, green: 0.82, blue: 0.42).opacity(0.28),
        success: Color(red: 0.95, green: 0.55, blue: 0.12).opacity(0.82),
        warning: Color(red: 0.98, green: 0.42, blue: 0.18).opacity(0.86)
    )

#if canImport(UIKit)
    private static let platformBackground = Color(uiColor: .systemBackground)
    private static let platformGroupedBackground = Color(uiColor: .systemGroupedBackground)
    private static let platformCardBackground = Color(uiColor: .secondarySystemGroupedBackground)
#elseif canImport(AppKit)
    private static let platformBackground = Color(nsColor: .windowBackgroundColor)
    private static let platformGroupedBackground = Color(nsColor: .controlBackgroundColor)
    private static let platformCardBackground = Color(nsColor: .underPageBackgroundColor)
#else
    private static let platformBackground = Color.white
    private static let platformGroupedBackground = Color(white: 0.96)
    private static let platformCardBackground = Color(white: 0.92)
#endif
}
