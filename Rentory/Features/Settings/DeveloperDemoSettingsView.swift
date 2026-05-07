//
//  DeveloperDemoSettingsView.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import SwiftData
import SwiftUI

#if DEBUG
@MainActor
struct DeveloperDemoSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.rrUsesEmbeddedNavigationLayout) private var usesEmbeddedNavigationLayout
    @Query private var propertyPacks: [PropertyPack]

    @State private var isShowingLoadConfirmation = false
    @State private var isShowingClearConfirmation = false
    @State private var alertContent: RRAlertContent?
    @State private var isWorking = false
    @State private var loadsFullSampleSet = true

    private let demoDataFactory = DemoDataFactory()

    private var hasDemoRecord: Bool {
        propertyPacks.contains(where: DemoModeSettings.matchesDemoRecord)
    }

    private var demoRecordCount: Int {
        propertyPacks.filter(DemoModeSettings.matchesDemoRecord).count
    }

    var body: some View {
        Group {
            if PlatformLayout.isPhone && horizontalSizeClass != .regular {
                compactView
            } else if usesEmbeddedNavigationLayout {
                RRFormContainer(maxWidth: 880) {
                    RRResponsiveFormGrid(items: [
                        RRResponsiveFormGridItem {
                            statusPanel
                        },
                        RRResponsiveFormGridItem {
                            actionsPanel
                        },
                    ])
                }
            } else {
                RRMacSheetContainer(maxWidth: 880, minHeight: PlatformLayout.isMac ? 560 : nil) {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Demo Data",
                            subtitle: "Use fake sample data for testing and screenshots.",
                            systemImage: "wand.and.stars"
                        )

                        RRResponsiveFormGrid(items: [
                            RRResponsiveFormGridItem {
                                statusPanel
                            },
                            RRResponsiveFormGridItem {
                                actionsPanel
                            },
                        ])
                    }
                }
            }
        }
        .navigationTitle("Demo data")
        .rrInlineNavigationTitle()
        .overlay {
            if isWorking {
                ZStack {
                    Color.black.opacity(0.12)
                        .ignoresSafeArea()

                    RRLoadingView(
                        title: "Preparing demo data",
                        message: "Please wait while fake sample content is created."
                    )
                    .padding(24)
                }
            }
        }
        .rrConfirmationDialog(
            RRDialogContent(
                title: loadsFullSampleSet ? "Load sample set?" : "Load sample record?",
                message: loadsFullSampleSet
                    ? "This adds a fuller set of fake records, rooms, photos, documents and timeline events for testing and screenshots."
                    : "This adds one fake rental record for testing and screenshots.",
                confirmTitle: loadsFullSampleSet ? "Load sample set" : "Load sample record",
                cancelTitle: "Cancel"
            ),
            isPresented: $isShowingLoadConfirmation
        ) {
            loadDemoRecord()
        }
        .rrConfirmationDialog(
            RRDialogContent(
                title: "Clear demo data?",
                message: "This removes the fake sample records and their sample files.",
                confirmTitle: "Clear demo data",
                cancelTitle: "Cancel",
                confirmRole: .destructive
            ),
            isPresented: $isShowingClearConfirmation
        ) {
            clearDemoData()
        }
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
    }

    private var compactView: some View {
        Form {
            Section("Demo data") {
                Text(
                    hasDemoRecord
                    ? "\(demoRecordCount) sample record\(demoRecordCount == 1 ? "" : "s") ready to use."
                    : "No sample records have been loaded yet."
                )
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)

                Toggle("Load the fullest sample set", isOn: $loadsFullSampleSet)
            }

            Section {
                RRPrimaryButton(title: loadsFullSampleSet ? "Load sample set" : "Load sample record", isDisabled: isWorking) {
                    isShowingLoadConfirmation = true
                }

                RRDestructiveButton(title: "Clear demo data", isDisabled: isWorking || !hasDemoRecord) {
                    isShowingClearConfirmation = true
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
    }

    private var statusPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Demo data")
                    .font(RRTypography.headline)

                Text("Use fake data for testing and screenshots.")
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)

                Text(
                    hasDemoRecord
                    ? "\(demoRecordCount) sample record\(demoRecordCount == 1 ? "" : "s") ready to use."
                    : "No sample records have been loaded yet."
                )
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)

                Toggle("Load the fullest sample set", isOn: $loadsFullSampleSet)
                    .toggleStyle(.switch)
            }
        }
    }

    private var actionsPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Actions")
                    .font(RRTypography.headline)

                RRPrimaryButton(title: loadsFullSampleSet ? "Load sample set" : "Load sample record", isDisabled: isWorking) {
                    isShowingLoadConfirmation = true
                }

                RRDestructiveButton(title: "Clear demo data", isDisabled: isWorking || !hasDemoRecord) {
                    isShowingClearConfirmation = true
                }
            }
        }
    }

    private func loadDemoRecord() {
        isWorking = true
        defer { isWorking = false }

        do {
            let style: DemoDataFactory.SampleDataStyle = loadsFullSampleSet ? .fullSampleSet : .singleRecord
            let loadedRecords = try demoDataFactory.loadSampleData(context: modelContext, style: style)
            alertContent = RRAlertContent(
                title: loadsFullSampleSet ? "Sample set ready" : "Sample record ready",
                message: loadsFullSampleSet
                    ? "\(loadedRecords.count) fake sample records are ready for testing and screenshots."
                    : "Fake sample data is ready for testing and screenshots."
            )
        } catch {
            alertContent = RRAlertContent(error: .somethingWentWrong)
        }
    }

    private func clearDemoData() {
        isWorking = true
        defer { isWorking = false }

        do {
            try demoDataFactory.clearDemoData(context: modelContext)
            alertContent = RRAlertContent(
                title: "Demo data cleared",
                message: "The fake sample records and their files have been removed."
            )
        } catch {
            alertContent = RRAlertContent(error: .somethingWentWrong)
        }
    }
}
#endif
