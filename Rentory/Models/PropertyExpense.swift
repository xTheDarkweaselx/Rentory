//
//  PropertyExpense.swift
//  Rentory
//
//  A single outgoing on a property — repairs, agent fees, insurance,
//  cleaning, etc. Used by the landlord profile alongside RentPayment to
//  produce year-to-date income / outgoings summaries. Persisted as a
//  SwiftData @Model with a cascade-delete relationship from PropertyPack.
//

import Foundation
import SwiftData

@Model
final class PropertyExpense {
    var id: UUID = UUID()
    var date: Date = Date.now
    var title: String = ""
    var amount: Double = 0
    var currencyCode: String = "GBP"
    var categoryRawValue: String = ExpenseCategory.other.rawValue
    var notes: String?
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    init(
        id: UUID = UUID(),
        date: Date = .now,
        title: String,
        amount: Double = 0,
        currencyCode: String = "GBP",
        category: ExpenseCategory = .other,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.amount = amount
        self.currencyCode = currencyCode
        self.categoryRawValue = category.rawValue
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension PropertyExpense {
    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }
}
