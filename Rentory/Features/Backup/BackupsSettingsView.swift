//
//  BackupsSettingsView.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import SwiftUI

struct BackupsSettingsView: View {
    var body: some View {
        Form {
            Section {
                RRGlassPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Backups")
                            .font(RRTypography.headline)
                            .foregroundStyle(RRColours.primary)

                        Text("Backups include your Rentory records, photos and documents. You choose where to save them.")
                            .font(RRTypography.body)
                            .foregroundStyle(RRColours.mutedText)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                NavigationLink("Export backup") {
                    ExportBackupView()
                }

                NavigationLink("Import backup") {
                    ImportBackupView()
                }
            }
        }
        .navigationTitle("Backups")
        .rrInlineNavigationTitle()
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
    }
}
