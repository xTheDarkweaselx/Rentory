//
//  PropertyFormSupport.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation
import SwiftUI

func trimmed(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
}

func optionalText(_ value: String) -> String? {
    let trimmedValue = trimmed(value)
    return trimmedValue.isEmpty ? nil : trimmedValue
}

func isLightweightEmail(_ value: String) -> Bool {
    let parts = value.split(separator: "@")

    guard parts.count == 2,
          !parts[0].isEmpty,
          !parts[1].isEmpty,
          parts[1].contains("."),
          !value.contains(" ") else {
        return false
    }

    return true
}

struct PropertyFormView<Footer: View, ManageSection: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let title: String
    let subtitle: String
    let systemImage: String
    let validationMessage: String?
    @Binding var nickname: String
    @Binding var addressLine1: String
    @Binding var addressLine2: String
    @Binding var townCity: String
    @Binding var postcode: String
    @Binding var hasTenancyStartDate: Bool
    @Binding var tenancyStartDate: Date
    @Binding var hasTenancyEndDate: Bool
    @Binding var tenancyEndDate: Date
    @Binding var landlordOrAgentName: String
    @Binding var landlordOrAgentEmail: String
    @Binding var depositSchemeName: String
    @Binding var depositReference: String
    @Binding var notes: String
    let footer: Footer
    let manageSection: ManageSection

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        validationMessage: String?,
        nickname: Binding<String>,
        addressLine1: Binding<String>,
        addressLine2: Binding<String>,
        townCity: Binding<String>,
        postcode: Binding<String>,
        hasTenancyStartDate: Binding<Bool>,
        tenancyStartDate: Binding<Date>,
        hasTenancyEndDate: Binding<Bool>,
        tenancyEndDate: Binding<Date>,
        landlordOrAgentName: Binding<String>,
        landlordOrAgentEmail: Binding<String>,
        depositSchemeName: Binding<String>,
        depositReference: Binding<String>,
        notes: Binding<String>,
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder manageSection: () -> ManageSection = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.validationMessage = validationMessage
        _nickname = nickname
        _addressLine1 = addressLine1
        _addressLine2 = addressLine2
        _townCity = townCity
        _postcode = postcode
        _hasTenancyStartDate = hasTenancyStartDate
        _tenancyStartDate = tenancyStartDate
        _hasTenancyEndDate = hasTenancyEndDate
        _tenancyEndDate = tenancyEndDate
        _landlordOrAgentName = landlordOrAgentName
        _landlordOrAgentEmail = landlordOrAgentEmail
        _depositSchemeName = depositSchemeName
        _depositReference = depositReference
        _notes = notes
        self.footer = footer()
        self.manageSection = manageSection()
    }

    var body: some View {
        Group {
            if PlatformLayout.prefersSplitView(for: horizontalSizeClass) {
                RRFormContainer {
                    RRSheetHeader(
                        title: title,
                        subtitle: subtitle,
                        systemImage: systemImage
                    )

                    helperPanel
                    propertySection
                    tenancySection
                    contactSection
                    depositSection
                    notesSection

                    if !isManageSectionEmpty {
                        RRFormSection(title: "Manage record") {
                            manageSection
                        }
                    }

                    footer
                }
            } else {
                Form {
                    Section {
                        RRSheetHeader(
                            title: title,
                            subtitle: subtitle,
                            systemImage: systemImage
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        helperText

                        if let validationMessage {
                            validationLabel(message: validationMessage)
                        }
                    }

                    compactPropertySection
                    compactTenancySection
                    compactContactSection
                    compactDepositSection
                    compactNotesSection

                    if !isManageSectionEmpty {
                        Section {
                            manageSection
                        }
                    }

                    Section {
                        footer
                    }
                }
                .scrollContentBackground(.hidden)
                .background(RRBackgroundView())
            }
        }
    }

    private var helperPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                helperText

                if let validationMessage {
                    validationLabel(message: validationMessage)
                }
            }
        }
    }

    private var helperText: some View {
        Text("Only the property name is needed. You can add more details now or later.")
            .font(RRTypography.footnote)
            .foregroundStyle(RRColours.mutedText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func validationLabel(message: String) -> some View {
        Text(message)
            .font(RRTypography.footnote)
            .foregroundStyle(RRColours.danger)
            .accessibilityLabel("Validation message. \(message)")
            .fixedSize(horizontal: false, vertical: true)
    }

    private var propertySection: some View {
        RRFormSection(title: "Property") {
            RRFormFieldRow(title: "Property name") {
                TextField("Property name", text: $nickname)
                    .rrTextInputAutocapitalizationWords()
                    .textFieldStyle(.roundedBorder)
                    .accessibilityHint("Required")
            }

            RRFormFieldRow(title: "Address line 1") {
                TextField("Address line 1", text: $addressLine1)
                    .rrTextInputAutocapitalizationWords()
                    .textFieldStyle(.roundedBorder)
            }

            RRFormFieldRow(title: "Address line 2") {
                TextField("Address line 2", text: $addressLine2)
                    .rrTextInputAutocapitalizationWords()
                    .textFieldStyle(.roundedBorder)
            }

            RRFormFieldRow(title: "Town or city") {
                TextField("Town or city", text: $townCity)
                    .rrTextInputAutocapitalizationWords()
                    .textFieldStyle(.roundedBorder)
            }

            RRFormFieldRow(title: "Postcode") {
                TextField("Postcode", text: $postcode)
                    .rrTextInputAutocapitalizationCharacters()
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var tenancySection: some View {
        RRFormSection(title: "Tenancy") {
            Toggle("Add start date", isOn: $hasTenancyStartDate.animation())
                .toggleStyle(.switch)

            if hasTenancyStartDate {
                RRFormFieldRow(title: "Tenancy start date") {
                    DatePicker("", selection: $tenancyStartDate, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Toggle("Add end date", isOn: $hasTenancyEndDate.animation())
                .toggleStyle(.switch)

            if hasTenancyEndDate {
                RRFormFieldRow(title: "Tenancy end date") {
                    DatePicker("", selection: $tenancyEndDate, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var contactSection: some View {
        RRFormSection(title: "Landlord or letting agent") {
            RRFormFieldRow(title: "Name") {
                TextField("Name", text: $landlordOrAgentName)
                    .rrTextInputAutocapitalizationWords()
                    .textFieldStyle(.roundedBorder)
            }

            RRFormFieldRow(title: "Email") {
                TextField("Email", text: $landlordOrAgentEmail)
                    .rrEmailKeyboard()
                    .rrTextInputAutocapitalizationNever()
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var depositSection: some View {
        RRFormSection(title: "Deposit") {
            RRFormFieldRow(title: "Scheme name") {
                TextField("Scheme name", text: $depositSchemeName)
                    .rrTextInputAutocapitalizationWords()
                    .textFieldStyle(.roundedBorder)
            }

            RRFormFieldRow(title: "Reference") {
                TextField("Reference", text: $depositReference)
                    .rrTextInputAutocapitalizationCharacters()
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var notesSection: some View {
        RRFormSection(title: "Notes") {
            RRFormFieldRow(
                title: "Notes",
                message: "Add anything you want to keep with this record."
            ) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: RRTheme.cornerRadius, style: .continuous)
                        .fill(RRColours.cardBackground.opacity(0.55))
                        .overlay {
                            RoundedRectangle(cornerRadius: RRTheme.cornerRadius, style: .continuous)
                                .stroke(RRColours.border.opacity(0.3), lineWidth: 1)
                        }

                    if trimmed(notes).isEmpty {
                        Text("Add any notes you want to keep here")
                            .font(RRTypography.body)
                            .foregroundStyle(RRColours.mutedText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $notes)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(minHeight: 140)
                }
                .frame(minHeight: 140)
            }
        }
    }

    private var compactPropertySection: some View {
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

    private var compactTenancySection: some View {
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

    private var compactContactSection: some View {
        Section("Landlord or letting agent") {
            TextField("Name", text: $landlordOrAgentName)
                .rrTextInputAutocapitalizationWords()

            TextField("Email", text: $landlordOrAgentEmail)
                .rrEmailKeyboard()
                .rrTextInputAutocapitalizationNever()
                .autocorrectionDisabled()
        }
    }

    private var compactDepositSection: some View {
        Section("Deposit") {
            TextField("Scheme name", text: $depositSchemeName)
                .rrTextInputAutocapitalizationWords()

            TextField("Reference", text: $depositReference)
                .rrTextInputAutocapitalizationCharacters()
        }
    }

    private var compactNotesSection: some View {
        Section("Notes") {
            TextField("Add any notes you want to keep here", text: $notes, axis: .vertical)
                .lineLimit(4...8)
        }
    }

    private var isManageSectionEmpty: Bool {
        ManageSection.self == EmptyView.self
    }
}
