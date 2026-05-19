//
//  AddRentPaymentView.swift
//  Rentory
//
//  Sheet for logging a single rent instalment on a tenancy. Optional
//  paid-date toggle — pending and late payments can be tracked too.
//

import SwiftData
import SwiftUI

struct AddRentPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let tenancy: Tenancy

    @State private var amountText = ""
    @State private var dueDate = Date()
    @State private var hasPaidDate = true
    @State private var paidDate = Date()
    @State private var status: RentPaymentStatus = .paid
    @State private var notes = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                RRMacSheetContainer {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Add rent payment",
                            subtitle: "Log when rent was due, what was paid, and any notes for the record.",
                            systemImage: "sterlingsign.circle"
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
                                RRSectionHeader(title: "Payment")

                                fieldLabel("Amount")
                                TextField("0.00", text: $amountText)
                                    .textFieldStyle(.roundedBorder)
                                    #if !os(macOS)
                                    .keyboardType(.decimalPad)
                                    #endif

                                DatePicker("Due date", selection: $dueDate, displayedComponents: .date)

                                Toggle("Already paid", isOn: $hasPaidDate)
                                    .tint(RRColours.secondary)
                                    .onChange(of: hasPaidDate) { _, isPaid in
                                        status = isPaid ? .paid : .pending
                                    }

                                if hasPaidDate {
                                    DatePicker("Paid on", selection: $paidDate, displayedComponents: .date)
                                }

                                fieldLabel("Status")
                                Picker("Status", selection: $status) {
                                    ForEach(RentPaymentStatus.allCases) { status in
                                        Label(status.rawValue, systemImage: status.systemImage)
                                            .tag(status)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }

                        RRGlassPanel {
                            VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                                RRSectionHeader(title: "Notes")
                                TextField("Method, receipt reference, anything else (optional)", text: $notes, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...6)
                            }
                        }

                        RRGlassPanel {
                            HStack(spacing: RRTheme.controlSpacing) {
                                Spacer(minLength: 0)
                                RRSecondaryButton(title: "Cancel") { dismiss() }
                                RRPrimaryButton(title: "Save payment") { savePayment() }
                            }
                        }
                    }
                    .padding(RRTheme.screenPadding)
                }
            }
            .background(RRBackgroundView())
            .navigationTitle("Add rent payment")
            .rrInlineNavigationTitle()
            .onAppear(perform: prefillFromTenancy)
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(RRTypography.footnote.weight(.semibold))
            .foregroundStyle(RRColours.mutedText)
    }

    private func prefillFromTenancy() {
        if amountText.isEmpty, let amount = tenancy.rentAmount {
            amountText = String(format: "%.2f", amount)
        }
    }

    private func savePayment() {
        let parsedAmount = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard parsedAmount > 0 else {
            validationMessage = "Enter an amount greater than zero."
            return
        }

        let payment = RentPayment(
            dueDate: dueDate,
            paidDate: hasPaidDate ? paidDate : nil,
            amount: parsedAmount,
            status: status,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        )
        tenancy.rentPayments.append(payment)
        tenancy.updatedAt = .now

        do {
            try modelContext.save()
            dismiss()
        } catch {
            validationMessage = "This payment could not be saved. Please try again."
        }
    }
}
