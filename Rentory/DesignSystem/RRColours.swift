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
    static func secondary(for theme: AppColourTheme) -> Color { palette(for: theme).secondary }
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
        palette(for: AppColourTheme.current)
    }

    private static func palette(for theme: AppColourTheme) -> RRColourPalette {
        switch theme {
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
        secondary: Color(red: 0.48, green: 0.30, blue: 0.92),
        background: platformBackground,
        groupedBackground: Color(red: 0.57, green: 0.42, blue: 1.00).opacity(0.12),
        cardBackground: Color(red: 0.48, green: 0.30, blue: 0.92).opacity(0.10),
        cardHighlight: Color(red: 0.78, green: 0.68, blue: 1.00).opacity(0.24),
        success: Color.green.opacity(0.8),
        warning: Color.orange.opacity(0.8)
    )

    static let appIcon = RRColourPalette(
        secondary: Color(red: 0.96, green: 0.48, blue: 0.10),
        background: platformBackground,
        groupedBackground: Color(red: 1.00, green: 0.72, blue: 0.24).opacity(0.16),
        cardBackground: Color(red: 1.00, green: 0.58, blue: 0.18).opacity(0.13),
        cardHighlight: Color(red: 1.00, green: 0.78, blue: 0.30).opacity(0.26),
        success: Color(red: 0.94, green: 0.58, blue: 0.10).opacity(0.82),
        warning: Color(red: 0.98, green: 0.52, blue: 0.08).opacity(0.86)
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
