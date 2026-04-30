//
//  PDFExportService.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

struct PDFExportService {
    private let fileStorageService: FileStorageService
    private let reportBuilder: PDFReportBuilder

    init(
        fileStorageService: FileStorageService = FileStorageService(),
        reportBuilder: PDFReportBuilder = PDFReportBuilder()
    ) {
        self.fileStorageService = fileStorageService
        self.reportBuilder = reportBuilder
    }

    func createReport(for propertyPack: PropertyPack, options: ExportOptions) throws -> URL {
        do {
            let data = try reportBuilder.buildReportData(for: propertyPack, options: options)

            // TODO: Clear older temporary reports when the export flow is expanded.
            return try fileStorageService.saveTemporaryExportData(
                data,
                preferredFileName: "rentory-report-\(UUID().uuidString.lowercased()).pdf"
            )
        } catch let error as PDFExportError {
            throw error
        } catch let error as FileStorageError {
            switch error {
            case .unableToWriteFile, .unableToCreateFolder:
                throw PDFExportError.unableToSaveReport
            default:
                throw PDFExportError.unableToCreateReport
            }
        } catch {
            throw PDFExportError.unableToCreateReport
        }
    }
}
