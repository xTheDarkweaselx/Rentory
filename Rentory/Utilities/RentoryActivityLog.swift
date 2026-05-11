//
//  RentoryActivityLog.swift
//  Rentory
//
//  Created by OpenAI on 11/05/2026.
//

import Foundation

struct RentoryActivityEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let kind: RentoryActivityKind
    let title: String
    let message: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        kind: RentoryActivityKind,
        title: String,
        message: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.message = message
        self.createdAt = createdAt
    }
}

enum RentoryActivityKind: String, Codable, CaseIterable {
    case backup
    case importBackup
    case report
    case iCloudSync
    case sampleData
    case archive
    case restore
    case deletion
    case record

    var title: String {
        switch self {
        case .backup: "Backup"
        case .importBackup: "Import"
        case .report: "Report"
        case .iCloudSync: "iCloud sync"
        case .sampleData: "Sample data"
        case .archive: "Archive"
        case .restore: "Restore"
        case .deletion: "Deletion"
        case .record: "Record"
        }
    }

    var systemImage: String {
        switch self {
        case .backup: "externaldrive"
        case .importBackup: "arrow.down.doc"
        case .report: "doc.richtext"
        case .iCloudSync: "icloud"
        case .sampleData: "wand.and.stars"
        case .archive: "archivebox"
        case .restore: "arrow.uturn.backward"
        case .deletion: "trash"
        case .record: "rectangle.on.rectangle"
        }
    }
}

enum RentoryActivityLog {
    private static let storageKey = "rentory.activityLog.entries"
    private static let maximumEntries = 80

    static var entries: [RentoryActivityEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decodedEntries = try? JSONDecoder().decode([RentoryActivityEntry].self, from: data) else {
            return []
        }

        return decodedEntries.sorted { $0.createdAt > $1.createdAt }
    }

    static func record(kind: RentoryActivityKind, title: String, message: String) {
        var updatedEntries = entries
        updatedEntries.insert(
            RentoryActivityEntry(kind: kind, title: title, message: message),
            at: 0
        )
        save(Array(updatedEntries.prefix(maximumEntries)))
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private static func save(_ entries: [RentoryActivityEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
