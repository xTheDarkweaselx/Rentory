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
    @Query private var propertyPacks: [PropertyPack]
    @Query private var allPhotos: [EvidencePhoto]
    @Query private var allDocuments: [DocumentRecord]

    @State private var isShowingDeleteAllConfirmation = false
    @State private var isShowingClearReportsConfirmation = false
    @State private var alertContent: RRAlertContent?
    @State private var isWorking = false
    @State private var storageSummary = LocalStorageSummary(temporaryReportCount: 0, approximateStorageUsedBytes: 0)

    private let deletionService = RentoryDataDeletionService()
    private let fileStorageService = FileStorageService()

    var body: some View {
        Form {
            Section("Your records") {
                Text("Rentory stores your records on this device by default.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }

            Section("Storage on this device") {
                LabeledContent("Rental records", value: "\(propertyPacks.count)")
                LabeledContent("Photos", value: "\(allPhotos.count)")
                LabeledContent("Documents", value: "\(allDocuments.count)")
                LabeledContent("Temporary reports", value: "\(storageSummary.temporaryReportCount)")
                LabeledContent("Approximate storage used", value: formattedStorageSize(storageSummary.approximateStorageUsedBytes))
            }

            Section("Temporary reports") {
                Text("Reports you create are saved temporarily so you can share them.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)

                RRSecondaryButton(title: "Clear temporary reports") {
                    isShowingClearReportsConfirmation = true
                }
                .accessibilityHint("Removes saved report files from this device.")
            }

            Section("Backups") {
                Text("Backups include your Rentory records, photos and documents. You choose where to save them.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)

                NavigationLink("Export backup") {
                    ExportBackupView()
                }

                NavigationLink("Import backup") {
                    ImportBackupView()
                }
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
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
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
        .rrConfirmationDialog(DialogCopy.clearTemporaryReports, isPresented: $isShowingClearReportsConfirmation) {
            clearTemporaryReports()
        }
        .rrConfirmationDialog(DialogCopy.deleteAllData, isPresented: $isShowingDeleteAllConfirmation) {
            deleteAllData()
        }
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
        .task {
            refreshStorageSummary()
        }
    }

    private func clearTemporaryReports() {
        isWorking = true
        defer { isWorking = false }

        do {
            try deletionService.clearTemporaryReports()
            refreshStorageSummary()
            alertContent = RRAlertContent(
                title: "Temporary reports cleared",
                message: "Earlier reports have been removed from this device."
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
            refreshStorageSummary()
            alertContent = RRAlertContent(
                title: "Data deleted",
                message: "All Rentory data has been deleted from this device."
            )
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeDeleted)
        }
    }

    private func refreshStorageSummary() {
        do {
            try? fileStorageService.cleanupOldTemporaryExports()
            storageSummary = try fileStorageService.storageSummary()
        } catch {
            storageSummary = LocalStorageSummary(temporaryReportCount: 0, approximateStorageUsedBytes: 0)
        }
    }

    private func formattedStorageSize(_ bytes: Int64) -> String {
        guard bytes > 0 else {
            return "Less than 1 KB"
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
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
