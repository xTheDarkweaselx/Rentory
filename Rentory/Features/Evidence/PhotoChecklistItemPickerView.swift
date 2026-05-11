//
//  PhotoChecklistItemPickerView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 11/05/2026.
//

import SwiftUI

struct PhotoChecklistItemPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let propertyPack: PropertyPack
    let onSelectItem: (ChecklistItemRecord) -> Void

    private var sortedRooms: [RoomRecord] {
        propertyPack.rooms.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RRBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Choose where the photo belongs",
                            subtitle: "Pick the room and checklist item first, then add the photo from your camera or photo library.",
                            systemImage: "camera.viewfinder"
                        )

                        if hasChecklistItems {
                            VStack(alignment: .leading, spacing: RRTheme.cardSpacing) {
                                ForEach(sortedRooms) { room in
                                    let sortedItems = sortedChecklistItems(for: room)
                                    if !sortedItems.isEmpty {
                                        PhotoChecklistRoomSection(
                                            room: room,
                                            items: sortedItems,
                                            onSelectItem: { item in
                                                onSelectItem(item)
                                                dismiss()
                                            }
                                        )
                                    }
                                }
                            }
                        } else {
                            RREmptyStateView(
                                symbolName: "square.grid.2x2",
                                title: "Add a room first",
                                message: "Photos are attached to checklist items, so add a room and item before adding photo evidence."
                            )
                        }
                    }
                    .frame(maxWidth: PlatformLayout.preferredDialogWidth, alignment: .leading)
                    .padding(RRTheme.screenPadding)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Choose item")
            .rrInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var hasChecklistItems: Bool {
        sortedRooms.contains { !$0.checklistItems.isEmpty }
    }

    private func sortedChecklistItems(for room: RoomRecord) -> [ChecklistItemRecord] {
        room.checklistItems.sorted { $0.sortOrder < $1.sortOrder }
    }
}

private struct PhotoChecklistRoomSection: View {
    let room: RoomRecord
    let items: [ChecklistItemRecord]
    let onSelectItem: (ChecklistItemRecord) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
            HStack(spacing: 10) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(RRColours.secondary)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(room.name)
                        .font(RRTypography.headline)
                        .foregroundStyle(RRColours.primary)

                    Text("Choose one item")
                        .font(RRTypography.caption)
                        .foregroundStyle(RRColours.mutedText)
                }
            }

            VStack(spacing: 10) {
                ForEach(items) { item in
                    Button {
                        onSelectItem(item)
                    } label: {
                        PhotoChecklistItemRow(room: room, item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(RRTheme.screenPadding)
        .background(sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: RRTheme.panelRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: RRTheme.panelRadius, style: .continuous)
                .stroke(RRColours.secondary.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(RRTheme.softShadowOpacity), radius: 20, x: 0, y: 10)
    }

    private var sectionBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                RRColours.secondary.opacity(0.13),
                RRColours.cardHighlight.opacity(0.44),
                RRColours.cardBackground.opacity(0.72),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct PhotoChecklistItemRow: View {
    let room: RoomRecord
    let item: ChecklistItemRecord

    var body: some View {
        HStack(spacing: 12) {
            RRIconBadge(systemName: "checklist", tint: RRColours.secondary, size: 38)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(RRTypography.body.weight(.semibold))
                    .foregroundStyle(RRColours.primary)
                    .lineLimit(2)

                Text(room.name)
                    .font(RRTypography.caption)
                    .foregroundStyle(RRColours.mutedText)
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RRColours.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RRTheme.controlSpacing)
        .background(itemBackground)
        .clipShape(RoundedRectangle(cornerRadius: RRTheme.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: RRTheme.cardRadius, style: .continuous)
                .stroke(RRColours.secondary.opacity(0.14), lineWidth: 1)
        }
        .contentShape(Rectangle())
    }

    private var itemBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                RRColours.cardHighlight.opacity(0.55),
                RRColours.cardBackground.opacity(0.78),
                RRColours.secondary.opacity(0.09),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
