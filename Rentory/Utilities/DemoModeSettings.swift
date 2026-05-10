//
//  DemoModeSettings.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import Foundation

enum DemoModeSettings {
    static let demoRecordName = "Demo rental record"
    static let demoTownCity = "Sampletown"
    static let demoPostcode = "AB1 2CD"
    static let demoRecordNote = "Sample data for testing and screenshots only."
    static let demoMarker = "[Rentory sample data]"

    private static let demoPropertyIdentifierKey = "debugDemoPropertyIdentifier"

    static var demoPropertyIdentifier: UUID? {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: demoPropertyIdentifierKey) else {
                return nil
            }

            return UUID(uuidString: rawValue)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.uuidString, forKey: demoPropertyIdentifierKey)
            } else {
                UserDefaults.standard.removeObject(forKey: demoPropertyIdentifierKey)
            }
        }
    }

    static func matchesDemoRecord(_ propertyPack: PropertyPack) -> Bool {
        if let demoPropertyIdentifier, propertyPack.id == demoPropertyIdentifier {
            return true
        }

        return (
            propertyPack.nickname == demoRecordName
            && propertyPack.townCity == demoTownCity
            && propertyPack.postcode == demoPostcode
            && propertyPack.notes?.contains(demoRecordNote) == true
        ) || propertyPack.notes?.contains(demoMarker) == true
    }
}
