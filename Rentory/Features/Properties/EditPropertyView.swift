//
//  EditPropertyView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI

struct EditPropertyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let propertyPack: PropertyPack

    @State private var nickname: String
    @State private var addressLine1: String
    @State private var addressLine2: String
    @State private var townCity: String
    @State private var postcode: String
    @State private var hasTenancyStartDate: Bool
    @State private var tenancyStartDate: Date
    @State private var hasTenancyEndDate: Bool
    @State private var tenancyEndDate: Date
    @State private var landlordOrAgentName: String
    @State private var landlordOrAgentEmail: String
    @State private var depositSchemeName: String
    @State private var depositReference: String
    @State private var notes: String
    @State private var validationMessage: String?
    @State private var isShowingArchiveConfirmation = false
    @State private var isShowingDeleteConfirmation = false
    @State private var deletionAlertMessage: String?

    let onDelete: (() -> Void)?

    private let deletionService = RentoryDataDeletionService()

    init(propertyPack: PropertyPack, onDelete: (() -> Void)? = nil) {
        self.propertyPack = propertyPack
        self.onDelete = onDelete
        _nickname = State(initialValue: propertyPack.nickname)
        _addressLine1 = State(initialValue: propertyPack.addressLine1 ?? "")
        _addressLine2 = State(initialValue: propertyPack.addressLine2 ?? "")
        _townCity = State(initialValue: propertyPack.townCity ?? "")
        _postcode = State(initialValue: propertyPack.postcode ?? "")
        _hasTenancyStartDate = State(initialValue: propertyPack.tenancyStartDate != nil)
        _tenancyStartDate = State(initialValue: propertyPack.tenancyStartDate ?? .now)
        _hasTenancyEndDate = State(initialValue: propertyPack.tenancyEndDate != nil)
        _tenancyEndDate = State(initialValue: propertyPack.tenancyEndDate ?? .now)
        _landlordOrAgentName = State(initialValue: propertyPack.landlordOrAgentName ?? "")
        _landlordOrAgentEmail = State(initialValue: propertyPack.landlordOrAgentEmail ?? "")
        _depositSchemeName = State(initialValue: propertyPack.depositSchemeName ?? "")
        _depositReference = State(initialValue: propertyPack.depositReference ?? "")
        _notes = State(initialValue: propertyPack.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage {
                    Section {
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

                Section {
                    RRDestructiveButton(title: "Archive record") {
                        isShowingArchiveConfirmation = true
                    }
                    .accessibilityHint("Keeps this record out of your active list.")

                    RRDestructiveButton(title: "Delete this record") {
                        isShowingDeleteConfirmation = true
                    }
                    .accessibilityHint("Removes this record, including its photos and documents, from this device.")
                }
            }
            .navigationTitle("Edit record")
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
                        saveChanges()
                    }
                    .accessibilityHint("Saves changes to this record.")
                }
            }
            .alert("Archive this record?", isPresented: $isShowingArchiveConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Archive", role: .destructive) {
                    propertyPack.isArchived = true
                    propertyPack.updatedAt = .now
                    dismiss()
                }
            } message: {
                Text("You can keep it out of your active list without deleting it.")
            }
            .alert("Delete this record?", isPresented: $isShowingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteRecord()
                }
            } message: {
                Text("This removes the record, including its photos and documents, from this device. This cannot be undone.")
            }
            .alert("Delete this record", isPresented: deletionAlertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deletionAlertMessage ?? "")
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

    private func saveChanges() {
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

        propertyPack.nickname = trimmedNickname
        propertyPack.addressLine1 = optionalText(addressLine1)
        propertyPack.addressLine2 = optionalText(addressLine2)
        propertyPack.townCity = optionalText(townCity)
        propertyPack.postcode = optionalText(postcode)
        propertyPack.tenancyStartDate = hasTenancyStartDate ? tenancyStartDate : nil
        propertyPack.tenancyEndDate = hasTenancyEndDate ? tenancyEndDate : nil
        propertyPack.landlordOrAgentName = optionalText(landlordOrAgentName)
        propertyPack.landlordOrAgentEmail = trimmedEmail.isEmpty ? nil : trimmedEmail
        propertyPack.depositSchemeName = optionalText(depositSchemeName)
        propertyPack.depositReference = optionalText(depositReference)
        propertyPack.notes = optionalText(notes)
        propertyPack.updatedAt = .now

        dismiss()
    }

    private var isValidDateRange: Bool {
        guard hasTenancyStartDate, hasTenancyEndDate else {
            return true
        }

        return tenancyEndDate >= tenancyStartDate
    }

    private var deletionAlertBinding: Binding<Bool> {
        Binding(
            get: { deletionAlertMessage != nil },
            set: { newValue in
                if !newValue {
                    deletionAlertMessage = nil
                }
            }
        )
    }

    private func deleteRecord() {
        do {
            try deletionService.deletePropertyPack(propertyPack, context: modelContext)
            dismiss()
            onDelete?()
        } catch let error as RentoryDataDeletionError {
            deletionAlertMessage = "\(error.errorDescription ?? "This record could not be deleted.") Please try again."
        } catch {
            deletionAlertMessage = "This record could not be deleted. Please try again."
        }
    }
}
