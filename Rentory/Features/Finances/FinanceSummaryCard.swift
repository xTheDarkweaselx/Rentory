//
//  FinanceSummaryCard.swift
//  Rentory
//
//  Landlord-only summary panel for the property dashboard. Shows
//  year-to-date rent received, year-to-date expenses, net total, and a
//  list of the most recent expenses. Pure derived data — no scheduling
//  or background work. Locale-aware currency formatting uses the
//  payment / expense currency code, defaulting to GBP.
//

import SwiftData
import SwiftUI

struct FinanceSummaryCard: View {
    let propertyPack: PropertyPack
    var onAddExpense: () -> Void = {}
    var onViewAllExpenses: () -> Void = {}
    var onExportCSV: () -> Void = {}

    @AppStorage(AppColourTheme.storageKey) private var appColourThemeRawValue = AppColourTheme.defaultLook.rawValue

    private let calendar = Calendar.autoupdatingCurrent

    private var yearToDateRentTotal: Double {
        let now = Date()
        return propertyPack.tenancies
            .flatMap(\.rentPayments)
            .filter { $0.isPaid && calendar.isDate($0.paidDate ?? $0.dueDate, equalTo: now, toGranularity: .year) }
            .reduce(0) { $0 + $1.amount }
    }

    private var yearToDateExpenseTotal: Double {
        let now = Date()
        return propertyPack.expenses
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .year) }
            .reduce(0) { $0 + $1.amount }
    }

    private var net: Double {
        yearToDateRentTotal - yearToDateExpenseTotal
    }

    private var currencyCode: String {
        propertyPack.expenses.first?.currencyCode
            ?? propertyPack.tenancies.flatMap(\.rentPayments).first?.currencyCode
            ?? "GBP"
    }

    private var recentExpenses: [PropertyExpense] {
        Array(propertyPack.expenses.sorted(by: { $0.date > $1.date }).prefix(3))
    }

    private var hasExportableRows: Bool {
        !propertyPack.expenses.isEmpty
            || propertyPack.tenancies.contains(where: { !$0.rentPayments.isEmpty })
    }

    var body: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                HStack(alignment: .firstTextBaseline) {
                    Text("FINANCES")
                        .font(RRTypography.caption.weight(.semibold))
                        .foregroundStyle(RRColours.mutedText)
                    Spacer(minLength: 0)
                    Text("\(currentYear)")
                        .font(RRTypography.caption)
                        .foregroundStyle(RRColours.mutedText)
                }

                Text(net >= 0 ? "Net \(formatted(net))" : "Net \(formatted(net))")
                    .font(RRTypography.title.weight(.bold))
                    .foregroundStyle(net >= 0 ? RRColours.success : RRColours.danger)

                HStack(spacing: 18) {
                    metric(label: "Rent in", value: formatted(yearToDateRentTotal), tint: RRColours.success)
                    metric(label: "Outgoings", value: formatted(yearToDateExpenseTotal), tint: RRColours.warning)
                }

                if !recentExpenses.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recent outgoings")
                            .font(RRTypography.footnote.weight(.semibold))
                            .foregroundStyle(RRColours.primary)

                        ForEach(recentExpenses) { expense in
                            HStack(alignment: .firstTextBaseline) {
                                Image(systemName: expense.category.systemImage)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(RRColours.secondary)
                                    .frame(width: 18)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(expense.title)
                                        .font(RRTypography.footnote)
                                        .foregroundStyle(RRColours.primary)
                                    Text("\(expense.category.rawValue) · \(expense.date.formatted(date: .abbreviated, time: .omitted))")
                                        .font(RRTypography.caption)
                                        .foregroundStyle(RRColours.mutedText)
                                }
                                Spacer(minLength: 8)
                                Text(formatted(expense.amount, currencyCode: expense.currencyCode))
                                    .font(RRTypography.footnote.weight(.semibold))
                                    .foregroundStyle(RRColours.primary)
                            }
                        }
                    }
                }

                HStack(spacing: RRTheme.controlSpacing) {
                    RRSecondaryButton(title: "Add expense", action: onAddExpense)
                    if !propertyPack.expenses.isEmpty {
                        RRSecondaryButton(title: "View all", action: onViewAllExpenses)
                    }
                }

                if hasExportableRows {
                    Button {
                        onExportCSV()
                    } label: {
                        Label("Export CSV for this tax year", systemImage: "square.and.arrow.up")
                            .font(RRTypography.footnote.weight(.semibold))
                            .foregroundStyle(RRColours.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Saves rent payments and expenses for the current UK tax year as a CSV file.")
                }
            }
        }
        .id(appColourThemeRawValue)
    }

    private var currentYear: Int {
        calendar.component(.year, from: Date())
    }

    private func metric(label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(RRTypography.caption)
                .foregroundStyle(RRColours.mutedText)
            Text(value)
                .font(RRTypography.headline)
                .foregroundStyle(tint)
        }
    }

    private func formatted(_ amount: Double, currencyCode: String? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode ?? self.currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }
}
