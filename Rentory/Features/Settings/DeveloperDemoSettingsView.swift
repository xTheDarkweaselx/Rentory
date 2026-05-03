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
    @Query private var propertyPacks: [PropertyPack]

    @State private var isShowingLoadConfirmation = false
    @State private var isShowingClearConfirmation = false
    @State private var alertContent: RRAlertContent?
    @State private var isWorking = false

    private let demoDataFactory = DemoDataFactory()

    private var hasDemoRecord: Bool {
        propertyPacks.contains(where: DemoModeSettings.matchesDemoRecord)
    }

    var body: some View {
        Form {
            Section("Demo data") {
                Text("Use fake data for testing and screenshots.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)

                Text(hasDemoRecord ? "A fake demo record is ready to use." : "No fake demo record has been loaded yet.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }

            Section {
                RRPrimaryButton(title: "Load demo record", isDisabled: isWorking) {
                    isShowingLoadConfirmation = true
                }

                RRDestructiveButton(title: "Clear demo data", isDisabled: isWorking || !hasDemoRecord) {
                    isShowingClearConfirmation = true
                }
            }
        }
        .navigationTitle("Demo data")
        .rrInlineNavigationTitle()
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
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
                title: "Load demo record?",
                message: "This adds a fake rental record for testing and screenshots.",
                confirmTitle: "Load demo record",
                cancelTitle: "Cancel"
            ),
            isPresented: $isShowingLoadConfirmation
        ) {
            loadDemoRecord()
        }
        .rrConfirmationDialog(
            RRDialogContent(
                title: "Clear demo data?",
                message: "This removes the fake demo record and its sample files.",
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

    private func loadDemoRecord() {
        isWorking = true
        defer { isWorking = false }

        do {
            _ = try demoDataFactory.loadDemoRecord(context: modelContext)
            alertContent = RRAlertContent(
                title: "Demo record ready",
                message: "Fake sample data is ready for testing and screenshots."
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
                message: "The fake demo record and its sample files have been removed."
            )
        } catch {
            alertContent = RRAlertContent(error: .somethingWentWrong)
        }
    }
}
#endif
