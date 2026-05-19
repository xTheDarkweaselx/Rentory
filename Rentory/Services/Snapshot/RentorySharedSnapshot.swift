//
//  RentorySharedSnapshot.swift
//  Rentory
//
//  Compact, Codable view of the parts of Rentory's data that widgets and
//  the watch app need to render. Built on the main app's @MainActor
//  context by RentorySnapshotPublisher, written to a shared App Group
//  container, and read by RentoryWidgets and RentoryWatch.
//
//  Designed for forward compatibility:
//    - All new fields go in as optional and at the end of their enclosing
//      struct so older decoders skip them safely.
//    - Bump `version` whenever the field set's *semantics* change.
//
//  Local-only: the snapshot never leaves the device. App Group containers
//  are sandboxed to this developer team.
//

import Foundation

/// App Group container identifier used by the snapshot publisher and by
/// every extension reader. Must match the value listed in each target's
/// `com.apple.security.application-groups` entitlement.
public enum RentorySharedSnapshotConstants {
    public static let appGroupIdentifier = "group.com.fusionstudios.rentory"
    public static let snapshotRelativePath = "Library/Rentory/snapshot.json"
}

public struct RentorySharedSnapshot: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public let version: Int
    public let writtenAt: Date
    public let activeProfileRawValue: String
    public let totalReminderCount: Int
    public let properties: [PropertyEntry]
    public let upcomingReminders: [ReminderEntry]

    public init(
        version: Int = RentorySharedSnapshot.currentVersion,
        writtenAt: Date,
        activeProfileRawValue: String,
        totalReminderCount: Int,
        properties: [PropertyEntry],
        upcomingReminders: [ReminderEntry]
    ) {
        self.version = version
        self.writtenAt = writtenAt
        self.activeProfileRawValue = activeProfileRawValue
        self.totalReminderCount = totalReminderCount
        self.properties = properties
        self.upcomingReminders = upcomingReminders
    }

    public static let empty = RentorySharedSnapshot(
        writtenAt: Date(timeIntervalSince1970: 0),
        activeProfileRawValue: "Renter",
        totalReminderCount: 0,
        properties: [],
        upcomingReminders: []
    )

    public struct PropertyEntry: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let nickname: String
        public let recordTypeRawValue: String
        public let profileRawValue: String
        public let isFavourite: Bool
        public let completionPercent: Int
        public let completionStatusTitle: String
        public let nextActionTitle: String?
        public let recentEventTitle: String?
        // Landlord-only — present only when profileRawValue == "Landlord".
        public let activeTenancyCount: Int?
        public let primaryTenantName: String?
        public let tenancyEndDate: Date?
        public let monthRentReceived: Double?
        public let monthExpenses: Double?
        public let monthNet: Double?
        public let currencyCode: String?

        public init(
            id: UUID,
            nickname: String,
            recordTypeRawValue: String,
            profileRawValue: String,
            isFavourite: Bool,
            completionPercent: Int,
            completionStatusTitle: String,
            nextActionTitle: String?,
            recentEventTitle: String?,
            activeTenancyCount: Int? = nil,
            primaryTenantName: String? = nil,
            tenancyEndDate: Date? = nil,
            monthRentReceived: Double? = nil,
            monthExpenses: Double? = nil,
            monthNet: Double? = nil,
            currencyCode: String? = nil
        ) {
            self.id = id
            self.nickname = nickname
            self.recordTypeRawValue = recordTypeRawValue
            self.profileRawValue = profileRawValue
            self.isFavourite = isFavourite
            self.completionPercent = completionPercent
            self.completionStatusTitle = completionStatusTitle
            self.nextActionTitle = nextActionTitle
            self.recentEventTitle = recentEventTitle
            self.activeTenancyCount = activeTenancyCount
            self.primaryTenantName = primaryTenantName
            self.tenancyEndDate = tenancyEndDate
            self.monthRentReceived = monthRentReceived
            self.monthExpenses = monthExpenses
            self.monthNet = monthNet
            self.currencyCode = currencyCode
        }
    }

    public struct ReminderEntry: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let propertyID: UUID
        public let propertyNickname: String
        public let title: String
        public let kindRawValue: String
        public let priorityRawValue: String
        public let dueDate: Date

        public init(
            id: UUID,
            propertyID: UUID,
            propertyNickname: String,
            title: String,
            kindRawValue: String,
            priorityRawValue: String,
            dueDate: Date
        ) {
            self.id = id
            self.propertyID = propertyID
            self.propertyNickname = propertyNickname
            self.title = title
            self.kindRawValue = kindRawValue
            self.priorityRawValue = priorityRawValue
            self.dueDate = dueDate
        }
    }
}

/// Synchronous file reader used by widget timelines and watch views. Keeps
/// no state. Falls back to `RentorySharedSnapshot.empty` if the file is
/// missing, corrupt, or from a future version — so the extension never
/// shows a crashed placeholder.
public enum RentorySharedSnapshotStore {
    public static func currentSnapshotURL() -> URL? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: RentorySharedSnapshotConstants.appGroupIdentifier
        ) else {
            return nil
        }
        return container.appendingPathComponent(RentorySharedSnapshotConstants.snapshotRelativePath, isDirectory: false)
    }

    public static func read() -> RentorySharedSnapshot {
        guard let url = currentSnapshotURL(),
              let data = try? Data(contentsOf: url, options: [.mappedIfSafe]) else {
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

    public static func write(_ snapshot: RentorySharedSnapshot) throws {
        guard let url = currentSnapshotURL() else {
            throw RentorySharedSnapshotError.appGroupContainerUnavailable
        }

        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: [.atomic])
    }
}

public enum RentorySharedSnapshotError: Error {
    case appGroupContainerUnavailable
}
