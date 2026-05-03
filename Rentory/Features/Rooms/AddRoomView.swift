//
//  AddRoomView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct AddRoomView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager

    let propertyPack: PropertyPack

    @State private var roomName = ""
    @State private var roomType: RoomType = .bedroom
    @State private var validationMessage: String?
    @State private var upgradePromptContent: UpgradePromptContent?

    var body: some View {
        NavigationStack {
            RRMacSheetContainer {
                Form {
                    Section {
                        RRSheetHeader(
                            title: "Add a room",
                            subtitle: "Choose a room type and Rentory will add a simple checklist to get you started.",
                            systemImage: "door.left.hand.open"
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        Text("Choose a room type and Rentory will add a simple checklist to get you started.")
                            .font(RRTypography.footnote)
                            .foregroundStyle(RRColours.mutedText)

                        if let validationMessage {
                            Text(validationMessage)
                                .font(RRTypography.footnote)
                                .foregroundStyle(RRColours.danger)
                        }
                    }

                    Section("Room") {
                        TextField("Room name", text: $roomName)
                            .rrTextInputAutocapitalizationWords()

                        Picker("Room type", selection: $roomType) {
                            ForEach(RoomType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                }
                .navigationTitle("Add a room")
                .rrInlineNavigationTitle()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveRoom()
                        }
                    }
                }
            }
        }
        .sheet(item: $upgradePromptContent) { content in
            LimitReachedView(title: content.title, message: content.message)
        }
    }

    private func saveRoom() {
        let trimmedRoomName = trimmed(roomName)

        guard !trimmedRoomName.isEmpty else {
            validationMessage = "Add a room name to continue."
            return
        }

        guard FeatureAccessService.canAddRoom(
            currentRoomCount: propertyPack.rooms.count,
            isUnlocked: entitlementManager.isUnlocked
        ) else {
            upgradePromptContent = FeatureAccessService.roomLimitPrompt
            return
        }

        let checklistItems = RoomTemplateService
            .defaultChecklistTitles(for: roomType)
            .enumerated()
            .map { index, title in
                ChecklistItemRecord(title: title, sortOrder: index)
            }

        let roomRecord = RoomRecord(
            name: trimmedRoomName,
            type: roomType,
            sortOrder: propertyPack.rooms.count,
            checklistItems: checklistItems
        )

        propertyPack.rooms.append(roomRecord)
        propertyPack.updatedAt = .now
        dismiss()
    }
}
