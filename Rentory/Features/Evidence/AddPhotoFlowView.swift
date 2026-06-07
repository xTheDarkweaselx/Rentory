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
    var stage: TenancyStage?

    /// Most photos selected from the library in one go. Free-plan limits
    /// still apply per photo while saving; this is just a sanity ceiling
    /// so a single import can't pull in a runaway number of images.
    private static let maxBatchSelection = 25

    private let photoStorageService = PhotoStorageService()

    @State private var selectedPhase: EvidencePhase
    @State private var isShowingCamera = false
    @State private var isShowingPhotoPicker = false
    @State private var userFacingError: UserFacingError?
    @State private var infoAlert: RRAlertContent?
    @State private var isSavingPhoto = false
    @State private var savingPhotoCount = 1
    @State private var upgradePromptContent: UpgradePromptContent?

#if canImport(PhotosUI)
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
#endif

    init(checklistItem: ChecklistItemRecord, stage: TenancyStage? = nil) {
        self.checklistItem = checklistItem
        self.stage = stage
        let allowed = Self.allowedPhases(for: stage)
        _selectedPhase = State(initialValue: Self.initialPhase(for: stage, allowed: allowed))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                RRSheetHeader(
                    title: "Add a photo",
                    subtitle: "Take a new photo, or choose one or more from your library.",
                    systemImage: "camera.viewfinder"
                )

                RRCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Where this photo belongs")
                            .font(RRTypography.caption.weight(.semibold))
                            .foregroundStyle(RRColours.secondary)

                        Picker("Where this photo belongs", selection: $selectedPhase) {
                            ForEach(allowedPhases, id: \.self) { phase in
                                Text(phase.rawValue).tag(phase)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        Text("Set from your current stage — tap to change.")
                            .font(RRTypography.caption)
                            .foregroundStyle(RRColours.mutedText)
                    }
                }

                PhotoSourcePickerView(
                    isCameraAvailable: CameraCaptureView.isCameraAvailable,
                    onTakePhoto: { isShowingCamera = true },
                    onChooseFromPhotos: { isShowingPhotoPicker = true }
                )

                Spacer(minLength: 0)
            }
            .padding(RRTheme.screenPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .navigationTitle("Add a photo")
            .rrInlineNavigationTitle()
            .background(RRBackgroundView())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if isSavingPhoto {
                    ZStack {
                        Rectangle()
                            .fill(.black.opacity(0.12))
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture {} // Swallow taps while saving.

                        RRLoadingView(title: savingTitle, message: savingMessage)
                            .padding(24)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraCaptureView(
                onImageCaptured: { image in
                    isShowingCamera = false
                    handleCameraImage(image)
                },
                onCancel: {
                    isShowingCamera = false
                }
            )
        }
#if canImport(PhotosUI)
        .photosPicker(
            isPresented: $isShowingPhotoPicker,
            selection: $selectedPhotoItems,
            maxSelectionCount: Self.maxBatchSelection,
            matching: .images,
            preferredItemEncoding: .current
        )
        .task(id: selectedPhotoItems) {
            let items = selectedPhotoItems
            guard !items.isEmpty else { return }
            await processSelectedItems(items)
            selectedPhotoItems = []
        }
#endif
        .alert(item: $userFacingError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .cancel(Text(error.recoveryActionTitle ?? "OK"))
            )
        }
        .alert(item: $infoAlert) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .default(Text(content.buttonTitle)) { dismiss() }
            )
        }
        .sheet(item: $upgradePromptContent) { content in
            LimitReachedView(title: content.title, message: content.message)
        }
    }

    private var savingTitle: String {
        savingPhotoCount == 1 ? "Adding photo" : "Adding photos"
    }

    private var savingMessage: String {
        savingPhotoCount == 1
            ? "Please wait while your photo is added."
            : "Please wait while your \(savingPhotoCount) photos are added."
    }

    private var allowedPhases: [EvidencePhase] { Self.allowedPhases(for: stage) }

    /// Phases the user is allowed to tag a new photo with. Mirrors the
    /// move-out lock applied in ChecklistItemDetailView: during move-in
    /// or while living, "Move-out" is hidden so the user doesn't end up
    /// with a stray exit photo before the tenancy is actually winding
    /// down. Static so it can be resolved in `init` and unit-tested.
    static func allowedPhases(for stage: TenancyStage?) -> [EvidencePhase] {
        switch stage {
        case .moveIn, .living:
            return EvidencePhase.allCases.filter { $0 != .moveOut }
        case .moveOut, .none:
            return EvidencePhase.allCases
        }
    }

    /// The phase a freshly opened add-photo flow should default to —
    /// derived from the property's current stage so the common case
    /// (documenting the stage you're in) needs no extra tap. Falls back
    /// to the first allowed phase if the preferred one isn't allowed.
    static func initialPhase(for stage: TenancyStage?, allowed: [EvidencePhase]) -> EvidencePhase {
        let preferred = stage?.matchingPhase ?? .moveIn
        return allowed.contains(preferred) ? preferred : (allowed.first ?? .moveIn)
    }

    private func handleCameraImage(_ image: UIImage) {
        guard FeatureAccessService.canAddPhoto(
            currentPhotoCount: allPhotos.count,
            isUnlocked: entitlementManager.isUnlocked
        ) else {
            upgradePromptContent = FeatureAccessService.photoLimitPrompt
            return
        }

        savingPhotoCount = 1
        isSavingPhoto = true
        defer { isSavingPhoto = false }

        do {
            // A freshly captured photo is, by definition, taken now —
            // so "now" is a genuine capture date, not a guess.
            let fileName = try photoStorageService.savePhoto(image)
            try appendPhoto(fileName: fileName, capturedAt: nil, dateIsConfirmed: true)
            dismiss()
        } catch {
            userFacingError = .photoCouldNotBeAdded
        }
    }

