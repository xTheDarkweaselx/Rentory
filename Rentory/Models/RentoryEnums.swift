//
//  RentoryEnums.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

enum PropertyRecordType: String, CaseIterable, Codable, Identifiable {
    case house = "House"
    case flat = "Flat"
    case apartment = "Apartment"
    case garage = "Garage"
    case annex = "Annex"
    case other = "Other"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .house:
            return "house.fill"
        case .flat:
            return "building.2.fill"
        case .apartment:
            return "building.fill"
        case .garage:
            return "door.garage.closed"
        case .annex:
            return "house.and.flag.fill"
        case .other:
            return "square.grid.2x2.fill"
        }
    }

    var shortDescription: String {
        switch self {
        case .house:
            return "A house or whole rented home."
        case .flat:
            return "A flat within a larger building."
        case .apartment:
            return "An apartment within a block or development."
        case .garage:
            return "A storage garage or rented parking space."
        case .annex:
            return "An annex or self-contained part of a larger home."
        case .other:
            return "Any other kind of rented space."
        }
    }

    var extraFields: [PropertyExtraField] {
        switch self {
        case .house:
            return []
        case .flat:
            return [.buildingName, .spaceIdentifier, .floorLevel]
        case .apartment:
            return [.buildingName, .spaceIdentifier, .floorLevel]
        case .garage:
            return [.spaceIdentifier, .accessDetails]
        case .annex:
            return [.mainPropertyName, .accessDetails]
        case .other:
            return [.buildingName, .spaceIdentifier, .accessDetails]
        }
    }
}

enum PropertyExtraField: String, CaseIterable, Identifiable {
    case buildingName
    case spaceIdentifier
    case floorLevel
    case mainPropertyName
    case accessDetails

    var id: String { rawValue }

    func title(for recordType: PropertyRecordType) -> String {
        switch self {
        case .buildingName:
            switch recordType {
            case .flat:
                return "Building name"
            case .apartment:
                return "Block or building"
            case .other:
                return "Building or place name"
            default:
                return "Building name"
            }
        case .spaceIdentifier:
            switch recordType {
            case .flat:
                return "Flat number"
            case .apartment:
                return "Apartment number"
            case .garage:
                return "Garage or bay number"
            case .other:
                return "Space name or number"
            default:
                return "Number"
            }
        case .floorLevel:
            return "Floor"
        case .mainPropertyName:
            return "Main house name"
        case .accessDetails:
            switch recordType {
            case .garage:
                return "Access details"
            case .annex:
                return "Shared access notes"
            default:
                return "Access details"
            }
        }
    }
}

enum EvidenceCondition: String, CaseIterable, Codable {
    case notChecked = "Not checked"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case damaged = "Damaged"
    case missing = "Missing"
    case notApplicable = "Not applicable"
}

enum EvidencePhase: String, CaseIterable, Codable {
    case moveIn = "Move-in"
    case duringTenancy = "During tenancy"
    case moveOut = "Move-out"
}

enum DocumentType: String, CaseIterable, Codable {
    case tenancyAgreement = "Tenancy agreement"
    case depositCertificate = "Deposit protection certificate"
    case checkInInventory = "Check-in inventory"
    case checkOutReport = "Check-out report"
    case cleaningReceipt = "Cleaning receipt"
    case repairReceipt = "Repair receipt"
    case meterReading = "Meter reading"
    case messageScreenshot = "Message screenshot"
    case rentPaymentRecord = "Rent payment record"
    case other = "Other"
}

enum TimelineEventType: String, CaseIterable, Codable {
    case moveIn = "Move-in"
    case inventoryReviewed = "Inventory reviewed"
    case issueNoticed = "Issue noticed"
    case issueReported = "Issue reported"
    case repairRequested = "Repair requested"
    case repairCompleted = "Repair completed"
    case cleaningCompleted = "Cleaning completed"
    case inspection = "Inspection"
    case moveOut = "Move-out"
    case depositDiscussion = "Deposit discussion"
    case other = "Other"
}

enum RoomType: String, CaseIterable, Codable {
    case hallway = "Hallway"
    case livingRoom = "Living room"
    case kitchen = "Kitchen"
    case bedroom = "Bedroom"
    case bathroom = "Bathroom"
    case ensuite = "Ensuite"
    case utility = "Utility"
    case garden = "Garden / outdoor"
    case garage = "Garage / parking"
    case other = "Other"
}
