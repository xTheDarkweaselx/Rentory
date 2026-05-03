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
    static let secondary = Color.accentColor
    static let background = platformBackground
    static let groupedBackground = platformGroupedBackground
    static let cardBackground = platformCardBackground
    static let cardHighlight = Color.white.opacity(0.22)
    static let success = Color.green.opacity(0.8)
    static let warning = Color.orange.opacity(0.8)
    static let danger = Color.red.opacity(0.75)
    static let mutedText = Color.secondary
    static let border = Color.primary.opacity(0.08)

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
