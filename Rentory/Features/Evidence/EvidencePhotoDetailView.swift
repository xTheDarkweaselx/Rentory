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
    @State private var includeInReport: Bool
    @State private var loadedImage: UIImage?
    @State private var alertMessage: String?
    @State private var isShowingDeleteConfirmation = false

    init(photo: EvidencePhoto) {
        self.photo = photo
        _caption = State(initialValue: photo.caption ?? "")
        _evidencePhase = State(initialValue: photo.evidencePhase)
        _includeInReport = State(initialValue: photo.includeInExport)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
        .alert("Delete this photo?", isPresented: $isShowingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deletePhoto()
            }
        } message: {
            Text("This removes the photo from this record.")
        }
        .alert("Photo update", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "This photo could not be saved.")
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { newValue in
                if !newValue {
                    alertMessage = nil
                }
            }
        )
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
        photo.includeInExport = includeInReport

        do {
            try modelContext.save()
        } catch {
            alertMessage = "This photo could not be saved."
        }
    }

    private func deletePhoto() {
        do {
            try photoStorageService.deletePhoto(fileName: photo.localFileName)
            modelContext.delete(photo)
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = "This photo could not be deleted."
        }
    }
}
