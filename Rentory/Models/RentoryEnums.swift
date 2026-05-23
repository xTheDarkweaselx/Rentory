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

    var aggregateSeverity: Int {
        switch self {
        case .notChecked, .notApplicable:
            return 0
        case .good:
            return 1
        case .fair:
            return 2
        case .poor:
            return 3
        case .damaged:
            return 4
        case .missing:
            return 5
        }
    }

    var contributesToAggregate: Bool {
        switch self {
        case .notChecked, .notApplicable:
            return false
        default:
            return true
        }
    }
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
    case gasSafetyCertificate = "Gas safety certificate"
    case electricalSafetyReport = "Electrical safety report (EICR)"
    case energyPerformanceCertificate = "Energy performance certificate (EPC)"
    case rightToRentCheck = "Right to rent check"
    case other = "Other"

    var isLandlordOnly: Bool {
        switch self {
        case .gasSafetyCertificate, .electricalSafetyReport, .energyPerformanceCertificate, .rightToRentCheck:
            return true
        default:
            return false
        }
    }

    static func availableCases(for profile: RentoryUserProfile) -> [DocumentType] {
        switch profile {
        case .landlord:
            return allCases
        case .renter:
            return allCases.filter { !$0.isLandlordOnly }
        }
    }
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
    case gasSafetyRenewed = "Gas safety renewed"
    case electricalSafetyRenewed = "Electrical safety renewed"
    case energyPerformanceRenewed = "Energy performance renewed"
    case tenancyStarted = "Tenancy started"
    case tenancyEnded = "Tenancy ended"
    case rentReceived = "Rent received"
    case other = "Other"

    var isLandlordOnly: Bool {
        switch self {
        case .gasSafetyRenewed, .electricalSafetyRenewed, .energyPerformanceRenewed, .tenancyStarted, .tenancyEnded, .rentReceived:
            return true
        default:
            return false
        }
    }

    static func availableCases(for profile: RentoryUserProfile) -> [TimelineEventType] {
        switch profile {
        case .landlord:
            return allCases
        case .renter:
            return allCases.filter { !$0.isLandlordOnly }
        }
    }

    var symbolName: String {
        switch self {
        case .moveIn:
            return "key.fill"
        case .inventoryReviewed:
            return "checkmark.square.fill"
        case .issueNoticed:
            return "exclamationmark.circle.fill"
        case .issueReported:
            return "paperplane.fill"
        case .repairRequested:
            return "wrench.fill"
        case .repairCompleted:
            return "checkmark.seal.fill"
        case .cleaningCompleted:
            return "sparkles"
        case .inspection:
            return "magnifyingglass"
        case .moveOut:
            return "rectangle.portrait.and.arrow.right"
        case .depositDiscussion:
            return "sterlingsign.circle.fill"
        case .gasSafetyRenewed:
            return "flame.fill"
        case .electricalSafetyRenewed:
            return "bolt.fill"
        case .energyPerformanceRenewed:
            return "leaf.fill"
        case .tenancyStarted:
            return "key.fill"
        case .tenancyEnded:
            return "rectangle.portrait.and.arrow.right"
        case .rentReceived:
            return "banknote.fill"
        case .other:
            return "circle.fill"
        }
    }
}

enum TenancyStatus: String, CaseIterable, Codable, Identifiable {
    case upcoming = "Upcoming"
    case active = "Active"
    case ended = "Ended"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .upcoming: return "calendar.badge.clock"
        case .active: return "checkmark.seal.fill"
        case .ended: return "checkmark.circle"
        }
    }
}

enum TenancyType: String, CaseIterable, Codable, Identifiable {
    case assuredShorthold = "Assured shorthold (AST)"
    case periodic = "Periodic / rolling"
    case fixedTerm = "Fixed-term (non-AST)"
    case lodger = "Lodger / room let"
    case licence = "Licence to occupy"
    case other = "Other"

    var id: String { rawValue }
}

enum RentFrequency: String, CaseIterable, Codable, Identifiable {
    case weekly = "Weekly"
    case fortnightly = "Fortnightly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annually = "Annually"
    case other = "Other"

    var id: String { rawValue }
}

enum TenancyMode: String, CaseIterable, Codable, Identifiable {
    /// Single tenant, basic dates + deposit + rent + status. Quick to enter.
    case standard = "Standard"
    /// Multiple tenants, signed-on / break clause / inventory tracking. Full record.
    case comprehensive = "Comprehensive"

    var id: String { rawValue }

    var shortTitle: String { rawValue }

    var summary: String {
        switch self {
        case .standard:
            return "A simple record: one tenant, dates, deposit, rent, status."
        case .comprehensive:
            return "Full record: multiple tenants, signed-on date, break clause, inventory document."
        }
    }
}

enum TenancyStage: String, CaseIterable, Codable, Identifiable {
    case moveIn = "Move-in"
    case living = "Living"
    case moveOut = "Move-out"

    var id: String { rawValue }

    var shortTitle: String { rawValue }

    var systemImage: String {
        switch self {
        case .moveIn: return "key"
        case .living: return "house.fill"
        case .moveOut: return "rectangle.portrait.and.arrow.right"
        }
    }

    var description: String {
        switch self {
        case .moveIn:
            return "Recording the property condition before or as you move in."
        case .living:
            return "During the tenancy — ongoing notes, reminders and incidents."
        case .moveOut:
            return "Documenting the property at the end of the tenancy."
        }
    }

