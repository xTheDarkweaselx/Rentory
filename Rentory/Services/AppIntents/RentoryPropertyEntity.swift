//
//  RentoryPropertyEntity.swift
//  Rentory
//
//  AppEntity that surfaces the user's Rentory records to Siri /
//  Shortcuts so they can be picked as the target of an intent. This is
//  the main-app twin of the same-named entity in the widget bundle —
//  intentionally duplicated rather than shared because the entity-name
//  is target-scoped (each binary's intents donate against the entity
//  type declared in that binary). Suggestions read from the App Group
//  shared snapshot so we never touch SwiftData from the intent process,
//  which Apple lets share state with the app but doesn't isolate
//  cleanly.
//

import AppIntents
import Foundation

struct RentoryPropertyEntity: AppEntity, Hashable {
    let id: UUID
    let nickname: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Rentory record")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(nickname)")
    }

    static var defaultQuery = RentoryPropertyEntityQuery()
}

struct RentoryPropertyEntityQuery: EntityQuery {
    func entities(for identifiers: [RentoryPropertyEntity.ID]) async throws -> [RentoryPropertyEntity] {
        let snapshot = RentorySharedSnapshotStore.read()
        let lookup = Dictionary(uniqueKeysWithValues: snapshot.properties.map { ($0.id, $0) })
        return identifiers.compactMap { id in
            guard let property = lookup[id] else { return nil }
            return RentoryPropertyEntity(id: property.id, nickname: property.nickname)
        }
    }

    func suggestedEntities() async throws -> [RentoryPropertyEntity] {
        let snapshot = RentorySharedSnapshotStore.read()
        return snapshot.properties.map { RentoryPropertyEntity(id: $0.id, nickname: $0.nickname) }
    }

    func defaultResult() async -> RentoryPropertyEntity? {
        let snapshot = RentorySharedSnapshotStore.read()
        guard let first = snapshot.properties.first else { return nil }
        return RentoryPropertyEntity(id: first.id, nickname: first.nickname)
    }
}
