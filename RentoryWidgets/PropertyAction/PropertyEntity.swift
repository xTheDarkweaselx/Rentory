//
//  PropertyEntity.swift  (RentoryWidgets target)
//  Rentory
//
//  AppIntent surface that lets the user pick a specific Rentory record
//  to pin to a widget. Configuration is per-widget (long-press → Edit),
//  so a landlord with several properties can give each widget on the
//  Home Screen a different record without changing what the main app
//  shows.
//
//  Lookups go through the shared App Group snapshot — no SwiftData in
//  the widget process. Suggested entities is the same property list
//  the user sees in the main app's records list, sorted favourite-
//  first then by recency.
//

import AppIntents
import Foundation

struct PropertyEntity: AppEntity, Hashable {
    let id: UUID
    let nickname: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Rentory record")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(nickname)")
    }

    static var defaultQuery = PropertyEntityQuery()
}

struct PropertyEntityQuery: EntityQuery {
    func entities(for identifiers: [PropertyEntity.ID]) async throws -> [PropertyEntity] {
        let snapshot = RentorySharedSnapshotStore.read()
        let lookup = Dictionary(uniqueKeysWithValues: snapshot.properties.map { ($0.id, $0) })
        return identifiers.compactMap { id in
            guard let property = lookup[id] else { return nil }
            return PropertyEntity(id: property.id, nickname: property.nickname)
        }
    }

    func suggestedEntities() async throws -> [PropertyEntity] {
        let snapshot = RentorySharedSnapshotStore.read()
        return snapshot.properties.map { PropertyEntity(id: $0.id, nickname: $0.nickname) }
    }

    func defaultResult() async -> PropertyEntity? {
        let snapshot = RentorySharedSnapshotStore.read()
        guard let first = snapshot.properties.first else { return nil }
        return PropertyEntity(id: first.id, nickname: first.nickname)
    }
}

struct PropertyActionConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose a record"
    static var description = IntentDescription("Pick which Rentory record this widget should focus on.")

    @Parameter(title: "Record")
    var property: PropertyEntity?

    init() {}

    init(property: PropertyEntity?) {
        self.property = property
    }
}
