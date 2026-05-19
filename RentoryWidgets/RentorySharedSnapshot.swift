//
//  RentorySharedSnapshot.swift  (RentoryWidgets target)
//  Rentory
//
//  Local copy of the JSON contract for the snapshot the main app writes
//  to the shared App Group container. Duplicated here intentionally so
//  the widget target has no source-level dependency on the main app —
//  the contract is the JSON on disk.
//
//  IMPORTANT: keep this file structurally in sync with
//  Rentory/Services/Snapshot/RentorySharedSnapshot.swift in the main app.
//  Tests in the main app target round-trip the structure; if you add a
//  field there, add it here too.
//

import Foundation

enum RentorySharedSnapshotConstants {
    static let appGroupIdentifier = "group.com.fusionstudios.rentory"
    static let snapshotRelativePath = "Library/Rentory/snapshot.json"
}

struct RentorySharedSnapshot: Codable, Equatable {
    static let currentVersion = 1

    let version: Int
    let writtenAt: Date
    let activeProfileRawValue: String
    let totalReminderCount: Int
    let properties: [PropertyEntry]
    let upcomingReminders: [ReminderEntry]

    static let empty = RentorySharedSnapshot(
        version: currentVersion,
        writtenAt: Date(timeIntervalSince1970: 0),
        activeProfileRawValue: "Renter",
        totalReminderCount: 0,
        properties: [],
        upcomingReminders: []
    )

    struct PropertyEntry: Codable, Equatable, Identifiable {
        let id: UUID
        let nickname: String
        let recordTypeRawValue: String
        let profileRawValue: String
        let isFavourite: Bool
        let completionPercent: Int
        let completionStatusTitle: String
        let nextActionTitle: String?
        let recentEventTitle: String?
        let activeTenancyCount: Int?
        let primaryTenantName: String?
        let tenancyEndDate: Date?
        let monthRentReceived: Double?
        let monthExpenses: Double?
        let monthNet: Double?
        let currencyCode: String?
    }

    struct ReminderEntry: Codable, Equatable, Identifiable {
        let id: UUID
        let propertyID: UUID
        let propertyNickname: String
        let title: String
        let kindRawValue: String
        let priorityRawValue: String
        let dueDate: Date
    }
}

enum RentorySharedSnapshotStore {
    static func read() -> RentorySharedSnapshot {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: RentorySharedSnapshotConstants.appGroupIdentifier
        ) else {
            return .empty
        }

        let url = container.appendingPathComponent(RentorySharedSnapshotConstants.snapshotRelativePath, isDirectory: false)
        guard let data = try? Data(contentsOf: url, options: [.mappedIfSafe]) else {
            return .empty
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode(RentorySharedSnapshot.self, from: data),
              decoded.version <= RentorySharedSnapshot.currentVersion else {
            return .empty
        }
        return decoded
    }
}
