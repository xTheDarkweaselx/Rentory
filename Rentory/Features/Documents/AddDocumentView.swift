//
//  AddDocumentView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct AddDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let propertyPack: PropertyPack

    private let fileStorageService = FileStorageService()

    @State private var displayName = ""
    @State private var documentType: DocumentType = .other
    @State private var hasDocumentDate = false
    @State private var documentDate = Date()
    @State private var notes = ""
    @State private var includeInReport = true
    @State private var selectedFileURL: URL?
    @State private var isShowingFileImporter = false
    @State private var validationMessage: String?
    @State private var userFacingError: UserFacingError?
    @State private var isSavingDocument = false

    private let allowedContentTypes: [UTType] = [
        .pdf,
        .image,
        .plainText,
        .rtf,
        .rtfd,
        .rrDoc,
        .rrDocx,
    ].compactMap { $0 }

    var body: some View {
        NavigationStack {
            ZStack {
                RRBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Add document",
                            subtitle: "Keep useful paperwork with this rental record.",
                            systemImage: "doc.text"
                        )

                        if let validationMessage {
                            validationCard(validationMessage)
                        }

                        RRGlassPanel {
                            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                                RRSectionHeader(
                                    title: "Document details",
                                    subtitle: "Name the file and choose what kind of paperwork it is."
                                )

                                VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                                    Text("Document name")
                                        .font(RRTypography.footnote.weight(.semibold))
                                        .foregroundStyle(RRColours.mutedText)

                                    TextField("Document name", text: $displayName)
                                        .textFieldStyle(.roundedBorder)
                                        .rrTextInputAutocapitalizationWords()
                                }

                                DocumentTypePickerView(selectedType: $documentType)

                                Toggle("Add document date", isOn: $hasDocumentDate.animation())
                                    .tint(RRColours.secondary)

                                if hasDocumentDate {
                                    DatePicker("Document date", selection: $documentDate, displayedComponents: .date)
                                }
                            }
                        }

                        RRGlassPanel {
                            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                                RRSectionHeader(
                                    title: "File",
                                    subtitle: "Choose the file that should be attached to this record."
                                )

                                RRSecondaryButton(title: selectedFileURL == nil ? "Choose file" : "Choose a different file") {
                                    isShowingFileImporter = true
                                }

                                Text(selectedFileURL == nil ? "No file selected yet." : "File selected.")
                                    .font(RRTypography.footnote)
                                    .foregroundStyle(RRColours.mutedText)
                            }
                        }

                        RRGlassPanel {
                            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                                RRSectionHeader(title: "Notes and report")

                                TextField("Add a short note", text: $notes, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...6)

                                Toggle("Include in report", isOn: $includeInReport)
                                    .tint(RRColours.secondary)
                            }
                        }

                        if !PlatformLayout.isMac {
                            RRGlassPanel {
                                ViewThatFits(in: .horizontal) {
                                    HStack(spacing: RRTheme.controlSpacing) {
                                        Spacer()
                                        actionButtons
                                    }

                                    VStack(spacing: RRTheme.controlSpacing) {
                                        actionButtons
                                    }
                                }
                            }
                            .tint(RRColours.secondary)
                        }
                    }
                    .frame(maxWidth: PlatformLayout.preferredDialogWidth, alignment: .leading)
                    .padding(RRTheme.screenPadding)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .scrollIndicators(.hidden)
                .overlay {
                    if isSavingDocument {
                        ZStack {
                            Color.black.opacity(0.12)
                                .ignoresSafeArea()

                            RRLoadingView(
                                title: "Adding document",
                                message: "Please wait while this document is added."
                            )
                            .padding(24)
                        }
                    }
                }
            }
            .navigationTitle("Add document")
            .rrInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDocument()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(RRColours.secondary)
                }
            }
        }
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: allowedContentTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                selectedFileURL = urls.first
            case .failure(let error):
                let nsError = error as NSError
                if nsError.domain == NSCocoaErrorDomain, nsError.code == NSUserCancelledError {
                    break
                }
                userFacingError = .documentCouldNotBeAdded
            }
        }
        .alert(item: $userFacingError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .cancel(Text(error.recoveryActionTitle ?? "OK"))
            )
        }
    }

    private var actionButtons: some View {
        Group {
            RRSecondaryButton(title: "Cancel") {
                dismiss()
            }
            .frame(maxWidth: PlatformLayout.prefersFooterButtons ? 150 : .infinity)

            RRPrimaryButton(title: "Save document") {
                saveDocument()
            }
            .frame(maxWidth: PlatformLayout.prefersFooterButtons ? 170 : .infinity)
        }
    }

    private func validationCard(_ message: String) -> some View {
        RRGlassPanel {
            Text(message)
                .font(RRTypography.footnote.weight(.semibold))
                .foregroundStyle(RRColours.danger)
        }
    }

    private func saveDocument() {
        let trimmedDisplayName = trimmed(displayName)

        guard !trimmedDisplayName.isEmpty else {
            validationMessage = "Add a document name to continue."
            return
        }

        guard let selectedFileURL else {
            validationMessage = "Choose a file to add."
            return
        }

        let didStartAccessing = selectedFileURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                selectedFileURL.stopAccessingSecurityScopedResource()
            }
        }

        isSavingDocument = true
        defer { isSavingDocument = false }

        do {
            let storedFileName = try fileStorageService.saveDocument(from: selectedFileURL)
            let document = DocumentRecord(
                displayName: trimmedDisplayName,
                type: documentType,
                localFileName: storedFileName,
                notes: optionalText(notes),
                documentDate: hasDocumentDate ? documentDate : nil,
                addedAt: .now,
                includeInExport: includeInReport
            )

            propertyPack.documents.append(document)
            propertyPack.updatedAt = .now
            try modelContext.save()
            dismiss()
        } catch {
            userFacingError = .documentCouldNotBeAdded
        }
    }
}

private extension UTType {
    static let rrDoc = UTType(filenameExtension: "doc")
    static let rrDocx = UTType(filenameExtension: "docx")
}
