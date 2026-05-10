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
            return "Default"
        case .appIcon:
            return "Sunset Warmth"
        }
    }

    var description: String {
        switch self {
        case .defaultLook:
            return "Use Rentory’s current calm blue look."
        case .appIcon:
            return "Use a warmer orange, coral and pink look for a brighter feel."
        }
    }

    static var current: AppColourTheme {
        AppColourTheme(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .defaultLook
    }
}
