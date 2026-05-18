//
//  AppColourTheme.swift
//  Rentory
//
//  Created by OpenAI on 10/05/2026.
//

import SwiftUI

enum AppColourTheme: String, CaseIterable, Identifiable {
    case defaultLook
    case appIcon

    static let storageKey = "rentory.appColourTheme"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .defaultLook:
            return "Violet Glow"
        case .appIcon:
            return "Sunset Orange"
        }
    }

    var description: String {
        switch self {
        case .defaultLook:
            return "Use a purple and indigo look inspired by Rentory’s app icon."
        case .appIcon:
            return "Use a warmer orange and amber look for a brighter feel."
        }
    }

    static var current: AppColourTheme {
        AppColourTheme(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .defaultLook
    }
}

private struct ObservesAppColourTheme: ViewModifier {
    @AppStorage(AppColourTheme.storageKey) private var themeRawValue = AppColourTheme.defaultLook.rawValue

    func body(content: Content) -> some View {
        content.id(themeRawValue)
    }
}

extension View {
    /// Re-renders the wrapped view when the app's colour theme changes.
    /// Use on row views inside Lists / LazyVStacks whose bodies read
    /// RRColours.* but don't otherwise observe the theme — SwiftUI's
    /// row caching can otherwise keep stale colours until the row's
    /// own input parameters change.
    func observesAppColourTheme() -> some View {
        modifier(ObservesAppColourTheme())
    }
}
