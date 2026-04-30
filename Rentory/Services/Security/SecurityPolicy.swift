//
//  SecurityPolicy.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

enum SecurityPolicy {
    static let appName = "Rentory"
    static let isLocalFirst = true
    static let allowsNetworking = false
    static let allowsAnalytics = false
    static let allowsAccountCreation = false
    static let allowsThirdPartyAI = false
    static let allowsAdvertisingTracking = false
    static let storesRecordsLocallyByDefault = true

    static let appBoundaryStatement = "Rentory helps you organise your own rental records. It does not give legal, financial or tenancy advice."
    static let localFirstStatement = "Your rental records stay on your device by default. No account is needed."

    // User records must not be sent to external services.
    // User records must not be logged.
    // Reports, when implemented later, must be created on device and shared only when the user chooses.
    // SwiftData should store record information only, not large photo or document files.
}
