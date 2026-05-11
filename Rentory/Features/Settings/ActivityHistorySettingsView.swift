//
//  ActivityHistorySettingsView.swift
//  Rentory
//
//  Created by OpenAI on 11/05/2026.
//

import SwiftUI

struct ActivityHistorySettingsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.rrUsesEmbeddedNavigationLayout) private var usesEmbeddedNavigationLayout

    @State private var entries = RentoryActivityLog.entries
    @State private var isShowingClearConfirmation = false

    var body: some View {
        Group {
            if PlatformLayout.isPhone && horizontalSizeClass != .regular {
                compactView
            } else if usesEmbeddedNavigationLayout {
                RRFormContainer(maxWidth: 880) {
                    contentStack
                }
            } else {
                RRMacSheetContainer(maxWidth: 880, minHeight: PlatformLayout.isMac ? 560 : nil) {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Activity history",
                            subtitle: "Recent backups, imports, reports, sync attempts and record changes on this device.",
                            systemImage: "clock.arrow.circlepath"
                        )

                        contentStack
                    }
                }
            }
        }
        .navigationTitle("Activity history")
        .rrInlineNavigationTitle()
        .onAppear(perform: refreshEntries)
        .rrConfirmationDialog(
            RRDialogContent(
                title: "Clear activity history?",
                message: "This only clears the local history list. It does not delete records, backups, reports, photos or documents.",
                confirmTitle: "Clear history",
                cancelTitle: "Cancel",
                confirmRole: .destructive
            ),
            isPresented: $isShowingClearConfirmation
        ) {
            RentoryActivityLog.clear()
            refreshEntries()
        }
    }

    private var compactView: some View {
        Form {
            Section("Activity history") {
                if entries.isEmpty {
                    Text("No activity has been recorded yet.")
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                } else {
                    ForEach(entries) { entry in
                        activityRow(entry)
                    }
                }
            }

            if !entries.isEmpty {
                Section {
                    Button("Clear history", role: .destructive) {
                        isShowingClearConfirmation = true
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
    }

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
            RRGlassPanel {
                VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                    Text("Recent activity")
                        .font(RRTypography.title)
                        .foregroundStyle(RRColours.primary)

                    Text("This is stored locally on this device to make troubleshooting easier.")
                        .font(RRTypography.body)
                        .foregroundStyle(RRColours.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if entries.isEmpty {
                RREmptyStateView(
                    symbolName: "clock.arrow.circlepath",
                    title: "No activity yet",
                    message: "Backups, imports, reports, sync attempts and record changes will appear here."
                )
            } else {
                LazyVStack(spacing: RRTheme.cardSpacing) {
                    ForEach(entries) { entry in
                        RRGlassPanel {
                            activityRow(entry)
                        }
                    }
                }

                RRDestructiveButton(title: "Clear history") {
                    isShowingClearConfirmation = true
                }
                .frame(maxWidth: PlatformLayout.isPhone ? .infinity : 220)
            }
        }
    }

    private func activityRow(_ entry: RentoryActivityEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RRIconBadge(systemName: entry.kind.systemImage, tint: RRColours.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)

                Text(entry.message)
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(entry.kind.title) • \(entry.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(RRTypography.caption)
                    .foregroundStyle(RRColours.mutedText)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private func refreshEntries() {
        entries = RentoryActivityLog.entries
    }
}
