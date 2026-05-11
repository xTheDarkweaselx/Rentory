//
//  ArchivedRecordsSettingsView.swift
//  Rentory
//
//  Created by OpenAI on 11/05/2026.
//

import SwiftData
import SwiftUI

struct ArchivedRecordsSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: [SortDescriptor(\PropertyPack.updatedAt, order: .reverse)]) private var propertyPacks: [PropertyPack]

    @State private var recordToDelete: PropertyPack?
    @State private var alertContent: RRAlertContent?
    @State private var isWorking = false

    private let deletionService = RentoryDataDeletionService()

    private var archivedRecords: [PropertyPack] {
        propertyPacks.filter(\.isArchived)
    }

    var body: some View {
        Group {
            if PlatformLayout.isPhone && horizontalSizeClass != .regular {
                compactView
            } else {
                RRFormContainer(maxWidth: 920) {
                    contentStack
                }
            }
        }
        .navigationTitle("Archived records")
        .rrInlineNavigationTitle()
        .overlay {
            if isWorking {
                ZStack {
                    Color.black.opacity(0.12)
                        .ignoresSafeArea()

                    RRLoadingView(
                        title: "Updating records",
                        message: "Please wait while Rentory updates your archived records."
                    )
                    .padding(24)
                }
            }
        }
        .alert("Delete this archived record?", isPresented: deleteConfirmationBinding) {
            Button("Cancel", role: .cancel) {
                recordToDelete = nil
            }

            Button("Delete", role: .destructive) {
                deleteSelectedRecord()
            }
        } message: {
            Text("This permanently removes the record, including its photos and documents, from this device. This cannot be undone.")
        }
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
    }

    private var compactView: some View {
        Form {
            Section("Archived records") {
                if archivedRecords.isEmpty {
                    Text("You do not have any archived records.")
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                } else {
                    ForEach(archivedRecords) { record in
                        archivedRecordRow(record)
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
                    Text("Archived records")
                        .font(RRTypography.title)
                        .foregroundStyle(RRColours.primary)

                    Text("These records are hidden from your main list. Restore one to use it again, or delete it permanently if you no longer need it.")
                        .font(RRTypography.body)
                        .foregroundStyle(RRColours.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if archivedRecords.isEmpty {
                RREmptyStateView(
                    symbolName: "archivebox",
                    title: "No archived records",
                    message: "Records you archive will appear here."
                )
            } else {
                LazyVStack(spacing: RRTheme.cardSpacing) {
                    ForEach(archivedRecords) { record in
                        archivedRecordCard(record)
                    }
                }
            }
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { recordToDelete != nil },
            set: { isPresented in
                if !isPresented {
                    recordToDelete = nil
                }
            }
        )
    }

    private func archivedRecordCard(_ record: PropertyPack) -> some View {
        RRGlassPanel {
            archivedRecordContent(record)
        }
    }

    private func archivedRecordRow(_ record: PropertyPack) -> some View {
        VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
            archivedRecordContent(record)
        }
        .padding(.vertical, 6)
    }

    private func archivedRecordContent(_ record: PropertyPack) -> some View {
        VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
            HStack(alignment: .top, spacing: 12) {
                RRIconBadge(systemName: record.recordIconName, tint: RRColours.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.nickname)
                        .font(RRTypography.headline)
                        .foregroundStyle(RRColours.primary)

                    Text(record.searchableAddressSummary)
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Archived \(record.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(RRTypography.caption)
                        .foregroundStyle(RRColours.mutedText)
                }

                Spacer(minLength: 0)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: RRTheme.controlSpacing) {
                    restoreButton(for: record)
                    deleteButton(for: record)
                }

                VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                    restoreButton(for: record)
                    deleteButton(for: record)
                }
            }
        }
    }

    private func restoreButton(for record: PropertyPack) -> some View {
        RRSecondaryButton(title: "Restore") {
            restore(record)
        }
        .frame(maxWidth: PlatformLayout.isPhone ? .infinity : 180)
    }

    private func deleteButton(for record: PropertyPack) -> some View {
        RRDestructiveButton(title: "Delete permanently") {
            recordToDelete = record
        }
        .frame(maxWidth: PlatformLayout.isPhone ? .infinity : 220)
    }

    private func restore(_ record: PropertyPack) {
        isWorking = true
        defer { isWorking = false }

        record.isArchived = false
        record.updatedAt = .now

        do {
            try modelContext.save()
            alertContent = RRAlertContent(
                title: "Record restored",
                message: "“\(record.nickname)” is back in your active records."
            )
            RentoryActivityLog.record(
                kind: .restore,
                title: "Record restored",
                message: "“\(record.nickname)” was restored to active records."
            )
        } catch {
            alertContent = RRAlertContent(
                title: "Record could not be restored",
                message: "Rentory could not restore this record just now. Please try again."
            )
        }
    }

    private func deleteSelectedRecord() {
        guard let recordToDelete else { return }
        isWorking = true
        defer {
            isWorking = false
            self.recordToDelete = nil
        }

        do {
            let recordName = recordToDelete.nickname
            try deletionService.deletePropertyPack(recordToDelete, context: modelContext)
            alertContent = RRAlertContent(
                title: "Archived record deleted",
                message: "The archived record has been permanently removed from this device."
            )
            RentoryActivityLog.record(
                kind: .deletion,
                title: "Archived record deleted",
                message: "“\(recordName)” was permanently removed from this device."
            )
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeDeleted)
        }
    }
}

private extension PropertyPack {
    var searchableAddressSummary: String {
        let addressParts = [addressLine1, addressLine2, townCity, postcode]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !addressParts.isEmpty {
            return addressParts.joined(separator: ", ")
        }

        return recordType.rawValue
    }
}
