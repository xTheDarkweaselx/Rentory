//
//  StoredFileKind.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

enum StoredFileKind {
    case evidencePhoto
    case importedDocument
    case temporaryExport

    var folderName: String {
        switch self {
        case .evidencePhoto:
            return "EvidencePhotos"
        case .importedDocument:
            return "ImportedDocuments"
        case .temporaryExport:
            return "TemporaryExports"
        }
    }
}
