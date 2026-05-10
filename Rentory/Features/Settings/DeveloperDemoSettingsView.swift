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
    @State private var loadProgress = DemoDataFactory.LoadProgress(
        completedRecords: 0,
        totalRecords: 1,
        stageDescription: "Getting ready."
    )
    @State private var loadTask: Task<Void, Never>?
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
                RRProgressDialog(
                    title: "Preparing demo data",
                    message: loadProgress.stageDescription,
                    progress: loadProgress.fractionCompleted,
                    cancelTitle: "Cancel"
                ) {
                    loadTask?.cancel()
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
            loadTask = Task {
                await loadDemoRecord()
            }
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
            Task {
                await clearDemoData()
            }
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

    private func loadDemoRecord() async {
        guard !isWorking else { return }
        isWorking = true
        let totalRecords = loadsFullSampleSet ? 8 : 1
        loadProgress = DemoDataFactory.LoadProgress(
            completedRecords: 0,
            totalRecords: totalRecords,
            stageDescription: "Getting the sample data ready."
        )
        await Task.yield()
        defer {
            isWorking = false
            loadTask = nil
        }

        do {
            let style: DemoDataFactory.SampleDataStyle = loadsFullSampleSet ? .fullSampleSet : .singleRecord
            let loadedRecords = try await demoDataFactory.loadSampleData(context: modelContext, style: style) { progress in
                Task { @MainActor in
                    loadProgress = progress
                }
            }
            alertContent = RRAlertContent(
                title: loadsFullSampleSet ? "Sample set ready" : "Sample record ready",
                message: loadsFullSampleSet
                    ? "\(loadedRecords.count) fake sample records are ready for testing and screenshots."
                    : "Fake sample data is ready for testing and screenshots."
            )
        } catch is CancellationError {
            alertContent = RRAlertContent(
                title: "Sample data cancelled",
                message: "Rentory removed the sample data that had already been created."
            )
        } catch {
            alertContent = RRAlertContent(
                title: "Sample data could not be loaded",
                message: "Rentory could not load the sample data just now. Anything partly created has been removed."
            )
        }
    }

    private func clearDemoData() async {
        guard !isWorking else { return }
        isWorking = true
        await Task.yield()
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
