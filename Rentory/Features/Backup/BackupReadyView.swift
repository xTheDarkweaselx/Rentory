//
//  BackupReadyView.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import SwiftUI

struct BackupReadyView: View {
    let backupURL: URL

    var body: some View {
        ZStack {
            RRBackgroundView()

            VStack(spacing: 24) {
                Spacer()

                RRSuccessView(
                    title: "Backup ready",
                    message: "Your Rentory backup has been created on this device. Choose where to save it.",
                    systemImage: "externaldrive.badge.checkmark"
                ) {
                    ShareLink(item: backupURL) {
                        Label("Save or share backup", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                }

                Spacer()
            }
            .padding(RRTheme.screenPadding)
        }
        .navigationTitle("Backup ready")
        .rrInlineNavigationTitle()
    }
}
