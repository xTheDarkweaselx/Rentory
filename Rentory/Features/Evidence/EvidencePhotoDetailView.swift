//
//  EvidencePhotoDetailView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI

struct EvidencePhotoDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let photo: EvidencePhoto

    private let photoStorageService = PhotoStorageService()

    @State private var caption: String
    @State private var evidencePhase: EvidencePhase
    @State private var capturedAt: Date
    @State private var dateIsConfirmed: Bool
    @State private var includeInReport: Bool
    @State private var loadedImage: UIImage?
    @State private var alertContent: RRAlertContent?
    @State private var isShowingDeleteConfirmation = false

    init(photo: EvidencePhoto) {
        self.photo = photo
        _caption = State(initialValue: photo.caption ?? "")
        _evidencePhase = State(initialValue: photo.evidencePhase)
        _capturedAt = State(initialValue: photo.capturedAt)
        _dateIsConfirmed = State(initialValue: photo.captureDateIsConfirmed)
        _includeInReport = State(initialValue: photo.includeInExport)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                RRSheetHeader(
                    title: "Photo",
                    subtitle: "Keep this photo in the right place and choose whether to include it in your report.",
                    systemImage: "photo"
                )

                RRCard {
                    Group {
                        if let loadedImage {
                            Image(rrImage: loadedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(RRColours.mutedText)

                                Text("Photo unavailable")
                                    .font(RRTypography.body)
                                    .foregroundStyle(RRColours.mutedText)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                        }
                    }
                }

                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Caption")
                            .font(RRTypography.headline)
                            .foregroundStyle(RRColours.primary)

                        TextField("Add a short note", text: $caption, axis: .vertical)
                            .lineLimit(2...4)

                        VStack(alignment: .leading, spacing: 8) {
                            DatePicker(
                                "Date taken",
                                selection: $capturedAt,
                                in: ...Date.now,
                                displayedComponents: .date
                            )
                            .onChange(of: capturedAt) { _, _ in
                                // The user has explicitly set the date, so it
                                // becomes an affirmed capture date.
                                dateIsConfirmed = true
                            }

                            if dateIsConfirmed {
                                Text("Shown on your report as when this photo was taken. Adjust it if it looks wrong.")
                                    .font(RRTypography.caption)
                                    .foregroundStyle(RRColours.mutedText)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                Label {
                                    Text("Rentory couldn’t read a date from this photo, so it’s showing today’s date. Set the day it was actually taken so your report is accurate.")
                                } icon: {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                }
                                .font(RRTypography.caption)
                                .foregroundStyle(RRColours.warning)
                                .fixedSize(horizontal: false, vertical: true)

                                Button("Today’s date is correct") {
                                    dateIsConfirmed = true
                                }
                                .font(RRTypography.caption.weight(.semibold))
                                .foregroundStyle(RRColours.secondary)
                            }
                        }

                        Picker("Where this photo belongs", selection: $evidencePhase) {
                            ForEach(EvidencePhase.allCases, id: \.self) { phase in
                                Text(phase.rawValue).tag(phase)
                            }
                        }

                        Toggle("Include in report", isOn: $includeInReport)
                            .accessibilityLabel("Include in report")
                    }
                }

                RRDestructiveButton(title: "Delete photo") {
                    isShowingDeleteConfirmation = true
                }
                .accessibilityHint("Removes this photo from this record.")
            }
            .padding(20)
        }
        .background(RRColours.groupedBackground.ignoresSafeArea())
        .navigationTitle("Photo")
        .rrInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .rrPrimaryAction) {
                Button("Save") {
                    saveChanges()
                }
            }
        }
        .task(id: photo.localFileName) {
            loadImage()
        }
        .rrConfirmationDialog(DialogCopy.deletePhoto, isPresented: $isShowingDeleteConfirmation) {
            deletePhoto()
        }
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
    }

    private func loadImage() {
        do {
            loadedImage = try photoStorageService.loadPhoto(fileName: photo.localFileName)
        } catch {
            loadedImage = nil
        }
    }

    private func saveChanges() {
        photo.caption = optionalText(caption)
        photo.evidencePhase = evidencePhase
        photo.capturedAt = capturedAt
        photo.captureDateIsConfirmed = dateIsConfirmed
        photo.includeInExport = includeInReport

        do {
            try modelContext.save()
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeSaved)
        }
    }

    private func deletePhoto() {
        do {
            try photoStorageService.deletePhoto(fileName: photo.localFileName)
            modelContext.delete(photo)
            try modelContext.save()
            RentorySnapshotPublisher.requestRepublish()
            RRHaptics.success()
            dismiss()
        } catch {
            alertContent = RRAlertContent(error: .photoCouldNotBeDeleted)
        }
    }
}
