//
//  AddPhotoFlowView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI

#if canImport(PhotosUI)
import PhotosUI
#endif

struct AddPhotoFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @Query private var allPhotos: [EvidencePhoto]

    let checklistItem: ChecklistItemRecord

    private let photoStorageService = PhotoStorageService()

    @State private var selectedPhase: EvidencePhase?
    @State private var isShowingCamera = false
    @State private var isShowingPhotoPicker = false
    @State private var userFacingError: UserFacingError?
    @State private var isSavingPhoto = false
    @State private var upgradePromptContent: UpgradePromptContent?

#if canImport(PhotosUI)
    @State private var selectedPhotoItem: PhotosPickerItem?
#endif

    var body: some View {
        NavigationStack {
            Group {
                if let selectedPhase {
                    VStack(spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Add a photo",
                            subtitle: "Choose where this photo belongs, then add it from your camera or photo library.",
                            systemImage: "camera.viewfinder"
                        )

                        PhotoSourcePickerView(
                            isCameraAvailable: CameraCaptureView.isCameraAvailable,
                            onTakePhoto: {
                                self.selectedPhase = selectedPhase
                                isShowingCamera = true
                            },
                            onChooseFromPhotos: {
                                self.selectedPhase = selectedPhase
                                isShowingPhotoPicker = true
                            }
                        )
                    }
                    .padding(RRTheme.screenPadding)
                } else {
                    VStack(spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Add a photo",
                            subtitle: "Choose where this photo belongs in your record.",
                            systemImage: "camera.viewfinder"
                        )

                        PhotoPhasePickerView { phase in
                            selectedPhase = phase
                        }
                    }
                    .padding(RRTheme.screenPadding)
                }
            }
            .navigationTitle("Add a photo")
            .rrInlineNavigationTitle()
            .background(RRBackgroundView())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedPhase == nil ? "Cancel" : "Back") {
                        if selectedPhase == nil {
                            dismiss()
                        } else {
                            selectedPhase = nil
                        }
                    }
                }
            }
            .overlay {
                if isSavingPhoto {
                    ZStack {
                        Color.black.opacity(0.12)
                            .ignoresSafeArea()

                        RRLoadingView(
                            title: "Adding photo",
                            message: "Please wait while this photo is added."
                        )
                        .padding(24)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraCaptureView(
                onImageCaptured: { image in
                    isShowingCamera = false
                    handleSelectedImage(image)
                },
                onCancel: {
                    isShowingCamera = false
                }
            )
        }
#if canImport(PhotosUI)
        .photosPicker(
            isPresented: $isShowingPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images,
            preferredItemEncoding: .current
        )
        .task(id: selectedPhotoItem) {
            guard let selectedPhotoItem else {
                return
            }

            do {
                guard let imageData = try await selectedPhotoItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: imageData) else {
                    throw ImageProcessingError.unableToReadImage
                }

                handleSelectedImage(image)
            } catch {
                userFacingError = .photoCouldNotBeAdded
            }

            self.selectedPhotoItem = nil
        }
#endif
        .alert(item: $userFacingError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .cancel(Text(error.recoveryActionTitle ?? "OK"))
            )
        }
        .sheet(item: $upgradePromptContent) { content in
            LimitReachedView(title: content.title, message: content.message)
        }
    }

    private func handleSelectedImage(_ image: UIImage) {
        guard let selectedPhase else {
            userFacingError = .photoCouldNotBeAdded
            return
        }

        guard FeatureAccessService.canAddPhoto(
            currentPhotoCount: allPhotos.count,
            isUnlocked: entitlementManager.isUnlocked
        ) else {
            upgradePromptContent = FeatureAccessService.photoLimitPrompt
            return
        }

        isSavingPhoto = true
        defer { isSavingPhoto = false }

        do {
            let storedFileName = try photoStorageService.savePhoto(image)
            let nextSortOrder = checklistItem.photos
                .filter { $0.evidencePhase == selectedPhase }
                .count

            let photo = EvidencePhoto(
                localFileName: storedFileName,
                phase: selectedPhase,
                sortOrder: nextSortOrder
            )

            checklistItem.photos.append(photo)
            checklistItem.updatedAt = .now
            try modelContext.save()
            dismiss()
        } catch {
            userFacingError = .photoCouldNotBeAdded
        }
    }
}
