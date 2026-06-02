//
//  RoomsListSection.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

/// Value pushed onto the detail NavigationStack when the user taps a
/// room row. Carries the room itself + the tenancy stage the dashboard
/// was on at the time of the push, so RoomDetailView can render
/// correctly. Hashable so it can sit inside `NavigationPath`.
struct RoomDestination: Hashable {
    let room: RoomRecord
    let stage: TenancyStage?
}

struct RoomsListSection: View {
    let rooms: [RoomRecord]
    var stage: TenancyStage? = nil
    let addRoomAction: () -> Void

    private var sortedRooms: [RoomRecord] {
        rooms.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RRSectionHeader(title: "Rooms", subtitle: roomsSubtitle)

            if sortedRooms.isEmpty {
                RREmptyStateView(
                    symbolName: "square.grid.2x2",
                    title: "No rooms added yet",
                    message: "Add rooms to start building your rental record.",
                    buttonTitle: "Add a room",
                    buttonAction: addRoomAction
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(sortedRooms) { room in
                        // Value-based navigation: pushes a
                        // `RoomDestination` into the outer
                        // NavigationStack's path. PropertiesSplitView
                        // registers `.navigationDestination(for:
                        // RoomDestination.self)` to actually build
                        // the RoomDetailView. This means
                        // `detailNavigationPath = NavigationPath()`
                        // will pop the room view — view-based
                        // `NavigationLink { destination }` pushes
                        // would survive that reset.
                        NavigationLink(value: RoomDestination(room: room, stage: stage)) {
                            RoomRowView(room: room)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var roomsSubtitle: String {
        switch stage {
        case .moveIn:
            return "Record the move-in condition for each space."
        case .living:
            return "Note anything new during the tenancy."
        case .moveOut:
            return "Record the move-out condition for each space."
        case .none:
            return "Work through each space at your own pace."
        }
    }
}
