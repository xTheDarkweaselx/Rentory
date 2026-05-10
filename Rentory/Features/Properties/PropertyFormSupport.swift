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

enum PropertyEditorTab: String, CaseIterable, Identifiable {
    case basics = "Basics"
    case tenancy = "Tenancy"
    case contacts = "Contacts"
    case files = "Files"
    case notes = "Notes"

    var id: String { rawValue }
}

struct PropertyFormView<FilesContent: View, Footer: View, ManageSection: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let validationMessage: String?
    @Binding var recordType: PropertyRecordType
    @Binding var isFavourite: Bool
    @Binding var nickname: String
    @Binding var buildingName: String
    @Binding var spaceIdentifier: String
    @Binding var floorLevel: String
    @Binding var mainPropertyName: String
    @Binding var accessDetails: String
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
    let filesContent: FilesContent
    let footer: Footer
    let manageSection: ManageSection

    @State private var selectedTab: PropertyEditorTab = .basics

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        validationMessage: String?,
        recordType: Binding<PropertyRecordType>,
        isFavourite: Binding<Bool>,
        nickname: Binding<String>,
        buildingName: Binding<String>,
        spaceIdentifier: Binding<String>,
        floorLevel: Binding<String>,
        mainPropertyName: Binding<String>,
        accessDetails: Binding<String>,
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
        @ViewBuilder filesContent: () -> FilesContent,
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder manageSection: () -> ManageSection = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.validationMessage = validationMessage
        _recordType = recordType
        _isFavourite = isFavourite
        _nickname = nickname
        _buildingName = buildingName
        _spaceIdentifier = spaceIdentifier
        _floorLevel = floorLevel
        _mainPropertyName = mainPropertyName
        _accessDetails = accessDetails
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
        self.filesContent = filesContent()
        self.footer = footer()
        self.manageSection = manageSection()
    }

    var body: some View {
        RRAdaptiveModalContainer(
            preferredWidth: PlatformLayout.preferredRecordDialogWidth,
            preferredHeight: 760,
            minWidth: 900,
            minHeight: 640
        ) {
            RRSheetHeader(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage
            )
        } topBar: {
            VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                if let validationMessage {
                    validationLabel(message: validationMessage)
                        .padding(.horizontal, 4)
                }
                tabPicker
            }
        } content: {
            selectedTabContent
        } footer: {
            footer
        }
    }

    private var tabPicker: some View {
        RRGlassPanel(padding: 14) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    tabButtons
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        tabButtons
                    }
                }
            }
        }
    }

    private var tabButtons: some View {
        ForEach(PropertyEditorTab.allCases) { tab in
            Button {
                selectedTab = tab
            } label: {
                Text(tab.rawValue)
                    .font(RRTypography.body.weight(.semibold))
                    .foregroundStyle(selectedTab == tab ? Color.white : RRColours.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(selectedTab == tab ? Color.accentColor.opacity(0.94) : RRColours.cardBackground.opacity(0.55))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .basics:
            RRResponsiveFormGrid(items: basicsTabItems)
        case .tenancy:
            RRResponsiveFormGrid(items: [
                RRResponsiveFormGridItem {
                    tenancyDatesSection
                },
                RRResponsiveFormGridItem {
                    depositSection
                },
            ])
        case .contacts:
            RRResponsiveFormGrid(items: [
                RRResponsiveFormGridItem {
                    contactsSection
                },
            ])
        case .files:
            filesContent
        case .notes:
            RRResponsiveFormGrid(items: noteTabItems)
        }
    }

    private var noteTabItems: [RRResponsiveFormGridItem] {
        var items: [RRResponsiveFormGridItem] = [
            RRResponsiveFormGridItem(span: .fullWidth) {
                notesSection
            },
        ]

        if !isManageSectionEmpty {
            items.append(
                RRResponsiveFormGridItem(span: .fullWidth) {
                    RRFormSection(title: "Manage record") {
                        manageSection
                    }
                }
            )
        }

        return items
    }

    private func validationLabel(message: String) -> some View {
        Text(message)
            .font(RRTypography.footnote)
            .foregroundStyle(RRColours.danger)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var basicsTabItems: [RRResponsiveFormGridItem] {
        var items: [RRResponsiveFormGridItem] = [
            RRResponsiveFormGridItem {
                basicsSection
            },
            RRResponsiveFormGridItem {
                recordTypeSection
            },
        ]

        if !recordType.extraFields.isEmpty {
            items.append(
                RRResponsiveFormGridItem {
                    typeDetailsSection
                }
            )
        }

        items.append(
            RRResponsiveFormGridItem {
                addressSection
            }
        )

        return items
    }

    private var basicsSection: some View {
        RRFormSection(title: "Basics", message: propertyValidationMessage) {
            RRFormFieldRow(title: "Property name") {
                TextField("Property name", text: $nickname)
                    .rrTextInputAutocapitalizationWords()
                    .textFieldStyle(.roundedBorder)
                    .accessibilityHint("Required")
            }

            Toggle(isOn: $isFavourite.animation()) {
                Label("Favourite", systemImage: isFavourite ? "star.fill" : "star")
            }
            .toggleStyle(.switch)
        }
    }

    private var recordTypeSection: some View {
        RRFormSection(title: "Record type", message: recordType.shortDescription) {
            Picker("Record type", selection: $recordType) {
                ForEach(PropertyRecordType.allCases) { type in
                    Label(type.rawValue, systemImage: type.iconName)
                        .tag(type)
                }
            }
            .pickerStyle(.menu)

            HStack(spacing: RRTheme.controlSpacing) {
                RRIconBadge(systemName: recordType.iconName, tint: RRColours.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(recordType.rawValue)
                        .font(RRTypography.headline)
                        .foregroundStyle(RRColours.primary)
                    Text(recordType.shortDescription)
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var typeDetailsSection: some View {
        RRFormSection(title: "Type details", message: "Add the details that make this record easy to recognise later.") {
            ForEach(recordType.extraFields) { field in
                RRFormFieldRow(title: field.title(for: recordType)) {
                    textField(for: field)
                }
            }
        }
    }

    @ViewBuilder
    private func textField(for field: PropertyExtraField) -> some View {
        switch field {
        case .buildingName:
            TextField(field.title(for: recordType), text: $buildingName)
                .rrTextInputAutocapitalizationWords()
                .textFieldStyle(.roundedBorder)
        case .spaceIdentifier:
            TextField(field.title(for: recordType), text: $spaceIdentifier)
                .rrTextInputAutocapitalizationWords()
                .textFieldStyle(.roundedBorder)
        case .floorLevel:
            TextField(field.title(for: recordType), text: $floorLevel)
                .rrTextInputAutocapitalizationWords()
                .textFieldStyle(.roundedBorder)
        case .mainPropertyName:
            TextField(field.title(for: recordType), text: $mainPropertyName)
                .rrTextInputAutocapitalizationWords()
                .textFieldStyle(.roundedBorder)
        case .accessDetails:
            TextField(field.title(for: recordType), text: $accessDetails, axis: .vertical)
                .lineLimit(2...4)
                .rrTextInputAutocapitalizationWords()
                .textFieldStyle(.roundedBorder)
        }
    }

    private var addressSection: some View {
        RRFormSection(title: "Address") {
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

    private var tenancyDatesSection: some View {
        RRFormSection(title: "Tenancy", message: tenancyValidationMessage) {
            Toggle("Add tenancy start date", isOn: $hasTenancyStartDate.animation())
                .toggleStyle(.switch)

            if hasTenancyStartDate {
                RRFormFieldRow(title: "Tenancy start date") {
                    DatePicker("", selection: $tenancyStartDate, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Toggle("Add tenancy end date", isOn: $hasTenancyEndDate.animation())
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

    private var contactsSection: some View {
        RRFormSection(title: "Contacts", message: contactValidationMessage) {
            RRFormFieldRow(title: "Landlord or letting agent name") {
                TextField("Name", text: $landlordOrAgentName)
                    .rrTextInputAutocapitalizationWords()
                    .textFieldStyle(.roundedBorder)
            }

            RRFormFieldRow(title: "Landlord or letting agent email") {
                TextField("Email", text: $landlordOrAgentEmail)
                    .rrEmailKeyboard()
                    .rrTextInputAutocapitalizationNever()
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var notesSection: some View {
        RRFormSection(title: "Notes", message: "Add anything useful you want to remember.") {
            VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                Text("Notes")
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)

                notesEditor
            }
        }
    }

    private var notesEditor: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: RRTheme.cornerRadius, style: .continuous)
                .fill(RRColours.cardBackground.opacity(0.55))
                .overlay {
                    RoundedRectangle(cornerRadius: RRTheme.cornerRadius, style: .continuous)
                        .stroke(RRColours.border.opacity(0.3), lineWidth: 1)
                }

            if trimmed(notes).isEmpty {
                Text("Add anything useful you want to remember.")
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
                .frame(minHeight: 180)
        }
        .frame(minHeight: 180)
    }

    private var isManageSectionEmpty: Bool {
        ManageSection.self == EmptyView.self
    }

    private var propertyValidationMessage: String? {
        switch validationMessage {
        case "Add a property name to save this record.", "Add a property name to continue.":
            validationMessage
        default:
            nil
        }
    }

    private var tenancyValidationMessage: String? {
        validationMessage == "Check the tenancy dates. The end date can’t be before the start date." ? validationMessage : nil
    }

    private var contactValidationMessage: String? {
        validationMessage == "Check the email address or leave it blank." ? validationMessage : nil
    }
}
