//
//  RentPayment.swift
//  Rentory
//
//  A single rent instalment on a tenancy: when it was due, whether (and
//  when) it was paid, the amount, and free-form notes. Landlord profile
//  uses these to log income and to produce annual summaries. Persisted
//  as a SwiftData @Model with a cascade-delete relationship from Tenancy.
//

import Foundation
import SwiftData

@Model
final class RentPayment {
    var id: UUID = UUID()
    var dueDate: Date = Date.now
    var paidDate: Date?
    var amount: Double = 0
    var currencyCode: String = "GBP"
    var statusRawValue: String = RentPaymentStatus.pending.rawValue
    var notes: String?
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    init(
        id: UUID = UUID(),
        dueDate: Date = .now,
        paidDate: Date? = nil,
        amount: Double = 0,
        currencyCode: String = "GBP",
        status: RentPaymentStatus = .pending,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.dueDate = dueDate
        self.paidDate = paidDate
        self.amount = amount
        self.currencyCode = currencyCode
        self.statusRawValue = status.rawValue
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension RentPayment {
    var status: RentPaymentStatus {
        get { RentPaymentStatus(rawValue: statusRawValue) ?? .pending }
        set { statusRawValue = newValue.rawValue }
    }

    var isPaid: Bool {
        status == .paid
    }
}
