//
//  ExportOptionsView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct ExportOptionsView: View {
    let propertyPack: PropertyPack
    let showsHelpfulNote: Bool

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var options = ExportOptions()
    @State private var createdReportURL: URL?
    @State private var userFacingError: UserFacingError?
    @State private var isCreatingReport = false
    @State private var upgradePromptContent: UpgradePromptContent?

    private let exportService = PDFExportService()

    var body: some View {
        RRMacSheetContainer(maxWidth: 760) {
            HStack {
                Form {
                    Section {
                        RRSheetHeader(
                            title: "Create report",
                            subtitle: "Choose what to include before you create your report.",
                            systemImage: "doc.badge.gearshape"
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        if showsHelpfulNote {
                            Text("You can create a report now, or add more details first.")
                                .font(RRTypography.footnote)
                                .foregroundStyle(RRColours.mutedText)
                        }
                    }

                    Section("Property details") {
                        Toggle("Property name", isOn: $options.includePropertyName)
                        Toggle("Town or postcode", isOn: $options.includeTownOrPostcode)
                        Toggle("Full address", isOn: $options.includeFullAddress)
                        Toggle("Tenancy dates", isOn: $options.includeTenancyDates)
                        Toggle("Landlord or letting agent details", isOn: $options.includeLandlordOrAgentDetails)
                        Toggle("Deposit details", isOn: $options.includeDepositDetails)
                    }

                    Section("Record details") {
                        Toggle("Rooms and checklists", isOn: $options.includeRooms)
                        Toggle("Notes", isOn: $options.includeChecklistNotes)
                        Toggle("Photos", isOn: $options.includePhotos)
                        Toggle("Documents list", isOn: $options.includeDocumentsList)
                        Toggle("Timeline", isOn: $options.includeTimeline)
                    }

                    Section("Included with every report") {
                        ReportDisclaimerView()
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }

                    Section {
                        ExportPreviewSummaryView(options: options)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }

                    Section {
                        RRPrimaryButton(title: isCreatingReport ? "Creating report…" : "Create report", isDisabled: isCreatingReport) {
                            createReport()
                        }
                        .listRowBackground(Color.clear)
                        .accessibilityHint("Creates a report on this device.")
                    }
                }
                .frame(maxWidth: DeviceLayout.contentWidth(for: horizontalSizeClass, maximum: 760))
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Create report")
        .rrInlineNavigationTitle()
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
        .overlay {
            if isCreatingReport {
                ZStack {
                    Color.black.opacity(0.12)
                        .ignoresSafeArea()

                    RRLoadingView(
                        title: "Creating report",
                        message: "Please wait while your report is created."
                    )
                    .padding(24)
                }
            }
        }
        .navigationDestination(item: $createdReportURL) { reportURL in
            ReportReadyView(reportURL: reportURL)
        }
        .alert(item: $userFacingError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .cancel(Text(error.recoveryActionTitle ?? "OK"))
            )
        }
        .onChange(of: options.includeDisclaimer) { _, _ in
            options.includeDisclaimer = true
        }
        .sheet(item: $upgradePromptContent) { content in
            LimitReachedView(title: content.title, message: content.message)
        }
    }

    private func createReport() {
        options.includeDisclaimer = true

        guard FeatureAccessService.canCreateFullReport(isUnlocked: entitlementManager.isUnlocked) else {
            upgradePromptContent = FeatureAccessService.reportLimitPrompt
            return
        }

        isCreatingReport = true

        do {
            createdReportURL = try exportService.createReport(for: propertyPack, options: options)
        } catch {
            userFacingError = .reportCouldNotBeCreated
        }

        isCreatingReport = false
    }
}