    var matchingPhase: EvidencePhase {
        switch self {
        case .moveIn: return .moveIn
        case .living: return .duringTenancy
        case .moveOut: return .moveOut
        }
    }

    static func derive(from startDate: Date?, to endDate: Date?, on referenceDate: Date = .now) -> TenancyStage? {
        switch (startDate, endDate) {
        case (nil, nil):
            return nil
        case (.some(let start), nil):
            return start > referenceDate ? .moveIn : .living
        case (nil, .some(let end)):
            return end < referenceDate ? .moveOut : .moveIn
        case (.some(let start), .some(let end)):
            if start > referenceDate { return .moveIn }
            if end < referenceDate { return .moveOut }
            return .living
        }
    }
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

enum ReminderKind: String, CaseIterable, Codable {
    case inspection = "Inspection"
    case repair = "Repair"
    case compliance = "Compliance"
    case deposit = "Deposit"
    case moveIn = "Move-in"
    case moveOut = "Move-out"
    case custom = "Custom"
    case gasSafety = "Gas safety"
    case electricalSafety = "Electrical safety (EICR)"
    case energyPerformance = "Energy performance (EPC)"
    case periodicInspection = "Periodic inspection"
    case tenancyRenewal = "Tenancy renewal"

    var iconName: String {
        switch self {
        case .inspection:
            return "magnifyingglass"
        case .repair:
            return "wrench.and.screwdriver"
        case .compliance:
            return "checkmark.shield"
        case .deposit:
            return "sterlingsign.circle"
        case .moveIn:
            return "key"
        case .moveOut:
            return "rectangle.portrait.and.arrow.right"
        case .custom:
            return "checklist"
        case .gasSafety:
            return "flame.fill"
        case .electricalSafety:
            return "bolt.fill"
        case .energyPerformance:
            return "leaf.fill"
        case .periodicInspection:
            return "magnifyingglass.circle.fill"
        case .tenancyRenewal:
            return "doc.text.fill"
        }
    }

    var isLandlordOnly: Bool {
        switch self {
        case .gasSafety, .electricalSafety, .energyPerformance, .periodicInspection, .tenancyRenewal:
            return true
        default:
            return false
        }
    }

    static func availableCases(for profile: RentoryUserProfile) -> [ReminderKind] {
        switch profile {
        case .landlord:
            return allCases
        case .renter:
            return allCases.filter { !$0.isLandlordOnly }
        }
    }
}

enum ReminderPriority: String, CaseIterable, Codable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"
}

/// Recurrence cadence for a `Reminder`. Stored as a raw string so the
/// schema can grow new cases without a migration. Completion logic in
/// `ReminderDetailView` spawns a new reminder for the next occurrence
/// (see `nextDueDate(after:)`) and marks the current one complete — so
/// each row is a single occurrence with audit history, not a moving
/// target. Picking `.none` means the reminder is one-off, which is the
/// default for all existing reminders that don't carry a stored value.
enum ReminderRecurrence: String, CaseIterable, Codable, Identifiable {
    case none = "Does not repeat"
    case daily = "Daily"
    case weekly = "Weekly"
    case fortnightly = "Every 2 weeks"
    case monthly = "Monthly"
    case quarterly = "Every 3 months"
    case yearly = "Yearly"

    var id: String { rawValue }

    /// Short label used inside dashboard list rows where the long
    /// "Every 2 weeks" form would push the layout. Returns nil for
    /// `.none` so callers can decide whether to render anything.
    var shortLabel: String? {
        switch self {
        case .none: return nil
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .fortnightly: return "2-weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }

    /// Given an existing due date, computes the next occurrence date
    /// using the user's current calendar. Returns nil for `.none` so
    /// callers can treat that as "no further occurrence".
    func nextDueDate(after dueDate: Date, calendar: Calendar = .autoupdatingCurrent) -> Date? {
        switch self {
        case .none:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: dueDate)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: dueDate)
        case .fortnightly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: dueDate)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: dueDate)
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: dueDate)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: dueDate)
        }
    }
}

enum RentPaymentStatus: String, CaseIterable, Codable, Identifiable {
    case paid = "Paid"
    case pending = "Pending"
    case late = "Late"
    case waived = "Waived"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .paid: return "checkmark.circle.fill"
        case .pending: return "clock"
        case .late: return "exclamationmark.triangle.fill"
        case .waived: return "circle.slash"
        }
    }
}

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case maintenance = "Maintenance & repair"
    case insurance = "Insurance"
    case agentFee = "Agent fees"
    case cleaning = "Cleaning"
    case utilities = "Utilities"
    case mortgage = "Mortgage interest"
    case professional = "Legal & professional"
    case taxes = "Taxes & licences"
    case furnishing = "Furnishings"
    case marketing = "Marketing"
    case other = "Other"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .maintenance: return "wrench.and.screwdriver"
        case .insurance: return "shield.lefthalf.filled"
        case .agentFee: return "person.badge.shield.checkmark"
        case .cleaning: return "sparkles"
        case .utilities: return "bolt.fill"
        case .mortgage: return "sterlingsign.circle"
        case .professional: return "doc.text.fill"
        case .taxes: return "percent"
        case .furnishing: return "sofa.fill"
        case .marketing: return "megaphone"
        case .other: return "ellipsis.circle"
        }
    }
}
