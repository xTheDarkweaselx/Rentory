//
//  RentorySharedSnapshot.swift  (RentoryWatchComplications target)
//  Rentory
//
//  Local copy of the snapshot Codable contract. The complications
//  extension can't import the watch app's source, so the types are
//  duplicated here. Reads come from the App Group container the watch
//  app writes to (group.com.fusionstudios.rentory) — this is the
//  only data crossing the target boundary.
//
//  IMPORTANT: keep this structurally in sync with the canonical
//  Rentory/Services/Snapshot/RentorySharedSnapshot.swift in the iOS
//  app and the matching copy in RentoryWatch.
//

import Foundation

// Same `nonisolated` story as the iPhone target — keep these pure
// data types reachable from background actors so complication
// timelines can decode without an actor hop. No behaviour change.
nonisolated enum WatchComplicationSnapshotConstants {
    static let appGroupIdentifier = "group.com.fusionstudios.rentory"
    static let snapshotRelativePath = "Library/Rentory/watch-snapshot.json"
}

nonisolated struct RentorySharedSnapshot: Codable, Equatable {
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

    struct PropertyEntry: Codable, Equatable, Identifiable, Hashable {
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

    struct ReminderEntry: Codable, Equatable, Identifiable, Hashable {
        let id: UUID
        let propertyID: UUID
        let propertyNickname: String
        let title: String
        let kindRawValue: String
        let priorityRawValue: String
        let dueDate: Date
    }
}

nonisolated enum WatchComplicationSnapshotReader {
    // Belt-and-suspenders: explicit `nonisolated` on the method too,
    // so Swift 6's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` can't
    // re-isolate the static func away from the enum's declaration.
    nonisolated static func read() -> RentorySharedSnapshot {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: WatchComplicationSnapshotConstants.appGroupIdentifier
        ) else {
            return .empty
        }
        let url = container.appendingPathComponent(WatchComplicationSnapshotConstants.snapshotRelativePath, isDirectory: false)
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
