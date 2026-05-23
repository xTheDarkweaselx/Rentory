//
//  LandlordFinanceCSVExporter.swift
//  Rentory
//
//  Generates a per-property CSV covering rent payments + property
//  expenses over a date range, primarily for users doing UK self-
//  assessment income tax. Plain RFC-4180-ish CSV — no escaping of UTF-8
//  beyond quoting and double-quote escaping. Saves to the temporary-
//  export folder via FileStorageService so the system share sheet has a
//  real URL to attach.
//
//  Default range is the UK tax year (6 April → 5 April). Callers can
//  override with any closed interval — useful for landlords with a
//  different accounting period.
//

import Foundation
import SwiftData

@MainActor
struct LandlordFinanceCSVExporter {
    private let fileStorageService: FileStorageService
    private let dateFormatter: DateFormatter
    private let amountFormatter: NumberFormatter

    init(fileStorageService: FileStorageService? = nil) {
        // Building the FileStorageService inside the init body keeps
        // the default-parameter expression off the call site, so Swift
        // 6 strict concurrency doesn't flag a MainActor-isolated call
        // from a possibly nonisolated context. Same intent as the
        // previous `= FileStorageService()` default — just relocated.
        self.fileStorageService = fileStorageService ?? FileStorageService()

        let date = DateFormatter()
        date.locale = Locale(identifier: "en_GB")
        date.dateFormat = "yyyy-MM-dd"
        self.dateFormatter = date

        let amount = NumberFormatter()
        amount.numberStyle = .decimal
        amount.minimumFractionDigits = 2
        amount.maximumFractionDigits = 2
        amount.usesGroupingSeparator = false
        self.amountFormatter = amount
    }

    /// Builds the CSV text and saves to a temporary file. Returns the
    /// URL so the caller can hand it to a share sheet.
    func createCSV(for propertyPack: PropertyPack, range: DateInterval) throws -> URL {
        let csv = csvText(for: propertyPack, range: range)
        guard let data = csv.data(using: .utf8) else {
            throw FileStorageError.unableToWriteFile
        }
        let safeName = propertyPack.nickname
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let yearLabel = "\(Calendar.current.component(.year, from: range.start))-\(Calendar.current.component(.year, from: range.end))"
        let baseName = "\(safeName.isEmpty ? "rentory" : safeName.lowercased())-finance-\(yearLabel)"
        return try fileStorageService.saveTemporaryExportData(
            data,
            preferredFileName: baseName + ".csv"
        )
    }

    /// Pure builder, exposed so tests can assert the body content
    /// without hitting the filesystem.
    func csvText(for propertyPack: PropertyPack, range: DateInterval) -> String {
        var rows: [String] = [
            "Date,Kind,Amount,Currency,Description,Category or tenancy,Status"
        ]

        // Flatten payments while still knowing which tenancy each came
        // from — RentPayment doesn't carry a back-reference, so we walk
        // the parent collection here rather than relying on
        // payment.tenancy.
        var paymentEntries: [(payment: RentPayment, tenants: String)] = []
        for tenancy in propertyPack.tenancies {
            let tenantNames = tenancy.tenants.map(\.name).joined(separator: " / ")
            for payment in tenancy.rentPayments {
                paymentEntries.append((payment, tenantNames))
            }
        }

        let rentRows = paymentEntries
            .filter { range.contains($0.payment.paidDate ?? $0.payment.dueDate) }
            .sorted { ($0.payment.paidDate ?? $0.payment.dueDate) < ($1.payment.paidDate ?? $1.payment.dueDate) }
            .map { entry -> String in
                let payment = entry.payment
                let date = payment.paidDate ?? payment.dueDate
                let description = payment.notes ?? "Rent payment"
                let status = (payment.paidDate != nil) ? "Paid" : "Pending"
                return makeRow(
                    date: date,
                    kind: "Rent",
                    amount: payment.amount,
                    currency: payment.currencyCode,
                    description: description,
                    categoryOrTenant: entry.tenants,
                    status: status
                )
            }
        rows.append(contentsOf: rentRows)

        let expenseRows = propertyPack.expenses
            .filter { range.contains($0.date) }
            .sorted { $0.date < $1.date }
            .map { expense -> String in
                makeRow(
                    date: expense.date,
                    kind: "Expense",
                    amount: expense.amount,
                    currency: expense.currencyCode,
                    description: expense.notes.map { "\(expense.title) — \($0)" } ?? expense.title,
                    categoryOrTenant: expense.categoryRawValue,
                    status: ""
                )
            }
        rows.append(contentsOf: expenseRows)

        return rows.joined(separator: "\n") + "\n"
    }

    private func makeRow(
        date: Date,
        kind: String,
        amount: Double,
        currency: String,
        description: String,
        categoryOrTenant: String,
        status: String
    ) -> String {
        let amountString = amountFormatter.string(from: NSNumber(value: amount)) ?? String(amount)
        let columns = [
            dateFormatter.string(from: date),
            kind,
            amountString,
            currency,
            description,
            categoryOrTenant,
            status,
        ]
        return columns.map(csvEscape(_:)).joined(separator: ",")
    }

    /// Wraps a value in quotes if it contains a comma, newline or
    /// quote, and escapes any embedded quotes by doubling. Matches
    /// the RFC-4180 convention every modern spreadsheet imports.
    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\n") || value.contains("\"") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }

    /// Returns the current UK tax year as a DateInterval. Defaults to
    /// the tax year that contains "now"; if now is before April 6,
    /// uses the previous year's range.
    static func currentUKTaxYear(now: Date = .now, calendar: Calendar = Calendar(identifier: .gregorian)) -> DateInterval {
        let year = calendar.component(.year, from: now)
        let aprilSixThisYear = calendar.date(from: DateComponents(year: year, month: 4, day: 6)) ?? now
        let start: Date
        let end: Date
        if now >= aprilSixThisYear {
            start = aprilSixThisYear
            end = calendar.date(from: DateComponents(year: year + 1, month: 4, day: 5, hour: 23, minute: 59, second: 59)) ?? now
        } else {
            start = calendar.date(from: DateComponents(year: year - 1, month: 4, day: 6)) ?? now
            end = calendar.date(from: DateComponents(year: year, month: 4, day: 5, hour: 23, minute: 59, second: 59)) ?? now
        }
        return DateInterval(start: start, end: end)
    }
}
