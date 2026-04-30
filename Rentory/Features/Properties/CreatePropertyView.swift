//
//  CreatePropertyView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI

struct CreatePropertyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var nickname = ""
    @State private var addressLine1 = ""
    @State private var addressLine2 = ""
    @State private var townCity = ""
    @State private var postcode = ""
    @State private var hasTenancyStartDate = false
    @State private var tenancyStartDate = Date()
    @State private var hasTenancyEndDate = false
    @State private var tenancyEndDate = Date()
    @State private var landlordOrAgentName = ""
    @State private var landlordOrAgentEmail = ""
    @State private var depositSchemeName = ""
    @State private var depositReference = ""
    @State private var notes = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Only the property name is needed. You can add more details now or later.")
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)

                    if let validationMessage {
                        Text(validationMessage)
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.danger)
                            .accessibilityLabel("Validation message. \(validationMessage)")
                    }
                }

                propertyDetailsSection
                tenancySection
                contactSection
                depositSection
                notesSection
            }
            .navigationTitle("Create a record")
            .rrInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProperty()
                    }
                    .accessibilityHint("Creates this rental record.")
                }
            }
        }
    }

    private var propertyDetailsSection: some View {
        Section("Property") {
            TextField("Property name", text: $nickname)
                .rrTextInputAutocapitalizationWords()
                .accessibilityHint("Required")

            TextField("Address line 1", text: $addressLine1)
                .rrTextInputAutocapitalizationWords()

            TextField("Address line 2", text: $addressLine2)
                .rrTextInputAutocapitalizationWords()

            TextField("Town or city", text: $townCity)
                .rrTextInputAutocapitalizationWords()

            TextField("Postcode", text: $postcode)
                .rrTextInputAutocapitalizationCharacters()
        }
    }

    private var tenancySection: some View {
        Section("Tenancy") {
            Toggle("Add tenancy start date", isOn: $hasTenancyStartDate.animation())

            if hasTenancyStartDate {
                DatePicker("Tenancy start date", selection: $tenancyStartDate, displayedComponents: .date)
            }

            Toggle("Add tenancy end date", isOn: $hasTenancyEndDate.animation())

            if hasTenancyEndDate {
                DatePicker("Tenancy end date", selection: $tenancyEndDate, displayedComponents: .date)
            }
        }
    }

    private var contactSection: some View {
        Section("Landlord or letting agent") {
            TextField("Name", text: $landlordOrAgentName)
                .rrTextInputAutocapitalizationWords()

            TextField("Email", text: $landlordOrAgentEmail)
                .rrEmailKeyboard()
                .rrTextInputAutocapitalizationNever()
                .autocorrectionDisabled()
        }
    }

    private var depositSection: some View {
        Section("Deposit") {
            TextField("Scheme name", text: $depositSchemeName)
                .rrTextInputAutocapitalizationWords()

            TextField("Reference", text: $depositReference)
                .rrTextInputAutocapitalizationCharacters()
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Add any notes you want to keep here", text: $notes, axis: .vertical)
                .lineLimit(4...8)
        }
    }

    private func saveProperty() {
        let trimmedNickname = trimmed(nickname)
        let trimmedEmail = trimmed(landlordOrAgentEmail)

        guard !trimmedNickname.isEmpty else {
            validationMessage = "Add a property name to continue."
            return
        }

        guard isValidDateRange else {
            validationMessage = "Check the tenancy dates. The end date can’t be before the start date."
            return
        }

        guard trimmedEmail.isEmpty || isLightweightEmail(trimmedEmail) else {
            validationMessage = "Check the email address or leave it blank."
            return
        }

        let propertyPack = PropertyPack(
            nickname: trimmedNickname,
            addressLine1: optionalText(addressLine1),
            addressLine2: optionalText(addressLine2),
            townCity: optionalText(townCity),
            postcode: optionalText(postcode),
            tenancyStartDate: hasTenancyStartDate ? tenancyStartDate : nil,
            tenancyEndDate: hasTenancyEndDate ? tenancyEndDate : nil,
            landlordOrAgentName: optionalText(landlordOrAgentName),
            landlordOrAgentEmail: trimmedEmail.isEmpty ? nil : trimmedEmail,
            depositSchemeName: optionalText(depositSchemeName),
            depositReference: optionalText(depositReference),
            notes: optionalText(notes),
            createdAt: .now,
            updatedAt: .now
        )

        modelContext.insert(propertyPack)
        dismiss()
    }

    private var isValidDateRange: Bool {
        guard hasTenancyStartDate, hasTenancyEndDate else {
            return true
        }

        return tenancyEndDate >= tenancyStartDate
    }
}
