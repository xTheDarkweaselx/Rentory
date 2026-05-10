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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let document: DocumentRecord

    private let fileStorageService = FileStorageService()

    @State private var displayName: String
    @State private var documentType: DocumentType
    @State private var hasDocumentDate: Bool
    @State private var documentDate: Date
    @State private var notes: String
    @State private var includeInReport: Bool
    @State private var alertContent: RRAlertContent?
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
        ScrollView {
            VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                RRSheetHeader(
                    title: document.displayName,
                    subtitle: "Keep this document organised with a clear name and simple details.",
                    systemImage: "doc.text"
                )

                RRResponsiveFormGrid(items: [
                    RRResponsiveFormGridItem {
                        documentSection
                    },
                    RRResponsiveFormGridItem {
                        reportSection
                    },
                    RRResponsiveFormGridItem(span: .fullWidth) {
                        notesSection
                    },
                    RRResponsiveFormGridItem(span: .fullWidth) {
                        actionsSection
                    },
                ])
            }
            .frame(maxWidth: DeviceLayout.contentWidth(for: horizontalSizeClass, maximum: 900), alignment: .leading)
            .padding(RRTheme.screenPadding)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(RRBackgroundView())
        .navigationTitle(document.displayName)
        .rrInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .rrPrimaryAction) {
                Button("Save") {
                    saveChanges()
                }
            }
        }
        .rrConfirmationDialog(DialogCopy.deleteDocument, isPresented: $isShowingDeleteConfirmation) {
            deleteDocument()
        }
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
    }

    private var documentSection: some View {
        RRFormSection(title: "Document details") {
            RRFormFieldRow(title: "Document name") {
                TextField("Document name", text: $displayName)
                    .rrTextInputAutocapitalizationWords()
                    .textFieldStyle(.roundedBorder)
            }

            RRFormFieldRow(title: "Document type") {
                DocumentTypePickerView(selectedType: $documentType)
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Toggle("Add document date", isOn: $hasDocumentDate.animation())
                .toggleStyle(.switch)

            if hasDocumentDate {
                RRFormFieldRow(title: "Document date") {
                    DatePicker("Document date", selection: $documentDate, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var reportSection: some View {
        RRFormSection(title: "Report") {
            Toggle("Include in report", isOn: $includeInReport)
                .toggleStyle(.switch)
                .accessibilityLabel("Include in report")

            NavigationLink {
                DocumentPreviewView(document: document)
            } label: {
                Label("Open preview", systemImage: "doc.richtext")
                    .font(RRTypography.body.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: RRTheme.buttonRadius, style: .continuous)
                    .fill(RRColours.cardBackground.opacity(0.55))
            )
            .overlay {
                RoundedRectangle(cornerRadius: RRTheme.buttonRadius, style: .continuous)
                    .stroke(RRColours.border.opacity(0.22), lineWidth: 1)
            }
        }
    }

    private var notesSection: some View {
        RRFormSection(title: "Notes", message: "Add anything useful about this document.") {
            TextField("Add a short note", text: $notes, axis: .vertical)
                .lineLimit(4...8)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var actionsSection: some View {
        RRFormSection(title: "Manage document") {
            RRDestructiveButton(title: "Delete document") {
                isShowingDeleteConfirmation = true
            }
            .accessibilityHint("Removes this document from this record.")
        }
    }

    private func saveChanges() {
        let trimmedDisplayName = trimmed(displayName)

        guard !trimmedDisplayName.isEmpty else {
            alertContent = RRAlertContent(title: "Document not saved", message: "Add a document name to continue.", buttonTitle: "OK")
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
            alertContent = RRAlertContent(error: .recordCouldNotBeSaved)
        }
    }

    private func deleteDocument() {
        do {
            try fileStorageService.deleteDocument(fileName: document.localFileName)
            modelContext.delete(document)
            try modelContext.save()
            dismiss()
        } catch {
            alertContent = RRAlertContent(error: .documentCouldNotBeDeleted)
        }
    }
}
