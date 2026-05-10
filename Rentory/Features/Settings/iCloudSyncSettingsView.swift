//
//  iCloudSyncSettingsView.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import SwiftUI
import SwiftData

struct ICloudSyncSettingsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.rrUsesEmbeddedNavigationLayout) private var usesEmbeddedNavigationLayout
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var iCloudSyncService: ICloudSyncService

    @State private var isShowingExportBackup = false
    @State private var isShowingImportBackup = false

    var body: some View {
        Group {
            if PlatformLayout.isPhone && horizontalSizeClass != .regular {
                compactView
            } else if usesEmbeddedNavigationLayout {
                RRFormContainer(maxWidth: 920) {
                    RRResponsiveFormGrid(items: detailGridItems)
                }
            } else {
                RRMacSheetContainer(maxWidth: 920, minHeight: PlatformLayout.isMac ? 620 : nil) {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "iCloud Sync",
                            subtitle: "Check whether iCloud is available for Rentory on this device.",
                            systemImage: "icloud"
                        )

                        RRResponsiveFormGrid(items: detailGridItems)
                    }
                }
            }
        }
        .navigationTitle("iCloud Sync")
        .rrInlineNavigationTitle()
        .sheet(isPresented: $isShowingExportBackup) {
            ExportBackupView()
                .rrUsesEmbeddedNavigationLayout(false)
        }
        .sheet(isPresented: $isShowingImportBackup) {
            ImportBackupView()
                .rrUsesEmbeddedNavigationLayout(false)
        }
        .alert(item: $iCloudSyncService.alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
        .task {
            await iCloudSyncService.refreshStatus()
        }
    }

    private var detailGridItems: [RRResponsiveFormGridItem] {
        [
            RRResponsiveFormGridItem {
                statusPanel
            },
            RRResponsiveFormGridItem {
                backupsPanel
            },
            RRResponsiveFormGridItem(span: .fullWidth) {
                guidancePanel
            },
        ]
    }

    private var compactView: some View {
        Form {
            Section("iCloud Sync") {
                LabeledContent("iCloud status", value: iCloudSyncService.syncStatus.title)
                Toggle("Sync Rentory with iCloud", isOn: toggleBinding)
                    .disabled(iCloudSyncService.syncStatus != .available || iCloudSyncService.isSyncing)

                RRSecondaryButton(title: iCloudSyncService.isSyncing ? "Syncing…" : "Sync now", isDisabled: !iCloudSyncService.isSyncEnabled || iCloudSyncService.isSyncing) {
                    Task {
                        await iCloudSyncService.syncNow(context: modelContext)
                    }
                }
            }

            Section {
                Text(statusMessage)
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }

            Section("Backups") {
                backupActionButtons
            }
        }
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
    }

    private var statusPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Keep Rentory in sync")
                    .font(RRTypography.headline)

                Text("Use iCloud to keep your Rentory records available across your devices signed in with the same Apple Account.")
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)

                LabeledContent("iCloud status", value: iCloudSyncService.syncStatus.title)
                Toggle("Sync Rentory with iCloud", isOn: toggleBinding)
                    .disabled(iCloudSyncService.syncStatus != .available || iCloudSyncService.isSyncing)

                LabeledContent("Last synced", value: lastSyncedText)

                RRSecondaryButton(title: iCloudSyncService.isSyncing ? "Syncing…" : "Sync now", isDisabled: !iCloudSyncService.isSyncEnabled || iCloudSyncService.isSyncing) {
                    Task {
                        await iCloudSyncService.syncNow(context: modelContext)
                    }
                }
            }
        }
    }

    private var backupsPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Backups")
                    .font(RRTypography.headline)

                Text("Export or import a backup whenever you want an extra copy of your Rentory records.")
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)

                backupActionButtons
            }
        }
    }

    private var guidancePanel: some View {
        RRGlassPanel {
            Text(statusMessage)
                .font(RRTypography.body)
                .foregroundStyle(RRColours.mutedText)
        }
    }

    @ViewBuilder
    private var backupActionButtons: some View {
        if usesEmbeddedNavigationLayout {
            RRSecondaryButton(title: "Export a backup") {
                isShowingExportBackup = true
            }

            RRSecondaryButton(title: "Import a backup") {
                isShowingImportBackup = true
            }
        } else {
            NavigationLink("Export a backup") {
                ExportBackupView()
            }

            NavigationLink("Import a backup") {
                ImportBackupView()
            }
        }
    }

    private var statusMessage: String {
        switch iCloudSyncService.syncStatus {
        case .available:
            return iCloudSyncService.isSyncEnabled
                ? "Rentory is set to keep this device in step with your private iCloud account."
                : "iCloud is available on this device. Turn on sync when you want Rentory to keep your records in step across your devices."
        case .unavailable:
            return "Check that you are signed in to iCloud and that iCloud Drive is enabled."
        case .checking:
            return "Checking your iCloud status."
        case .unknown:
            return "iCloud status could not be confirmed just now."
        }
    }

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { iCloudSyncService.isSyncEnabled },
            set: { newValue in
                Task {
                    await iCloudSyncService.setSyncEnabled(newValue, context: modelContext)
                }
            }
        )
    }

    private var lastSyncedText: String {
        guard let lastSyncDate = iCloudSyncService.lastSyncDate else {
            return iCloudSyncService.isSyncEnabled ? "Waiting for first sync" : "Not turned on"
        }

        return lastSyncDate.formatted(date: .abbreviated, time: .shortened)
    }
}
