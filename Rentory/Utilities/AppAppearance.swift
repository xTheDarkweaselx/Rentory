//
//  AppAppearance.swift
//  Rentory
//
//  Created by OpenAI on 10/05/2026.
//

import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case deviceDefault
    case light
    case dark

    static let storageKey = "rentory.appAppearance"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .deviceDefault:
            return "Device default"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var description: String {
        switch self {
        case .deviceDefault:
            return "Follow this device’s appearance setting."
        case .light:
            return "Keep Rentory in light mode."
        case .dark:
            return "Keep Rentory in dark mode."
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .deviceDefault:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
