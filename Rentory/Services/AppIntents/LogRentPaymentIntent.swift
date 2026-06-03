//
//  LogRentPaymentIntent.swift
//  Rentory
//
//  Background Siri / Shortcuts intent for logging a rent payment. Same
//  queue-then-apply pattern as AddReminderIntent — the intent process
//  writes a payload to the App Group queue, and `RentoryPendingIntent
//  Applier` materialises it onto the most-recent tenancy of the picked
//  property the next time the app opens.
//
//  Defaults: `paidDate` defaults to today, `currencyCode` defaults to
//  GBP (the same default the rest of the app uses for landlord finance
//  surfaces). The user can override either through Shortcuts.
//

import AppIntents
import Foundation

struct LogRentPaymentIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Rentory rent payment"
    static var description = IntentDescription("Record a paid rent instalment on the most-recent tenancy of one of your Rentory records. Saves locally — no networking.")

    @Parameter(title: "Record")
    var property: RentoryPropertyEntity

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Paid on", default: nil)
    var paidDate: Date?

    @Parameter(title: "Currency", default: "GBP")
    var currencyCode: String

    init() {}

    init(property: RentoryPropertyEntity, amount: Double, paidDate: Date? = nil, currencyCode: String = "GBP") {
        self.property = property
        self.amount = amount
        self.paidDate = paidDate
        self.currencyCode = currencyCode
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard amount > 0 else {
            throw LogRentPaymentIntentError.nonPositiveAmount
        }

        let payload = RentoryPendingIntent.logRentPayment(
            propertyID: property.id,
            amount: amount,
            paidDate: paidDate ?? .now,
            currencyCode: currencyCode,
            createdAt: .now
        )

        try RentoryPendingIntentStore.enqueue(payload)

        let formatter = NumberFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)

        return .result(dialog: IntentDialog(stringLiteral: "Logged \(formattedAmount) on \(property.nickname)."))
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) \(\.$currencyCode) for \(\.$property) on \(\.$paidDate)")
    }
}

enum LogRentPaymentIntentError: Error, CustomLocalizedStringResourceConvertible {
    case nonPositiveAmount

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .nonPositiveAmount:
            return "Rent payment amount must be greater than zero."
        }
    }
}
