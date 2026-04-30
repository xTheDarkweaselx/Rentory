//
//  PropertyFormSupport.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

func trimmed(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
}

func optionalText(_ value: String) -> String? {
    let trimmedValue = trimmed(value)
    return trimmedValue.isEmpty ? nil : trimmedValue
}

func isLightweightEmail(_ value: String) -> Bool {
    let parts = value.split(separator: "@")

    guard parts.count == 2,
          !parts[0].isEmpty,
          !parts[1].isEmpty,
          parts[1].contains("."),
          !value.contains(" ") else {
        return false
    }

    return true
}
