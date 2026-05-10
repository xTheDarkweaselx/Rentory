//
//  ReportReadyView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ReportReadyView: View {
    let reportURL: URL

    @State private var isShowingSaveExporter = false
    @State private var userFacingError: UserFacingError?

    var body: some View {
        RRMacSheetContainer(maxWidth: 760, minHeight: PlatformLayout.isMac ? 520 : nil) {
            VStack(spacing: 24) {
                Spacer()

                RRGlassPanel {
                    VStack(spacing: 18) {
                        reportIcon
                            .accessibilityHidden(true)

                        VStack(spacing: RRTheme.smallSpacing) {
                            Text("Report ready")
                                .font(RRTypography.largeTitle)
                                .foregroundStyle(RRColours.primary)

                            Text("Your report has been created on this device. You can save a copy where you want it, or share it now.")
                                .font(RRTypography.body)
                                .foregroundStyle(RRColours.mutedText)
                                .multilineTextAlignment(.center)
                        }

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: RRTheme.controlSpacing) {
                                actionButtons
                            }
                            .frame(maxWidth: .infinity, alignment: .center)

                            VStack(spacing: RRTheme.controlSpacing) {
                                actionButtons
                            }
                            .frame(maxWidth: 220)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                Spacer()
            }
        }
        .navigationTitle("Report ready")
        .rrInlineNavigationTitle()
        .fileExporter(
            isPresented: $isShowingSaveExporter,
            document: ReportPDFDocument(url: reportURL),
            contentType: .pdf,
            defaultFilename: "Rentory report.pdf"
        ) { result in
            if case .failure = result {
                userFacingError = .reportCouldNotBeSaved
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

    private var reportIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: RRTheme.cornerRadius, style: .continuous)
                .fill(RRColours.success.opacity(0.14))
                .overlay {
                    RoundedRectangle(cornerRadius: RRTheme.cornerRadius, style: .continuous)
                        .stroke(RRColours.success.opacity(0.26), lineWidth: 1)
                }

            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(RRColours.primary)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(RRColours.success)
                    .background(Circle().fill(RRColours.cardBackground))
                    .offset(x: 5, y: 5)
            }
        }
        .frame(width: 64, height: 64)
    }

    private var actionButtons: some View {
        Group {
            Button {
                isShowingSaveExporter = true
            } label: {
                Label("Save to device", systemImage: "square.and.arrow.down")
                    .lineLimit(1)
                    .frame(width: 190)
            }
            .buttonStyle(.glassProminent)
            .accessibilityHint("Choose where to save a copy of the report.")

            ReportShareView(reportURL: reportURL)
                .buttonStyle(.glass)
                .accessibilityHint("Opens the share sheet.")
        }
    }
}

private struct ReportPDFDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }

    let data: Data

    init(url: URL) {
        data = (try? Data(contentsOf: url, options: [.mappedIfSafe])) ?? Data()
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
