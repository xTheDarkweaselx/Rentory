//
//  BackupsSettingsView.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import SwiftUI

struct BackupsSettingsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.rrUsesEmbeddedNavigationLayout) private var usesEmbeddedNavigationLayout
    @State private var isShowingExportBackup = false
    @State private var isShowingImportBackup = false

    var body: some View {
        Group {
            if PlatformLayout.isPhone && horizontalSizeClass != .regular {
                compactView
            } else if usesEmbeddedNavigationLayout {
                RRFormContainer(maxWidth: 920) {
                    RRResponsiveFormGrid(items: [
                        RRResponsiveFormGridItem {
                            overviewPanel
                        },
                        RRResponsiveFormGridItem {
                            actionsPanel
                        },
                    ])
                }
            } else {
                RRMacSheetContainer(maxWidth: 920, minHeight: PlatformLayout.isMac ? 620 : nil) {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Backups",
                            subtitle: "Export or import a Rentory backup when you want to keep a copy.",
                            systemImage: "externaldrive"
                        )

                        RRResponsiveFormGrid(items: [
                            RRResponsiveFormGridItem {
                                overviewPanel
                            },
                            RRResponsiveFormGridItem {
                                actionsPanel
                            },
                        ])
                    }
                }
            }
        }
        .navigationTitle("Backups")
        .rrInlineNavigationTitle()
        .sheet(isPresented: $isShowingExportBackup) {
            ExportBackupView()
                .rrUsesEmbeddedNavigationLayout(false)
        }
        .sheet(isPresented: $isShowingImportBackup) {
            ImportBackupView()
                .rrUsesEmbeddedNavigationLayout(false)
        }
    }

    private var compactView: some View {
        Form {
            Section {
                Text("Backups include your Rentory records, photos and documents. You choose where to save them.")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }

            Section {
                backupActions
            }
        }
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
    }

    private var overviewPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Keep a backup")
                    .font(RRTypography.headline)

                Text("Backups include your Rentory records, photos and documents. You choose where to save them.")
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)
            }
        }
    }

    private var actionsPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Backup actions")
                    .font(RRTypography.headline)

                backupActions
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
}
