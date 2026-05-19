//
//  Tenancy.swift
//  Rentory
//
//  Created by Adam Ibrahim on 19/05/2026.
//

import Foundation
import SwiftData

@Model
final class Tenancy {
    var id: UUID = UUID()

    // Always-present (Standard) fields
    var startDate: Date = Date.now
    var endDate: Date?
    var statusRawValue: String = TenancyStatus.upcoming.rawValue
    var tenancyTypeRawValue: String = TenancyType.assuredShorthold.rawValue
    var depositAmount: Double?
    var depositSchemeName: String?
    var depositReference: String?
    var rentAmount: Double?
    var rentFrequencyRawValue: String?
    var notes: String?

    // Comprehensive-only fields (kept optional so standard tenancies don't have to fill them)
    var signedOnDate: Date?
    var breakClauseDate: Date?
    var inventoryDocumentID: UUID?

    // Mode the user picked when they last edited this tenancy. Standard hides
    // the comprehensive fields in the UI; comprehensive shows everything.
    // Persisted so the form opens in the right mode next time.
    var modeRawValue: String = TenancyMode.standard.rawValue

    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    @Relationship(deleteRule: .cascade) var tenants: [Tenant] = []
    @Relationship(deleteRule: .cascade) var rentPayments: [RentPayment] = []

    init(
        id: UUID = UUID(),
        startDate: Date = .now,
        endDate: Date? = nil,
        status: TenancyStatus = .upcoming,
        tenancyType: TenancyType = .assuredShorthold,
        depositAmount: Double? = nil,
        depositSchemeName: String? = nil,
        depositReference: String? = nil,
        rentAmount: Double? = nil,
        rentFrequency: RentFrequency? = nil,
        notes: String? = nil,
        signedOnDate: Date? = nil,
        breakClauseDate: Date? = nil,
        inventoryDocumentID: UUID? = nil,
        mode: TenancyMode = .standard,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        tenants: [Tenant] = [],
        rentPayments: [RentPayment] = []
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.statusRawValue = status.rawValue
        self.tenancyTypeRawValue = tenancyType.rawValue
        self.depositAmount = depositAmount
        self.depositSchemeName = depositSchemeName
        self.depositReference = depositReference
        self.rentAmount = rentAmount
        self.rentFrequencyRawValue = rentFrequency?.rawValue
        self.notes = notes
        self.signedOnDate = signedOnDate
        self.breakClauseDate = breakClauseDate
        self.inventoryDocumentID = inventoryDocumentID
        self.modeRawValue = mode.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tenants = tenants
        self.rentPayments = rentPayments
    }
}

extension Tenancy {
    var status: TenancyStatus {
        get { TenancyStatus(rawValue: statusRawValue) ?? .upcoming }
        set { statusRawValue = newValue.rawValue }
    }

    var tenancyType: TenancyType {
        get { TenancyType(rawValue: tenancyTypeRawValue) ?? .assuredShorthold }
        set { tenancyTypeRawValue = newValue.rawValue }
    }

    var rentFrequency: RentFrequency? {
        get { rentFrequencyRawValue.flatMap(RentFrequency.init(rawValue:)) }
        set { rentFrequencyRawValue = newValue?.rawValue }
    }

    var mode: TenancyMode {
        get { TenancyMode(rawValue: modeRawValue) ?? .standard }
        set { modeRawValue = newValue.rawValue }
    }

    /// The status this tenancy *should* have based on its dates, irrespective
    /// of any manual override. Use to drive the same nudge pattern as
    /// TenancyStage when the user's manual status differs from what the
    /// dates imply.
    func derivedStatus(on referenceDate: Date = .now) -> TenancyStatus {
        if startDate > referenceDate { return .upcoming }
        if let endDate, endDate < referenceDate { return .ended }
        return .active
    }

    var primaryTenant: Tenant? {
        tenants.sorted { $0.sortOrder < $1.sortOrder }.first
    }
}
