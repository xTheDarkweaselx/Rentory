//
//  PrivacyAndDataSettingsView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI

struct PrivacyAndDataSettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isShowingDeleteAllConfirmation = false
    @State private var alertContent: RRAlertContent?
    @State private var isWorking = false

    private let deletionService = RentoryDataDeletionService()

    var body: some View {
        Form {
            Section("Your records") {
                Text("Rentory stores your records on this device by default.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }

            Section("Temporary reports") {
                Text("Reports you create are saved temporarily so you can share them.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)

                RRSecondaryButton(title: "Clear temporary reports") {
                    clearTemporaryReports()
                }
                .accessibilityHint("Removes saved report files from this device.")
            }

            Section("Delete all data") {
                Text("Remove all rental records, photos, documents and temporary reports from this device.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)

                RRDestructiveButton(title: "Delete all Rentory data") {
                    isShowingDeleteAllConfirmation = true
                }
                .accessibilityHint("Removes all records, photos, documents and temporary reports from this device.")
            }
        }
        .navigationTitle("Privacy & Data")
        .rrInlineNavigationTitle()
        .overlay {
            if isWorking {
                ZStack {
                    Color.black.opacity(0.12)
                        .ignoresSafeArea()

                    RRLoadingView(
                        title: "Removing data",
                        message: "Please wait while your data is removed from this device."
                    )
                    .padding(24)
                }
            }
        }
        .alert("Delete all Rentory data?", isPresented: $isShowingDeleteAllConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete all data", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This removes all rental records, photos, documents and temporary reports from this device. This cannot be undone.")
        }
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
    }

    private func clearTemporaryReports() {
        isWorking = true
        defer { isWorking = false }

        do {
            try deletionService.clearTemporaryReports()
            alertContent = RRAlertContent(
                title: "Privacy & Data",
                message: "Temporary reports have been cleared from this device."
            )
        } catch {
            alertContent = RRAlertContent(error: .temporaryReportsCouldNotBeCleared)
        }
    }

    private func deleteAllData() {
        isWorking = true
        defer { isWorking = false }

        do {
            try deletionService.deleteAllData(context: modelContext)
            alertContent = RRAlertContent(
                title: "Privacy & Data",
                message: "All Rentory data has been deleted from this device."
            )
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeDeleted)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyAndDataSettingsView()
    }
    .modelContainer(
        for: [
            PropertyPack.self,
            RoomRecord.self,
            ChecklistItemRecord.self,
            EvidencePhoto.self,
            DocumentRecord.self,
            TimelineEvent.self,
        ],
        inMemory: true
    )
}
