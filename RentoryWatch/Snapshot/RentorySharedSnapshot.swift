//
//  RentorySharedSnapshot.swift  (RentoryWatch target)
//  Rentory
//
//  Local copy of the snapshot Codable contract used by the main iOS app
//  and the Watch app. Duplicated here intentionally so the Watch target
//  has no source-level dependency on the iPhone target — they're
//  separate executables shipped together but built independently. The
//  binary contract is the JSON payload that WatchConnectivity ferries
//  across.
//
//  IMPORTANT: keep this structurally in sync with the canonical
//  Rentory/Services/Snapshot/RentorySharedSnapshot.swift in the iOS app.
//

import Foundation

// Same `nonisolated` story as the iPhone target — keep these pure
// data types reachable from background actors so widget/complication
// timelines and WatchConnectivity callbacks can decode without an
// actor hop. No behaviour change.
nonisolated enum WatchSharedSnapshotConstants {
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
