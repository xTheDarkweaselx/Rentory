//
//  iCloudSyncSettingsView.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import SwiftUI

struct ICloudSyncSettingsView: View {
    @State private var syncStatus: SyncStatus = .checking
    @State private var alertContent: RRAlertContent?

    private let statusService = ICloudSyncStatusService()

    var body: some View {
        Form {
            Section {
                RRGlassPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Keep Rentory in sync")
                            .font(RRTypography.headline)
                            .foregroundStyle(RRColours.primary)

                        Text("Use iCloud to keep your Rentory records available across your devices signed in with the same Apple ID.")
                            .font(RRTypography.body)
                            .foregroundStyle(RRColours.mutedText)

                        Text("Rentory does not use its own server. If you turn this on, your records are stored in your private iCloud account.")
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.mutedText)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("iCloud Sync") {
                Toggle("Sync with iCloud", isOn: .constant(false))
                    .disabled(true)

                LabeledContent("iCloud status", value: syncStatus.title)

                RRSecondaryButton(title: syncStatus == .checking ? "Checking iCloud status…" : "Check iCloud status", isDisabled: syncStatus == .checking) {
                    Task {
                        await refreshStatus()
                    }
                }
            }

            Section {
                Text(statusMessage)
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }

            Section("Backups") {
                NavigationLink("Export a backup") {
                    ExportBackupView()
                }

                NavigationLink("Import a backup") {
                    ImportBackupView()
                }
            }
        }
        .navigationTitle("iCloud Sync")
        .rrInlineNavigationTitle()
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
        .task {
            await refreshStatus()
        }
    }

    private var statusMessage: String {
        switch syncStatus {
        case .available:
            return "Your records stay on this device. Full iCloud sync setup will be added later. For now, you can export or import a backup whenever you need one."
        case .unavailable:
            return "Check that you are signed in to iCloud and that iCloud Drive is enabled."
        case .checking:
            return "Checking your iCloud status."
        case .unknown:
            return "iCloud status could not be confirmed just now. Your records stay on this device."
        }
    }

    private func refreshStatus() async {
        syncStatus = .checking
        let checkedStatus = await statusService.checkStatus()
        syncStatus = checkedStatus

        if checkedStatus == .unavailable {
            alertContent = RRAlertContent(
                title: "iCloud is not available",
                message: "Check that you are signed in to iCloud and that iCloud Drive is enabled."
            )
        }
    }
}
