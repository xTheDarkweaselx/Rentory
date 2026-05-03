//
//  DocumentsListView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct DocumentsListView: View {
    let propertyPack: PropertyPack

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isShowingAddDocumentView = false

    private var groupedDocuments: [(type: DocumentType, documents: [DocumentRecord])] {
        let grouped = Dictionary(grouping: propertyPack.documents) { $0.documentType }

        return grouped
            .map { key, value in
                (
                    type: key,
                    documents: value.sorted { $0.addedAt > $1.addedAt }
                )
            }
            .sorted { $0.type.rawValue < $1.type.rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                RRSheetHeader(
                    title: "Documents",
                    subtitle: "Keep useful paperwork and receipts together.",
                    systemImage: "doc.text.fill"
                )

                if propertyPack.documents.isEmpty {
                    RREmptyStateView(
                        symbolName: "doc",
                        title: "No documents yet",
                        message: "Add tenancy paperwork, receipts or other useful files when you need them.",
                        buttonTitle: "Add document",
                        buttonAction: {
                            isShowingAddDocumentView = true
                        }
                    )
                } else {
                    ForEach(groupedDocuments, id: \.type) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.type.rawValue)
                                .font(RRTypography.headline)
                                .foregroundStyle(RRColours.primary)
                                .accessibilityAddTraits(.isHeader)

                            LazyVStack(spacing: 12) {
                                ForEach(group.documents) { document in
                                    NavigationLink {
                                        DocumentDetailView(document: document)
                                    } label: {
                                        DocumentRowView(document: document)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: DeviceLayout.contentWidth(for: horizontalSizeClass, maximum: 900), alignment: .leading)
            .padding(RRTheme.screenPadding)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(RRBackgroundView())
        .navigationTitle("Documents")
        .rrInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .rrPrimaryAction) {
                Button {
                    isShowingAddDocumentView = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add document")
            }
        }
        .sheet(isPresented: $isShowingAddDocumentView) {
            AddDocumentView(propertyPack: propertyPack)
        }
    }
}
