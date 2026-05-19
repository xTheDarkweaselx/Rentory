//
//  AddTenancyView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 19/05/2026.
//

import SwiftData
import SwiftUI

struct AddTenancyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppColourTheme.storageKey) private var appColourThemeRawValue = AppColourTheme.defaultLook.rawValue

    let propertyPack: PropertyPack

    @State private var mode: TenancyMode = .standard
    @State private var isShowingModeChooser = false

    @State private var tenantDrafts: [TenantDraft] = [TenantDraft()]
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now
    @State private var status: TenancyStatus = .upcoming
    @State private var tenancyType: TenancyType = .assuredShorthold
    @State private var depositAmountText = ""
    @State private var depositSchemeName = ""
    @State private var depositReference = ""
    @State private var rentAmountText = ""
    @State private var rentFrequency: RentFrequency = .monthly
    @State private var hasSignedOnDate = false
    @State private var signedOnDate = Date()
    @State private var hasBreakClauseDate = false
    @State private var breakClauseDate = Date()
    @State private var notes = ""
    @State private var validationMessage: String?
    @State private var alertContent: RRAlertContent?

    var body: some View {
        NavigationStack {
            ZStack {
                RRBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Add tenancy",
                            subtitle: "Record a tenancy on this property. Standard mode is quick; Comprehensive covers more.",
                            systemImage: "person.2.fill"
                        )

                        if let validationMessage {
                            validationCard(validationMessage)
                        }

                        modePanel
                        tenantsPanel
                        datesPanel
                        statusPanel
                        depositPanel
                        rentPanel

                        if mode == .comprehensive {
                            comprehensivePanel
                        }

                        notesPanel

                        if !PlatformLayout.isMac {
                            footerButtonsPanel
                        }
                    }
                    .frame(maxWidth: PlatformLayout.preferredDialogWidth, alignment: .leading)
                    .padding(RRTheme.screenPadding)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Add tenancy")
            .rrInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .rrPrimaryAction) {
                    Button("Save") { saveTenancy() }
                }
            }
        }
        .sheet(isPresented: $isShowingModeChooser) {
            TenancyModeChooserSheet(mode: $mode)
                .rrAdaptiveSheetPresentation()
        }
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
        .id(appColourThemeRawValue)
    }

    // MARK: - Panels

    private var modePanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                RRSectionHeader(
                    title: "Mode",
                    subtitle: mode.summary
                )

                Picker("Mode", selection: $mode) {
                    ForEach(TenancyMode.allCases) { mode in
                        Text(mode.shortTitle).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    isShowingModeChooser = true
                } label: {
                    Label("Not sure? Help me decide", systemImage: "questionmark.circle")
                        .font(RRTypography.footnote.weight(.semibold))
                        .foregroundStyle(RRColours.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var tenantsPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                RRSectionHeader(
                    title: mode == .standard ? "Tenant" : "Tenants",
                    subtitle: mode == .standard ? "Name + contact details." : "Add a row for each tenant on the agreement."
                )

                let displayedRange = mode == .standard ? 0..<1 : 0..<tenantDrafts.count
                ForEach(Array(displayedRange), id: \.self) { index in
                    tenantRow(index: index)
                    if index < displayedRange.upperBound - 1 {
                        Divider().background(RRColours.border)
                    }
                }

                if mode == .comprehensive {
                    Button {
                        tenantDrafts.append(TenantDraft())
                    } label: {
                        Label("Add another tenant", systemImage: "person.badge.plus")
                            .font(RRTypography.footnote.weight(.semibold))
                            .foregroundStyle(RRColours.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func tenantRow(index: Int) -> some View {
        VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
            HStack {
                Text(mode == .standard ? "Tenant" : "Tenant \(index + 1)")
                    .font(RRTypography.footnote.weight(.semibold))
                    .foregroundStyle(RRColours.mutedText)
                Spacer()
                if mode == .comprehensive && tenantDrafts.count > 1 {
                    Button {
                        tenantDrafts.remove(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(RRColours.danger)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove tenant \(index + 1)")
                }
            }

            TextField("Name", text: tenantBinding(index, keyPath: \.name))
                .textFieldStyle(.roundedBorder)
                .rrTextInputAutocapitalizationWords()

            TextField("Email (optional)", text: tenantBinding(index, keyPath: \.email))
                .textFieldStyle(.roundedBorder)

            TextField("Phone (optional)", text: tenantBinding(index, keyPath: \.phone))
                .textFieldStyle(.roundedBorder)
        }
    }

    private var datesPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                RRSectionHeader(title: "Dates", subtitle: "When does the tenancy run?")

                DatePicker("Start date", selection: $startDate, displayedComponents: .date)

                Toggle("Has end date", isOn: $hasEndDate.animation())
                    .tint(RRColours.secondary)

                if hasEndDate {
                    DatePicker("End date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
            }
        }
    }

    private var statusPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                RRSectionHeader(title: "Status & type")

                labelledField("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(TenancyStatus.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                }

                labelledField("Type") {
                    Picker("Type", selection: $tenancyType) {
                        ForEach(TenancyType.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }

    private var depositPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                RRSectionHeader(title: "Deposit", subtitle: "Optional — leave blank if not applicable.")

                labelledField("Amount") {
                    TextField("0.00", text: $depositAmountText)
                        .textFieldStyle(.roundedBorder)
                }

                if mode == .comprehensive {
                    labelledField("Scheme") {
                        TextField("e.g. DPS, MyDeposits, TDS", text: $depositSchemeName)
                            .textFieldStyle(.roundedBorder)
                            .rrTextInputAutocapitalizationWords()
                    }
                }

                labelledField("Reference") {
                    TextField("Deposit reference", text: $depositReference)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var rentPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                RRSectionHeader(title: "Rent", subtitle: "Optional — leave blank if not applicable.")

                labelledField("Amount") {
                    TextField("0.00", text: $rentAmountText)
                        .textFieldStyle(.roundedBorder)
                }

                labelledField("Frequency") {
                    Picker("Frequency", selection: $rentFrequency) {
                        ForEach(RentFrequency.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }

    private var comprehensivePanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                RRSectionHeader(title: "Comprehensive details", subtitle: "Signed agreement, break clause, inventory.")

                Toggle("Has signed-on date", isOn: $hasSignedOnDate.animation())
                    .tint(RRColours.secondary)
                if hasSignedOnDate {
                    DatePicker("Signed on", selection: $signedOnDate, displayedComponents: .date)
                }

                Toggle("Has break clause date", isOn: $hasBreakClauseDate.animation())
                    .tint(RRColours.secondary)
                if hasBreakClauseDate {
                    DatePicker("Break clause", selection: $breakClauseDate, displayedComponents: .date)
                }

                Text("Inventory document linking will be available from a tenancy's details after creation.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }
        }
    }

    private var notesPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                RRSectionHeader(title: "Notes")

                TextField("Anything useful to remember", text: $notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }
        }
    }

    private var footerButtonsPanel: some View {
        RRGlassPanel {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: RRTheme.controlSpacing) {
                    Spacer()
                    footerActionButtons
                }
                VStack(spacing: RRTheme.controlSpacing) {
                    footerActionButtons
                }
            }
        }
        .tint(RRColours.secondary)
    }

    @ViewBuilder
    private var footerActionButtons: some View {
        RRSecondaryButton(title: "Cancel") { dismiss() }
            .frame(maxWidth: PlatformLayout.prefersFooterButtons ? 150 : .infinity)
        RRPrimaryButton(title: "Save tenancy") { saveTenancy() }
            .frame(maxWidth: PlatformLayout.prefersFooterButtons ? 170 : .infinity)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func labelledField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
            Text(label)
                .font(RRTypography.footnote.weight(.semibold))
                .foregroundStyle(RRColours.mutedText)
            content()
        }
    }

    private func validationCard(_ message: String) -> some View {
        RRGlassPanel {
            Text(message)
                .font(RRTypography.footnote.weight(.semibold))
                .foregroundStyle(RRColours.danger)
        }
    }

    private func tenantBinding(_ index: Int, keyPath: WritableKeyPath<TenantDraft, String>) -> Binding<String> {
        Binding(
            get: {
                guard tenantDrafts.indices.contains(index) else { return "" }
                return tenantDrafts[index][keyPath: keyPath]
            },
            set: { newValue in
                guard tenantDrafts.indices.contains(index) else { return }
                tenantDrafts[index][keyPath: keyPath] = newValue
            }
        )
    }

    private func saveTenancy() {
        let usableDrafts = tenantDrafts
            .filter { !$0.isEmpty }
            .enumerated()
            .map { offset, draft in (offset, draft) }

        guard !usableDrafts.isEmpty else {
            validationMessage = "Add at least one tenant name."
            return
        }

        let tenants = usableDrafts.map { offset, draft in
            Tenant(
                name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: optionalText(draft.email),
                phone: optionalText(draft.phone),
                sortOrder: offset
            )
        }

        let tenancy = Tenancy(
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            status: status,
            tenancyType: tenancyType,
            depositAmount: parseDouble(depositAmountText),
            depositSchemeName: optionalText(depositSchemeName),
            depositReference: optionalText(depositReference),
            rentAmount: parseDouble(rentAmountText),
            rentFrequency: rentFrequency,
            notes: optionalText(notes),
            signedOnDate: hasSignedOnDate ? signedOnDate : nil,
            breakClauseDate: hasBreakClauseDate ? breakClauseDate : nil,
            mode: mode,
            tenants: tenants
        )

        propertyPack.tenancies.append(tenancy)
        propertyPack.updatedAt = .now

        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeSaved)
        }
    }

    private func parseDouble(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }
}

struct TenantDraft: Identifiable, Equatable {
    let id = UUID()
    var name: String = ""
    var email: String = ""
    var phone: String = ""

    var isEmpty: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
