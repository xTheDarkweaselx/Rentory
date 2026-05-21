//
//  RRTheme.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

enum RRTheme {
    static let screenPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 20
    static let cardSpacing: CGFloat = 16
    static let controlSpacing: CGFloat = 12
    static let smallSpacing: CGFloat = 8

    static let iconSize: CGFloat = 18
    static let badgeIconSize: CGFloat = 20
    static let tileIconSize: CGFloat = 40
    static let heroIconSize: CGFloat = 42

    static let cornerRadius: CGFloat = 18
    static let cardRadius: CGFloat = 26
    static let panelRadius: CGFloat = 30
    static let buttonRadius: CGFloat = 18
    /// Smaller radius used by inline banners and tile-sized chrome where
    /// the larger `cornerRadius` would look heavy. Pick this over
    /// hardcoding a literal in feature views.
    static let inlineBannerRadius: CGFloat = 10

    static let borderOpacity: Double = 0.18
    static let softShadowOpacity: Double = 0.08
    static let strongShadowOpacity: Double = 0.14

    static let quickAnimation = Animation.easeInOut(duration: 0.2)
    static let standardAnimation = Animation.spring(duration: 0.36, bounce: 0.12)

    static let cardMaterial: Material = .regularMaterial
    static let panelMaterial: Material = .thinMaterial
    static let accentMaterial: Material = .ultraThinMaterial
}
