//
//  CreatePropertyView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#endif

struct CreatePropertyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @Query private var propertyPacks: [PropertyPack]
    @Query private var allPhotos: [EvidencePhoto]

    @State private var nickname = ""
    @State private var addressLine1 = ""
    @State private var addressLine2 = ""
    @State private var townCity = ""
    @State private var postcode = ""
    @State private var hasTenancyStartDate = false
    @State private var tenancyStartDate = Date()
    @State private var hasTenancyEndDate = false
    @State private var tenancyEndDate = Date()
    @State private var landlordOrAgentName = ""
    @State private var landlordOrAgentEmail = ""
    @State private var depositSchemeName = ""
    @State private var depositReference = ""
    @State private var notes = ""
    @State private var validationMessage: String?
    @State private var upgradePromptContent: UpgradePromptContent?
    @State private var userFacingError: UserFacingError?
    @State private var isShowingDocumentImporter = false
    @State private var isShowingPhotoImporter = false
    @State private var draftDocuments: [DraftDocumentAttachment] = []
    @State private var draftPhotos: [DraftPhotoAttachment] = []

    private let fileStorageService = FileStorageService()
    private let photoStorageService = PhotoStorageService()

    private let documentContentTypes: [UTType] = [
        .pdf,
        .image,
        .plainText,
        .rtf,
        .rtfd,
        .rrDoc,
        .rrDocx,
    ].compactMap { $0 }

    private var realPropertyPacksCount: Int {
        propertyPacks.filter { !isSampleProperty($0) }.count
    }

    private var isOnlySampleDataUsingFreeRecord: Bool {
        propertyPacks.contains(where: isSampleProperty) && realPropertyPacksCount == 0
    }

    var body: some View {
        NavigationStack {
            PropertyFormView(
                title: "Create a record",
                subtitle: "Start with the basics. You can add more now or come back later.\n\nOnly the property name is needed to save a draft.",
                systemImage: "house",
                validationMessage: validationMessage,
                nickname: $nickname,
                addressLine1: $addressLine1,
                addressLine2: $addressLine2,
                townCity: $townCity,
                postcode: $postcode,
                hasTenancyStartDate: $hasTenancyStartDate,
                tenancyStartDate: $tenancyStartDate,
                hasTenancyEndDate: $hasTenancyEndDate,
                tenancyEndDate: $tenancyEndDate,
                landlordOrAgentName: $landlordOrAgentName,
                landlordOrAgentEmail: $landlordOrAgentEmail,
                depositSchemeName: $depositSchemeName,
                depositReference: $depositReference,
                notes: $notes
            ) {
                filesTabContent
            } footer: {
                footerButtons
            }
            .navigationTitle("Create a record")
            .rrInlineNavigationTitle()
        }
        .fileImporter(
            isPresented: $isShowingDocumentImporter,
            allowedContentTypes: documentContentTypes,
            allowsMultipleSelection: true,
            onCompletion: handleImportedDocuments
        )
        .fileImporter(
            isPresented: $isShowingPhotoImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true,
            onCompletion: handleImportedPhotos
        )
        .sheet(item: $upgradePromptContent) { content in
            LimitReachedView(title: content.title, message: content.message)
        }
        .alert(item: $userFacingError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .cancel(Text(error.recoveryActionTitle ?? "OK"))
            )
        }
    }

    private var filesTabContent: some View {
        RRResponsiveFormGrid(items: filesTabItems)
    }

    private var filesTabItems: [RRResponsiveFormGridItem] {
        var items: [RRResponsiveFormGridItem] = [
            RRResponsiveFormGridItem(span: .fullWidth) {
                RRGlassPanel {
                    VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                        Text("Files")
                            .font(RRTypography.headline)
                            .foregroundStyle(RRColours.primary)

                        Text("Add tenancy paperwork, photos or other useful files now, or leave this for later.")
                            .font(RRTypography.body)
                            .foregroundStyle(RRColours.mutedText)

                        HStack(spacing: RRTheme.controlSpacing) {
                            RRSecondaryButton(title: "Add document") {
                                isShowingDocumentImporter = true
                            }

                            RRSecondaryButton(title: "Add photo") {
                                isShowingPhotoImporter = true
                            }
                        }
                    }
                }
            },
        ]

        if draftDocuments.isEmpty && draftPhotos.isEmpty {
            items.append(
                RRResponsiveFormGridItem(span: .fullWidth) {
                    RRGlassPanel {
                        VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                            Text("No files added yet")
                                .font(RRTypography.headline)
                                .foregroundStyle(RRColours.primary)

                            Text("You can add documents or photos now, or come back later.")
                                .font(RRTypography.body)
                                .foregroundStyle(RRColours.mutedText)
                        }
                    }
                }
            )
            return items
        }

        if !draftDocuments.isEmpty {
            items.append(
                RRResponsiveFormGridItem {
                    RRGlassPanel {
                        VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                            Text("Documents")
                                .font(RRTypography.headline)
                                .foregroundStyle(RRColours.primary)

                            ForEach(draftDocuments) { document in
                                draftAttachmentRow(title: document.displayName) {
                                    draftDocuments.removeAll { $0.id == document.id }
                                }
                            }
                        }
                    }
                }
            )
        }

        if !draftPhotos.isEmpty {
            items.append(
                RRResponsiveFormGridItem {
                    RRGlassPanel {
                        VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                            Text("Photos")
                                .font(RRTypography.headline)
                                .foregroundStyle(RRColours.primary)

                            Text("\(draftPhotos.count) photo\(draftPhotos.count == 1 ? "" : "s") ready to save with this record.")
                                .font(RRTypography.body)
                                .foregroundStyle(RRColours.mutedText)

                            ForEach(draftPhotos) { photo in
                                draftAttachmentRow(title: photo.displayName) {
                                    draftPhotos.removeAll { $0.id == photo.id }
                                }
                            }
                        }
                    }
                }
            )
        }

        return items
    }

    private func draftAttachmentRow(title: String, removeAction: @escaping () -> Void) -> some View {
        HStack(spacing: RRTheme.controlSpacing) {
            Text(title)
                .font(RRTypography.body)
                .foregroundStyle(RRColours.primary)
                .lineLimit(1)

            Spacer(minLength: 12)

            Button(action: removeAction) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(RRColours.mutedText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(title)")
        }
    }

    private var footerButtons: some View {
        RRGlassPanel {
            Group {
                if PlatformLayout.prefersFooterButtons {
                    HStack(spacing: RRTheme.controlSpacing) {
                        Spacer()

                        RRSecondaryButton(title: "Cancel") {
                            dismiss()
                        }
                        .frame(width: 150)

                        RRPrimaryButton(title: "Save draft") {
                            saveProperty()
                        }
                        .frame(width: 150)
                    }
                } else {
                    VStack(spacing: RRTheme.controlSpacing) {
                        RRPrimaryButton(title: "Save draft") {
                            saveProperty()
                        }

                        RRSecondaryButton(title: "Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func saveProperty() {
        let trimmedNickname = trimmed(nickname)
        let trimmedEmail = trimmed(landlordOrAgentEmail)

        guard !trimmedNickname.isEmpty else {
            validationMessage = "Add a property name to save this record."
            return
        }

        guard isValidDateRange else {
            validationMessage = "Check the tenancy dates. The end date can’t be before the start date."
            return
        }

        guard trimmedEmail.isEmpty || isLightweightEmail(trimmedEmail) else {
            validationMessage = "Check the email address or leave it blank."
            return
        }

        guard FeatureAccessService.canCreateProperty(
            currentPropertyCount: propertyPacks.count,
            isUnlocked: entitlementManager.isUnlocked
        ) else {
            upgradePromptContent = FeatureAccessService.propertyLimitPrompt(
                isSampleDataUsingFreeRecord: isOnlySampleDataUsingFreeRecord
            )
            return
        }

        let propertyPack = PropertyPack(
            nickname: trimmedNickname,
            addressLine1: optionalText(addressLine1),
            addressLine2: optionalText(addressLine2),
            townCity: optionalText(townCity),
            postcode: optionalText(postcode),
            tenancyStartDate: hasTenancyStartDate ? tenancyStartDate : nil,
            tenancyEndDate: hasTenancyEndDate ? tenancyEndDate : nil,
            landlordOrAgentName: optionalText(landlordOrAgentName),
            landlordOrAgentEmail: trimmedEmail.isEmpty ? nil : trimmedEmail,
            depositSchemeName: optionalText(depositSchemeName),
            depositReference: optionalText(depositReference),
            notes: optionalText(notes),
            createdAt: .now,
            updatedAt: .now
        )

        var savedDocumentFileNames: [String] = []
        var savedPhotoFileNames: [String] = []

        do {
            try appendDraftDocuments(to: propertyPack, savedDocumentFileNames: &savedDocumentFileNames)
            try appendDraftPhotos(to: propertyPack, savedPhotoFileNames: &savedPhotoFileNames)
            modelContext.insert(propertyPack)
            try modelContext.save()
            dismiss()
        } catch {
            cleanupDraftFiles(documentFileNames: savedDocumentFileNames, photoFileNames: savedPhotoFileNames)
            userFacingError = .recordCouldNotBeSaved
        }
    }

    private func appendDraftDocuments(
        to propertyPack: PropertyPack,
        savedDocumentFileNames: inout [String]
    ) throws {
        for document in draftDocuments {
            let didStartAccessing = document.sourceURL.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    document.sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            let storedFileName = try fileStorageService.saveDocument(from: document.sourceURL)
            savedDocumentFileNames.append(storedFileName)

            propertyPack.documents.append(
                DocumentRecord(
                    displayName: document.displayName,
                    type: .other,
                    localFileName: storedFileName,
                    addedAt: .now,
                    includeInExport: true
                )
            )
        }
    }

    private func appendDraftPhotos(
        to propertyPack: PropertyPack,
        savedPhotoFileNames: inout [String]
    ) throws {
        guard !draftPhotos.isEmpty else {
            return
        }

        let checklistItem = generalPhotosChecklistItem(for: propertyPack)
        let existingPhotoCount = checklistItem.photos.count

        for (index, draftPhoto) in draftPhotos.enumerated() {
            let storedFileName = try photoStorageService.savePhoto(draftPhoto.image)
            savedPhotoFileNames.append(storedFileName)

            checklistItem.photos.append(
                EvidencePhoto(
                    localFileName: storedFileName,
                    phase: .duringTenancy,
                    sortOrder: existingPhotoCount + index
                )
            )
        }

        checklistItem.updatedAt = .now
    }

    private func generalPhotosChecklistItem(for propertyPack: PropertyPack) -> ChecklistItemRecord {
        if let existingRoom = propertyPack.rooms.first(where: { $0.name == "General" }),
           let existingChecklistItem = existingRoom.checklistItems.first(where: { $0.title == "General photos" }) {
            return existingChecklistItem
        }

        let checklistItem = ChecklistItemRecord(title: "General photos", sortOrder: 0)
        let room = RoomRecord(
            name: "General",
            type: .other,
            sortOrder: propertyPack.rooms.count,
            updatedAt: .now,
            checklistItems: [checklistItem]
        )
        propertyPack.rooms.append(room)
        return checklistItem
    }

    private func cleanupDraftFiles(documentFileNames: [String], photoFileNames: [String]) {
        for fileName in documentFileNames {
            try? fileStorageService.deleteDocument(fileName: fileName)
        }

        for fileName in photoFileNames {
            try? fileStorageService.deleteEvidencePhoto(fileName: fileName)
        }
    }

    private func handleImportedDocuments(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            let newDocuments = urls.map {
                DraftDocumentAttachment(
                    sourceURL: $0,
                    displayName: $0.deletingPathExtension().lastPathComponent
                )
            }
            draftDocuments.append(contentsOf: newDocuments)
        case .failure(let error):
            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain, nsError.code == NSUserCancelledError {
                return
            }
            userFacingError = .documentCouldNotBeAdded
        }
    }

    private func handleImportedPhotos(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard entitlementManager.isUnlocked || allPhotos.count + draftPhotos.count + urls.count <= FreePlanLimits.maxPhotos else {
                upgradePromptContent = FeatureAccessService.photoLimitPrompt
                return
            }

            var importedPhotos: [DraftPhotoAttachment] = []

            for url in urls {
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                guard let imageData = try? Data(contentsOf: url),
                      let image = UIImage(data: imageData) else {
                    userFacingError = .fileTypeNotSupported
                    return
                }

                importedPhotos.append(
                    DraftPhotoAttachment(
                        image: image,
                        displayName: url.deletingPathExtension().lastPathComponent
                    )
                )
            }

            draftPhotos.append(contentsOf: importedPhotos)
        case .failure(let error):
            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain, nsError.code == NSUserCancelledError {
                return
            }
            userFacingError = .photoCouldNotBeAdded
        }
    }

    private var isValidDateRange: Bool {
        guard hasTenancyStartDate, hasTenancyEndDate else {
            return true
        }

        return tenancyEndDate >= tenancyStartDate
    }

    private func isSampleProperty(_ propertyPack: PropertyPack) -> Bool {
#if DEBUG
        DemoModeSettings.matchesDemoRecord(propertyPack)
#else
        false
#endif
    }
}

private struct DraftDocumentAttachment: Identifiable {
    let id = UUID()
    let sourceURL: URL
    let displayName: String
}

private struct DraftPhotoAttachment: Identifiable {
    let id = UUID()
    let image: UIImage
    let displayName: String
}

private extension UTType {
    static let rrDoc = UTType(filenameExtension: "doc")
    static let rrDocx = UTType(filenameExtension: "docx")
}
