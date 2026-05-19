//
//  WatchSnapshotStore.swift  (RentoryWatch target)
//  Rentory
//
//  Persists the most recent RentorySharedSnapshot received from the
//  paired iPhone to the Watch app's Documents directory. Reads are
//  cheap and synchronous so views can pull straight from disk during
//  initialisation. The companion app delivers fresh snapshots via
//  WatchConnectivity (see WatchSessionCoordinator).
//
//  Storage uses the .completeUntilFirstUserAuthentication protection
//  class to match the iOS side's privacy stance — readable after first
//  unlock, never written in clear if the watch is locked.
//

import Foundation
import Combine
import WidgetKit

@MainActor
final class WatchSnapshotStore: ObservableObject {
    static let shared = WatchSnapshotStore()

    @Published private(set) var snapshot: RentorySharedSnapshot
    @Published private(set) var lastUpdated: Date?

    private let fileURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(fileURL: URL? = nil) {
        let resolvedURL: URL
        if let fileURL {
            resolvedURL = fileURL
        } else if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: WatchSharedSnapshotConstants.appGroupIdentifier
        ) {
            resolvedURL = groupURL.appendingPathComponent(WatchSharedSnapshotConstants.snapshotRelativePath, isDirectory: false)
        } else {
            let documents = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            resolvedURL = documents.appendingPathComponent("rentory-snapshot.json", isDirectory: false)
        }
        self.fileURL = resolvedURL

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        if let data = try? Data(contentsOf: resolvedURL, options: [.mappedIfSafe]),
           let decoded = try? decoder.decode(RentorySharedSnapshot.self, from: data),
           decoded.version <= RentorySharedSnapshot.currentVersion {
            self.snapshot = decoded
            self.lastUpdated = decoded.writtenAt
        } else {
            self.snapshot = .empty
            self.lastUpdated = nil
        }
    }

    /// Replace the persisted snapshot with the supplied one. Called from
    /// `WatchSessionCoordinator` whenever a fresh transfer arrives.
    func apply(_ snapshot: RentorySharedSnapshot) {
        guard snapshot.version <= RentorySharedSnapshot.currentVersion else { return }
        if snapshot == self.snapshot { return }
        self.snapshot = snapshot
        self.lastUpdated = snapshot.writtenAt
        persist(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func persist(_ snapshot: RentorySharedSnapshot) {
        guard let data = try? encoder.encode(snapshot) else { return }
        let parent = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
