//
//  AddPropertyExpenseView.swift
//  Rentory
//
//  Sheet for logging a single outgoing on a property — repairs, agent
//  fees, insurance, etc. Saved straight onto PropertyPack.expenses; no
//  intermediate validation beyond a non-empty title and a positive
//  amount.
//

import SwiftData
import SwiftUI

struct AddPropertyExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let propertyPack: PropertyPack

    @State private var title = ""
    @State private var amountText = ""
    @State private var category: ExpenseCategory = .maintenance
    @State private var date = Date()
    @State private var notes = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                RRMacSheetContainer {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Add expense",
                            subtitle: "Log an outgoing on this property — repair, agent fee, insurance, anything you pay for.",
                            systemImage: "creditcard"
                        )

                        if let validationMessage {
                            RRGlassPanel {
                                Text(validationMessage)
                                    .font(RRTypography.footnote.weight(.semibold))
                                    .foregroundStyle(RRColours.danger)
                            }
                        }

                        RRGlassPanel {
                            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                                RRSectionHeader(title: "What was paid for?")

                                fieldLabel("Title")
                                TextField("e.g. Boiler service", text: $title)
                                    .textFieldStyle(.roundedBorder)
                                    .rrTextInputAutocapitalizationWords()

                                fieldLabel("Category")
                                Picker("Category", selection: $category) {
                                    ForEach(ExpenseCategory.allCases) { category in
                                        Label(category.rawValue, systemImage: category.systemImage)
                                            .tag(category)
                                    }
                                }
                                .pickerStyle(.menu)

                                fieldLabel("Amount")
                                TextField("0.00", text: $amountText)
                                    .textFieldStyle(.roundedBorder)
                                    #if !os(macOS)
                                    .keyboardType(.decimalPad)
                                    #endif

                                DatePicker("Date paid", selection: $date, displayedComponents: .date)
                            }
                        }

                        RRGlassPanel {
                            VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                                RRSectionHeader(title: "Notes")
                                TextField("Anything worth recording (optional)", text: $notes, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...6)
                            }
                        }

                        RRGlassPanel {
                            HStack(spacing: RRTheme.controlSpacing) {
                                Spacer(minLength: 0)
                                RRSecondaryButton(title: "Cancel") { dismiss() }
                                RRPrimaryButton(title: "Save expense") { saveExpense() }
                            }
                        }
                    }
                    .padding(RRTheme.screenPadding)
                }
            }
            .background(RRBackgroundView())
            .navigationTitle("Add expense")
            .rrInlineNavigationTitle()
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(RRTypography.footnote.weight(.semibold))
            .foregroundStyle(RRColours.mutedText)
    }

    private func saveExpense() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            validationMessage = "Add a short title so you remember what this expense was for."
            return
        }

        let parsedAmount = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard parsedAmount > 0 else {
            validationMessage = "Enter an amount greater than zero."
            return
        }

        let expense = PropertyExpense(
            date: date,
            title: trimmedTitle,
            amount: parsedAmount,
            category: category,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        )
        propertyPack.expenses.append(expense)
        propertyPack.updatedAt = .now

        do {
            try modelContext.save()
            dismiss()
        } catch {
            validationMessage = "This expense could not be saved. Please try again."
        }
    }
}
