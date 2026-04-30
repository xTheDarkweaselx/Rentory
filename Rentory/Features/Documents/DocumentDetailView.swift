//
//  DocumentDetailView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI

struct DocumentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let document: DocumentRecord

    private let fileStorageService = FileStorageService()

    @State private var displayName: String
    @State private var documentType: DocumentType
    @State private var hasDocumentDate: Bool
    @State private var documentDate: Date
    @State private var notes: String
    @State private var includeInReport: Bool
    @State private var alertMessage: String?
    @State private var isShowingDeleteConfirmation = false

    init(document: DocumentRecord) {
        self.document = document
        _displayName = State(initialValue: document.displayName)
        _documentType = State(initialValue: document.documentType)
        _hasDocumentDate = State(initialValue: document.documentDate != nil)
        _documentDate = State(initialValue: document.documentDate ?? .now)
        _notes = State(initialValue: document.notes ?? "")
        _includeInReport = State(initialValue: document.includeInExport)
    }

    var body: some View {
        Form {
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
                    .accessibilityLabel("Include in report")
            }

            Section {
                NavigationLink("Open preview") {
                    DocumentPreviewView(document: document)
                }
            }

            Section {
                RRDestructiveButton(title: "Delete document") {
                    isShowingDeleteConfirmation = true
                }
                .accessibilityHint("Removes this document from this record.")
            }
        }
        .navigationTitle(document.displayName)
        .rrInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .rrPrimaryAction) {
                Button("Save") {
                    saveChanges()
                }
            }
        }
        .alert("Delete this document?", isPresented: $isShowingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteDocument()
            }
        } message: {
            Text("This removes the document from this record.")
        }
        .alert("Document update", isPresented: alertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "This document could not be opened.")
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { newValue in
                if !newValue {
                    alertMessage = nil
                }
            }
        )
    }

    private func saveChanges() {
        let trimmedDisplayName = trimmed(displayName)

        guard !trimmedDisplayName.isEmpty else {
            alertMessage = "Add a document name to continue."
            return
        }

        document.displayName = trimmedDisplayName
        document.documentType = documentType
        document.documentDate = hasDocumentDate ? documentDate : nil
        document.notes = optionalText(notes)
        document.includeInExport = includeInReport

        do {
            try modelContext.save()
        } catch {
            alertMessage = "This document could not be opened."
        }
    }

    private func deleteDocument() {
        do {
            try fileStorageService.deleteDocument(fileName: document.localFileName)
            modelContext.delete(document)
            try modelContext.save()
            dismiss()
        } catch {
            alertMessage = "This document could not be deleted."
        }
    }
}
