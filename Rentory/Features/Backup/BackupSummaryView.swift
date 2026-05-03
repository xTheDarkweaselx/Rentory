//
//  BackupSummaryView.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import SwiftUI

struct BackupSummaryView: View {
    let manifest: RentoryBackupManifest
    let buttonTitle: String?
    let buttonAction: (() -> Void)?

    init(manifest: RentoryBackupManifest, buttonTitle: String? = nil, buttonAction: (() -> Void)? = nil) {
        self.manifest = manifest
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }

    var body: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                RRSectionHeader(
                    title: "Backup summary",
                    subtitle: "A quick look at what is included."
                )

                LabeledContent("Date created", value: formattedDate(manifest.createdAt))
                LabeledContent("Rental records", value: "\(manifest.propertyCount)")
                LabeledContent("Rooms", value: "\(manifest.roomCount)")
                LabeledContent("Photos", value: "\(manifest.photoCount)")
                LabeledContent("Documents", value: "\(manifest.documentCount)")
                LabeledContent("Timeline events", value: "\(manifest.timelineEventCount)")
                LabeledContent("Backup version", value: "\(manifest.backupVersion)")

                if let buttonTitle, let buttonAction {
                    RRPrimaryButton(title: buttonTitle, action: buttonAction)
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
