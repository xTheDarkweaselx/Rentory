//
//  DocumentPreviewView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

#if canImport(QuickLook)
import QuickLook
#endif

struct DocumentPreviewView: View {
    let document: DocumentRecord

    private let fileStorageService = FileStorageService()

    @State private var previewURL: URL?
    @State private var isPreviewAvailable = true

    var body: some View {
        Group {
            if isPreviewAvailable {
                if let previewURL {
                    QuickLookDocumentPreview(url: previewURL)
                } else {
                    RRLoadingView(
                        title: "Opening document",
                        message: "Please wait while this document is opened."
                    )
                    .padding(24)
                }
            } else {
                RRErrorStateView(
                    symbolName: "doc",
                    title: "Document not opened",
                    message: "This document could not be opened here."
                )
                .padding(24)
            }
        }
        .navigationTitle(document.displayName)
        .rrInlineNavigationTitle()
        .task {
            loadPreviewURL()
        }
    }

    private func loadPreviewURL() {
        do {
            previewURL = try fileStorageService.urlForDocument(fileName: document.localFileName)
            isPreviewAvailable = previewURL != nil
        } catch {
            previewURL = nil
            isPreviewAvailable = false
        }
    }
}

#if os(iOS)
import UIKit

private struct QuickLookDocumentPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        context.coordinator.url = url
        uiViewController.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        var url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}
#else
private struct QuickLookDocumentPreview: View {
    let url: URL

    var body: some View {
        RRErrorStateView(
            symbolName: "doc",
            title: "Document not opened",
            message: "This document could not be opened here."
        )
        .padding(24)
    }
}
#endif