#if canImport(PhotosUI)
    private func processSelectedItems(_ items: [PhotosPickerItem]) async {
        savingPhotoCount = items.count
        isSavingPhoto = true
        defer { isSavingPhoto = false }

        var addedCount = 0
        var failedCount = 0
        var hitLimit = false

        for item in items {
            guard FeatureAccessService.canAddPhoto(
                currentPhotoCount: allPhotos.count + addedCount,
                isUnlocked: entitlementManager.isUnlocked
            ) else {
                hitLimit = true
                break
            }

            do {
                guard let imageData = try await item.loadTransferable(type: Data.self) else {
                    failedCount += 1
                    continue
                }

                // Decode, read the EXIF capture date, resize and encode the
                // image, then store it to disk. The image/storage utilities
                // are main-actor-isolated, so this runs on the main actor;
                // yielding first lets a large batch refresh the UI (and its
                // progress) between photos, and the selection is capped so
                // the total work stays bounded.
                await Task.yield()
                guard let prepared = Self.prepareImport(from: imageData) else {
                    failedCount += 1
                    continue
                }

                // Back on the main actor: the only step that must touch the
                // SwiftData context. No readable capture date → unconfirmed.
                try appendPhoto(
                    fileName: prepared.fileName,
                    capturedAt: prepared.capturedAt,
                    dateIsConfirmed: prepared.capturedAt != nil
                )
                addedCount += 1
            } catch {
                failedCount += 1
            }
        }

        resolveBatch(addedCount: addedCount, failedCount: failedCount, hitLimit: hitLimit)
    }

    /// Decodes the image, reads its EXIF capture date and stores a
    /// resized copy to disk, returning the stored file name and the
    /// capture date (if any). `nil` when the image can't be read.
    private static func prepareImport(from data: Data) -> (fileName: String, capturedAt: Date?)? {
        guard let image = UIImage(data: data) else { return nil }
        let capturedAt = PhotoCaptureDate.captureDate(fromImageData: data)
        guard let fileName = try? PhotoStorageService().savePhoto(image) else { return nil }
        return (fileName, capturedAt)
    }

    private func resolveBatch(addedCount: Int, failedCount: Int, hitLimit: Bool) {
        if hitLimit {
            // Photos that did save are kept; the prompt explains the cap.
            upgradePromptContent = FeatureAccessService.photoLimitPrompt
        } else if addedCount == 0 {
            if failedCount > 0 { userFacingError = .photoCouldNotBeAdded }
        } else if failedCount > 0 {
            // Partial success — never dismiss silently on a record app.
            infoAlert = RRAlertContent(
                title: "Some photos were skipped",
                message: "Added \(addedCount) photo\(addedCount == 1 ? "" : "s"). "
                    + "\(failedCount) couldn’t be read and \(failedCount == 1 ? "was" : "were") skipped."
            )
        } else {
            dismiss()
        }
    }
#endif

    /// Appends a new `EvidencePhoto` (already stored on disk) to the item
    /// under the currently selected phase, then saves the context. Throws
    /// on save failure; the caller decides how to surface it.
    private func appendPhoto(fileName: String, capturedAt: Date?, dateIsConfirmed: Bool) throws {
        let nextSortOrder = checklistItem.photos
            .filter { $0.evidencePhase == selectedPhase }
            .count

        let photo = EvidencePhoto(
            localFileName: fileName,
            phase: selectedPhase,
            capturedAt: capturedAt ?? .now,
            captureDateIsConfirmed: dateIsConfirmed,
            sortOrder: nextSortOrder
        )

        checklistItem.photos.append(photo)
        checklistItem.updatedAt = .now
        try modelContext.save()
    }
}
