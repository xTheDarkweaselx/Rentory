//
//  ImportBackupView.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ImportBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.rrUsesEmbeddedNavigationLayout) private var usesEmbeddedNavigationLayout

    @State private var importMode: BackupImportMode = .addToExisting
    @State private var loadedBackup: LoadedRentoryBackup?
    @State private var isShowingFileImporter = false
    @State private var isShowingReplaceConfirmation = false
    @State private var userFacingError: UserFacingError?
    @State private var alertContent: RRAlertContent?
    @State private var isImporting = false

    private let backupService = RentoryBackupService()

    var body: some View {
        Group {
            if usesEmbeddedNavigationLayout {
                RRFormContainer(maxWidth: 860) {
                    importContent
                }
            } else {
                RRMacSheetContainer(maxWidth: 860, minHeight: PlatformLayout.isMac ? 640 : nil) {
                    VStack(alignment: .leading, spacing: 20) {
                        RRSheetHeader(
                            title: "Import backup",
                            subtitle: "Import a Rentory backup from another device or a file you saved earlier.",
                            systemImage: "arrow.down.doc.fill"
                        )

                        importContent
                    }
                }
            }
        }
        .navigationTitle("Import backup")
        .rrInlineNavigationTitle()
        .overlay {
            if isImporting {
                BackupProgressView(
                    title: "Importing backup",
                    message: "Please wait while your records are added to this device."
                )
            }
        }
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [RentoryBackupService.backupContentType, .folder]
        ) { result in
            handleImportedFile(result)
        }
        .rrConfirmationDialog(
            RRDialogContent(
                title: "Replace all Rentory data?",
                message: "This will delete the Rentory records currently on this device before importing the backup. This cannot be undone.",
                confirmTitle: "Replace and import",
                cancelTitle: "Cancel",
                confirmRole: .destructive
            ),
            isPresented: $isShowingReplaceConfirmation
        ) {
            importBackup()
        }
        .alert(item: $userFacingError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .cancel(Text(error.recoveryActionTitle ?? "OK"))
            )
        }
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
    }

    private var importContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            RRGlassPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Before you import")
                        .font(RRTypography.headline)
                        .foregroundStyle(RRColours.primary)

                    Text("Importing adds records from the backup to this device. Your existing records will not be deleted unless you choose to replace them.")
                        .font(RRTypography.body)
                        .foregroundStyle(RRColours.mutedText)
                }
            }

            RRGlassPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Import option")
                        .font(RRTypography.headline)
                        .foregroundStyle(RRColours.primary)

                    Picker("Import option", selection: $importMode) {
                        ForEach(BackupImportMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }

            RRSecondaryButton(title: "Choose backup file") {
                isShowingFileImporter = true
            }

            if let loadedBackup {
                BackupSummaryView(manifest: loadedBackup.manifest, buttonTitle: "Import backup") {
                    if importMode == .replaceAll {
                        isShowingReplaceConfirmation = true
                    } else {
                        importBackup()
                    }
                }
            }
        }
    }

    private func handleImportedFile(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            loadedBackup = try backupService.loadBackup(from: url)
        } catch let error as RentoryBackupError {
            loadedBackup = nil
            userFacingError = mapBackupError(error)
        } catch {
            loadedBackup = nil
            userFacingError = .backupNotImported
        }
    }

    private func importBackup() {
        guard let loadedBackup else {
            return
        }

        isImporting = true
        defer { isImporting = false }

        do {
            try backupService.importBackup(loadedBackup, mode: importMode, context: modelContext)
            alertContent = RRAlertContent(
                title: "Backup imported",
                message: "Your Rentory records have been added to this device."
            )
            self.loadedBackup = nil
        } catch let error as RentoryBackupError {
            userFacingError = mapBackupError(error)
        } catch {
            userFacingError = .backupNotImported
        }
    }

    private func mapBackupError(_ error: RentoryBackupError) -> UserFacingError {
        switch error {
        case .backupNotCreated:
            return .backupNotCreated
        case .backupNotOpened, .backupNotImported:
            return .backupNotImported
        case .backupNotSupported:
            return .backupNotSupported
        case .backupIncomplete:
            return .backupIncomplete
        case .backupValidationFailed:
            return .backupValidationFailed
        }
    }
}
