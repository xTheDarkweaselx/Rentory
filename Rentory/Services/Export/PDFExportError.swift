//
//  PDFExportError.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

enum PDFExportError: LocalizedError {
    case unableToCreateReport
    case somePhotosCouldNotBeAdded
    case unableToSaveReport

    var errorDescription: String? {
        switch self {
        case .unableToCreateReport:
            return "The report could not be created."
        case .somePhotosCouldNotBeAdded:
            return "Some photos could not be added to the report."
        case .unableToSaveReport:
            return "The report could not be saved."
        }
    }
}
