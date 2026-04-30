//
//  RoomsListSection.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RoomsListSection: View {
    let rooms: [RoomRecord]
    let addRoomAction: () -> Void

    private var sortedRooms: [RoomRecord] {
        rooms.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RRSectionHeader(title: "Rooms", subtitle: "Work through each space at your own pace.")

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
                        NavigationLink {
                            RoomDetailView(room: room)
                        } label: {
                            RoomRowView(room: room)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
