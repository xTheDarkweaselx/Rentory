//
//  DocumentRecord.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation
import SwiftData

@Model
final class DocumentRecord {
    var id: UUID
    var displayName: String
    var documentTypeRawValue: String
    // Store a generated local file name only. Never store an absolute path or the original imported file name.
    var localFileName: String
    var notes: String?
    var documentDate: Date?
    var addedAt: Date
    var includeInExport: Bool

    var documentType: DocumentType {
        get { DocumentType(rawValue: documentTypeRawValue) ?? .other }
        set { documentTypeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        displayName: String,
        type: DocumentType,
        localFileName: String,
        notes: String? = nil,
        documentDate: Date? = nil,
        addedAt: Date = .now,
        includeInExport: Bool = true
    ) {
        self.id = id
        self.displayName = displayName
        self.documentTypeRawValue = type.rawValue
        self.localFileName = localFileName
        self.notes = notes
        self.documentDate = documentDate
        self.addedAt = addedAt
        self.includeInExport = includeInExport
    }
}
