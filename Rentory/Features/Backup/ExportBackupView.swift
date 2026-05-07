//
//  ExportBackupView.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import SwiftData
import SwiftUI

struct ExportBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.rrUsesEmbeddedNavigationLayout) private var usesEmbeddedNavigationLayout

    @State private var manifest = RentoryBackupManifest(
        backupVersion: RentoryBackupService.backupVersion,
        appName: "Rentory",
        createdAt: .now,
        appVersion: nil,
        propertyCount: 0,
        roomCount: 0,
        photoCount: 0,
        documentCount: 0,
        timelineEventCount: 0
    )
    @State private var backupURL: URL?
    @State private var userFacingError: UserFacingError?
    @State private var isCreatingBackup = false

    private let backupService = RentoryBackupService()

    var body: some View {
        Group {
            if usesEmbeddedNavigationLayout {
                RRFormContainer(maxWidth: 860) {
                    BackupSummaryView(manifest: manifest)

                    RRPrimaryButton(title: isCreatingBackup ? "Creating backup…" : "Create backup", isDisabled: isCreatingBackup) {
                        createBackup()
                    }
                }
            } else {
                RRMacSheetContainer(maxWidth: 860, minHeight: PlatformLayout.isMac ? 620 : nil) {
                    VStack(alignment: .leading, spacing: 20) {
                        RRSheetHeader(
                            title: "Export backup",
                            subtitle: "Create a backup of your Rentory records, photos and documents. You choose where to save or share it.",
                            systemImage: "externaldrive.fill.badge.icloud"
                        )

                        BackupSummaryView(manifest: manifest)

                        RRPrimaryButton(title: isCreatingBackup ? "Creating backup…" : "Create backup", isDisabled: isCreatingBackup) {
                            createBackup()
                        }
                    }
                }
            }
        }
        .navigationTitle("Export backup")
        .rrInlineNavigationTitle()
        .overlay {
            if isCreatingBackup {
                BackupProgressView(
                    title: "Creating backup",
                    message: "Please wait while your records, photos and documents are prepared."
                )
            }
        }
        .navigationDestination(item: $backupURL) { backupURL in
            BackupReadyView(backupURL: backupURL)
        }
        .alert(item: $userFacingError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .cancel(Text(error.recoveryActionTitle ?? "OK"))
            )
        }
        .task {
            refreshSummary()
        }
    }

    private func refreshSummary() {
        do {
            manifest = try backupService.makeManifest(context: modelContext)
        } catch {
            userFacingError = .backupNotCreated
        }
    }

    private func createBackup() {
        isCreatingBackup = true
        defer { isCreatingBackup = false }

        do {
            backupURL = try backupService.createBackup(context: modelContext)
        } catch {
            userFacingError = .backupNotCreated
        }
    }
}
