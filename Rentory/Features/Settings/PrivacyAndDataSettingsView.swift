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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.rrUsesEmbeddedNavigationLayout) private var usesEmbeddedNavigationLayout
    @Query private var propertyPacks: [PropertyPack]
    @Query private var allPhotos: [EvidencePhoto]
    @Query private var allDocuments: [DocumentRecord]

    @State private var isShowingDeleteAllConfirmation = false
    @State private var isShowingClearReportsConfirmation = false
    @State private var isShowingExportBackup = false
    @State private var isShowingImportBackup = false
    @State private var alertContent: RRAlertContent?
    @State private var isWorking = false
    @State private var storageSummary = LocalStorageSummary(temporaryReportCount: 0, approximateStorageUsedBytes: 0)

    private let deletionService = RentoryDataDeletionService()
    private let fileStorageService = FileStorageService()

    var body: some View {
        Group {
            if PlatformLayout.isPhone && horizontalSizeClass != .regular {
                compactView
            } else if usesEmbeddedNavigationLayout {
                RRFormContainer(maxWidth: 960) {
                    RRResponsiveFormGrid(items: detailGridItems)
                }
            } else {
                RRMacSheetContainer(maxWidth: 960, minHeight: PlatformLayout.isMac ? 640 : nil) {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Privacy & Data",
                            subtitle: "Manage storage, backups and what stays on this device.",
                            systemImage: "hand.raised.fill"
                        )

                        RRResponsiveFormGrid(items: detailGridItems)
                    }
                }
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
        .sheet(isPresented: $isShowingExportBackup) {
            ExportBackupView()
                .rrUsesEmbeddedNavigationLayout(false)
        }
        .sheet(isPresented: $isShowingImportBackup) {
            ImportBackupView()
                .rrUsesEmbeddedNavigationLayout(false)
        }
        .task {
            refreshStorageSummary()
        }
    }

    private var detailGridItems: [RRResponsiveFormGridItem] {
        [
            RRResponsiveFormGridItem {
                summaryPanel
            },
            RRResponsiveFormGridItem {
                storagePanel
            },
            RRResponsiveFormGridItem {
                backupsPanel
            },
            RRResponsiveFormGridItem(span: .fullWidth) {
                dangerPanel
            },
        ]
    }

    private var compactView: some View {
        Form {
            Section("Your records") {
                Text("Rentory stores your records on this device by default.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }

            Section("Storage on this device") {
                storageRows
            }

            Section("Temporary reports") {
                Text("Reports you create are saved temporarily so you can share them.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)

                RRSecondaryButton(title: "Clear temporary reports") {
                    isShowingClearReportsConfirmation = true
                }
            }

            Section("Backups") {
                backupActions
            }

            Section("Delete all data") {
                RRDestructiveButton(title: "Delete all Rentory data") {
                    isShowingDeleteAllConfirmation = true
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
    }

    private var summaryPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Your records")
                    .font(RRTypography.headline)

                Text("Rentory stores your records on this device by default.")
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)

                Text("Export a backup whenever you want to keep a copy somewhere you choose.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }
        }
    }

    private var storagePanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Storage on this device")
                    .font(RRTypography.headline)

                storageRows
            }
        }
    }

    private var storageRows: some View {
        Group {
            LabeledContent("Rental records", value: "\(propertyPacks.count)")
            LabeledContent("Photos", value: "\(allPhotos.count)")
            LabeledContent("Documents", value: "\(allDocuments.count)")
            LabeledContent("Temporary reports", value: "\(storageSummary.temporaryReportCount)")
            LabeledContent("Approximate storage used", value: formattedStorageSize(storageSummary.approximateStorageUsedBytes))
        }
        .font(RRTypography.body)
    }

    private var backupsPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Backups")
                    .font(RRTypography.headline)

                Text("Backups include your Rentory records, photos and documents. You choose where to save them.")
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)

                backupActions
            }
        }
    }

    private var dangerPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Temporary reports")
                    .font(RRTypography.headline)

                Text("Reports you create are saved temporarily so you can share them.")
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)

                RRSecondaryButton(title: "Clear temporary reports") {
                    isShowingClearReportsConfirmation = true
                }

                Divider()

                Text("Delete all data")
                    .font(RRTypography.headline)

                Text("Remove all rental records, photos, documents and temporary reports from this device.")
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)

                RRDestructiveButton(title: "Delete all Rentory data") {
                    isShowingDeleteAllConfirmation = true
                }
            }
        }
    }

    @ViewBuilder
    private var backupActions: some View {
        if usesEmbeddedNavigationLayout {
            RRSecondaryButton(title: "Export backup") {
                isShowingExportBackup = true
            }

            RRSecondaryButton(title: "Import backup") {
                isShowingImportBackup = true
            }
        } else {
            NavigationLink("Export backup") {
                ExportBackupView()
            }

            NavigationLink("Import backup") {
                ImportBackupView()
            }
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
