//
//  RentoryEnums.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

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
