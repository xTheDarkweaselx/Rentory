//
//  RentoryUserProfile.swift
//  Rentory
//
//  Created by Adam Ibrahim on 18/05/2026.
//

import Foundation

enum RentoryUserProfile: String, CaseIterable, Codable, Identifiable {
    case renter = "Renter"
    case landlord = "Landlord"

    var id: String { rawValue }

    static let storageKey = "rentoryUserProfile"
    static let defaultProfile: RentoryUserProfile = .renter

    var systemImage: String {
        switch self {
        case .renter:
            return "house.fill"
        case .landlord:
            return "key.fill"
        }
    }

    var shortSummary: String {
        switch self {
        case .renter:
            return "Keep a defensible record of your rented home — rooms, photos, deposit details, repairs, move-out checks."
        case .landlord:
            return "Manage rental properties — tenancies, compliance dates, periodic inspections, deposit protection records."
        }
    }

    var detailedSummary: String {
        switch self {
        case .renter:
            return "Renter mode focuses on the prompts most tenants need: move-in checks, deposit follow-up, repair reports and move-out evidence."
        case .landlord:
            return "Landlord mode adds compliance prompts: gas safety, EICR, EPC renewals, tenancy renewals and periodic inspections."
        }
    }
}
