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
            RRMacSheetContainer {
                Form {
                    Section {
                        RRSheetHeader(
                            title: "Add document",
                            subtitle: "Keep useful paperwork with this rental record.",
                            systemImage: "doc.text"
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        Text("Add documents that may be useful to keep with this rental record.")
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.mutedText)

                        if let validationMessage {
                            Text(validationMessage)
                                .font(RRTypography.footnote)
                                .foregroundStyle(RRColours.danger)
                        }
                    }

                    Section("Document") {
                        TextField("Document name", text: $displayName)
                            .rrTextInputAutocapitalizationWords()

                        DocumentTypePickerView(selectedType: $documentType)

                        Toggle("Add document date", isOn: $hasDocumentDate.animation())

                        if hasDocumentDate {
                            DatePicker("Document date", selection: $documentDate, displayedComponents: .date)
                        }
                    }

                    Section("Notes") {
                        TextField("Add a short note", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                    }

                    Section {
                        Toggle("Include in report", isOn: $includeInReport)
                    }

                    Section {
                        RRSecondaryButton(title: selectedFileURL == nil ? "Choose file" : "Choose a different file") {
                            isShowingFileImporter = true
                        }

                        if selectedFileURL != nil {
                            Text("File selected")
                                .font(RRTypography.footnote)
                                .foregroundStyle(RRColours.mutedText)
                        }
                    }
                }
                .navigationTitle("Add document")
                .rrInlineNavigationTitle()
                .scrollContentBackground(.hidden)
                .background(RRBackgroundView())
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .rrPrimaryAction) {
                        Button("Save") {
                            saveDocument()
                        }
                    }
                }
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
