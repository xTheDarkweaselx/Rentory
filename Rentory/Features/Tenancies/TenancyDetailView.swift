//
//  TenancyDetailView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 19/05/2026.
//

import SwiftData
import SwiftUI

struct TenancyDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppColourTheme.storageKey) private var appColourThemeRawValue = AppColourTheme.defaultLook.rawValue

    let tenancy: Tenancy
    let propertyPack: PropertyPack

    @State private var mode: TenancyMode
    @State private var isShowingModeChooser = false
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var status: TenancyStatus
    @State private var tenancyType: TenancyType
    @State private var depositAmountText: String
    @State private var depositSchemeName: String
    @State private var depositReference: String
    @State private var rentAmountText: String
    @State private var rentFrequency: RentFrequency
    @State private var hasSignedOnDate: Bool
    @State private var signedOnDate: Date
    @State private var hasBreakClauseDate: Bool
    @State private var breakClauseDate: Date
    @State private var notes: String
    @State private var newTenantName = ""
    @State private var alertContent: RRAlertContent?
    @State private var isShowingDeleteConfirmation = false

    init(tenancy: Tenancy, propertyPack: PropertyPack) {
        self.tenancy = tenancy
        self.propertyPack = propertyPack
        _mode = State(initialValue: tenancy.mode)
        _startDate = State(initialValue: tenancy.startDate)
        _hasEndDate = State(initialValue: tenancy.endDate != nil)
        _endDate = State(initialValue: tenancy.endDate ?? (Calendar.current.date(byAdding: .year, value: 1, to: tenancy.startDate) ?? .now))
        _status = State(initialValue: tenancy.status)
        _tenancyType = State(initialValue: tenancy.tenancyType)
        _depositAmountText = State(initialValue: tenancy.depositAmount.map { String(format: "%.2f", $0) } ?? "")
        _depositSchemeName = State(initialValue: tenancy.depositSchemeName ?? "")
        _depositReference = State(initialValue: tenancy.depositReference ?? "")
        _rentAmountText = State(initialValue: tenancy.rentAmount.map { String(format: "%.2f", $0) } ?? "")
        _rentFrequency = State(initialValue: tenancy.rentFrequency ?? .monthly)
        _hasSignedOnDate = State(initialValue: tenancy.signedOnDate != nil)
        _signedOnDate = State(initialValue: tenancy.signedOnDate ?? tenancy.startDate)
        _hasBreakClauseDate = State(initialValue: tenancy.breakClauseDate != nil)
        _breakClauseDate = State(initialValue: tenancy.breakClauseDate ?? tenancy.startDate)
        _notes = State(initialValue: tenancy.notes ?? "")
    }

    private var sortedTenants: [Tenant] {
        tenancy.tenants.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                RRSheetHeader(
                    title: "Edit tenancy",
                    subtitle: "Update the dates, deposit, tenants, or any other detail.",
                    systemImage: "person.2.fill"
                )

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

                statusBanner

                RRDestructiveButton(title: "Delete tenancy") {
                    isShowingDeleteConfirmation = true
                }
            }
            .frame(maxWidth: PlatformLayout.preferredDialogWidth, alignment: .leading)
            .padding(RRTheme.screenPadding)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .scrollIndicators(.hidden)
        .background(RRBackgroundView())
        .navigationTitle(navigationTitle)
        .rrInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .rrPrimaryAction) {
                Button("Save") { saveChanges() }
            }
        }
        .sheet(isPresented: $isShowingModeChooser) {
            TenancyModeChooserSheet(mode: $mode).rrAdaptiveSheetPresentation()
        }
        .confirmationDialog("Delete tenancy?", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteTenancy() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The tenancy, all tenants on it, and their details will be removed from this property.")
        }
        .alert(item: $alertContent) { content in
            Alert(title: Text(content.title), message: Text(content.message), dismissButton: .cancel(Text(content.buttonTitle)))
        }
        .id(appColourThemeRawValue)
    }

    private var navigationTitle: String {
        sortedTenants.first?.name.isEmpty == false ? sortedTenants.first!.name : "Tenancy"
    }

    private var statusBanner: some View {
        let derived = tenancy.derivedStatus()
        if derived != status {
            return AnyView(
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(RRColours.warning)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dates suggest status: \(derived.rawValue).")
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.primary)
                        Button("Switch to \(derived.rawValue)") {
                            status = derived
                        }
                        .font(RRTypography.footnote.weight(.semibold))
                        .foregroundStyle(RRColours.secondary)
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(RRColours.warning.opacity(0.12)))
            )
        }
        return AnyView(EmptyView())
    }

    // MARK: - Panels

    private var modePanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                RRSectionHeader(title: "Mode", subtitle: mode.summary)
                Picker("Mode", selection: $mode) {
                    ForEach(TenancyMode.allCases) { Text($0.shortTitle).tag($0) }
                }
                .pickerStyle(.segmented)
                Button { isShowingModeChooser = true } label: {
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
                    subtitle: sortedTenants.isEmpty ? "No tenants yet." : "\(sortedTenants.count) on this tenancy"
                )

                let displayed = mode == .standard ? Array(sortedTenants.prefix(1)) : sortedTenants
                ForEach(Array(displayed.enumerated()), id: \.element.id) { index, tenant in
                    tenantRow(tenant, index: index)
                    if index < displayed.count - 1 {
                        Divider().background(RRColours.border)
                    }
                }

                if mode == .comprehensive || sortedTenants.isEmpty {
                    HStack {
                        TextField("Add another tenant by name", text: $newTenantName)
                            .textFieldStyle(.roundedBorder)
                            .rrTextInputAutocapitalizationWords()
                        Button("Add") {
                            addTenant()
                        }
                        .disabled(newTenantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(.borderedProminent)
                        .tint(RRColours.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tenantRow(_ tenant: Tenant, index: Int) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Name", text: Binding(get: { tenant.name }, set: { tenant.name = $0 }))
                    .textFieldStyle(.roundedBorder)
                    .rrTextInputAutocapitalizationWords()
                TextField("Email (optional)", text: Binding(get: { tenant.email ?? "" }, set: { tenant.email = optionalText($0) }))
                    .textFieldStyle(.roundedBorder)
                TextField("Phone (optional)", text: Binding(get: { tenant.phone ?? "" }, set: { tenant.phone = optionalText($0) }))
                    .textFieldStyle(.roundedBorder)
            }

            if sortedTenants.count > 1 {
                Button {
                    modelContext.delete(tenant)
                    try? modelContext.save()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(RRColours.danger)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove tenant")
            }
        }
        .padding(.vertical, 4)
    }

    private var datesPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                RRSectionHeader(title: "Dates")
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
                RRSectionHeader(title: "Deposit")
                labelledField("Amount") { TextField("0.00", text: $depositAmountText).textFieldStyle(.roundedBorder) }
                if mode == .comprehensive {
                    labelledField("Scheme") {
                        TextField("e.g. DPS, MyDeposits, TDS", text: $depositSchemeName)
                            .textFieldStyle(.roundedBorder)
                            .rrTextInputAutocapitalizationWords()
                    }
                }
                labelledField("Reference") { TextField("Deposit reference", text: $depositReference).textFieldStyle(.roundedBorder) }
            }
        }
    }

    private var rentPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                RRSectionHeader(title: "Rent")
                labelledField("Amount") { TextField("0.00", text: $rentAmountText).textFieldStyle(.roundedBorder) }
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
                RRSectionHeader(title: "Comprehensive details")
                Toggle("Has signed-on date", isOn: $hasSignedOnDate.animation()).tint(RRColours.secondary)
                if hasSignedOnDate { DatePicker("Signed on", selection: $signedOnDate, displayedComponents: .date) }
                Toggle("Has break clause date", isOn: $hasBreakClauseDate.animation()).tint(RRColours.secondary)
                if hasBreakClauseDate { DatePicker("Break clause", selection: $breakClauseDate, displayedComponents: .date) }
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

    // MARK: - Helpers + actions

    @ViewBuilder
    private func labelledField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
            Text(label)
                .font(RRTypography.footnote.weight(.semibold))
                .foregroundStyle(RRColours.mutedText)
            content()
        }
    }

    private func addTenant() {
        let trimmed = newTenantName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextOrder = (sortedTenants.last?.sortOrder ?? -1) + 1
        let tenant = Tenant(name: trimmed, sortOrder: nextOrder)
        tenancy.tenants.append(tenant)
        tenancy.updatedAt = .now
        try? modelContext.save()
        newTenantName = ""
    }

    private func saveChanges() {
        tenancy.mode = mode
        tenancy.startDate = startDate
        tenancy.endDate = hasEndDate ? endDate : nil
        tenancy.status = status
        tenancy.tenancyType = tenancyType
        tenancy.depositAmount = parseDouble(depositAmountText)
        tenancy.depositSchemeName = optionalText(depositSchemeName)
        tenancy.depositReference = optionalText(depositReference)
        tenancy.rentAmount = parseDouble(rentAmountText)
        tenancy.rentFrequency = rentFrequency
        tenancy.signedOnDate = hasSignedOnDate ? signedOnDate : nil
        tenancy.breakClauseDate = hasBreakClauseDate ? breakClauseDate : nil
        tenancy.notes = optionalText(notes)
        tenancy.updatedAt = .now
        propertyPack.updatedAt = .now

        do {
            try modelContext.save()
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeSaved)
        }
    }

    private func deleteTenancy() {
        modelContext.delete(tenancy)
        propertyPack.updatedAt = .now
        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertContent = RRAlertContent(
                title: "Tenancy not deleted",
                message: "This tenancy could not be deleted. Please try again."
            )
        }
    }

    private func parseDouble(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }
}
