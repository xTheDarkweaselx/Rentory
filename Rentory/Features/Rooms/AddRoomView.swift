//
//  AddRoomView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct AddRoomView: View {
    @Environment(\.dismiss) private var dismiss

    let propertyPack: PropertyPack

    @State private var roomName = ""
    @State private var roomType: RoomType = .bedroom
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
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

    private func saveRoom() {
        let trimmedRoomName = trimmed(roomName)

        guard !trimmedRoomName.isEmpty else {
            validationMessage = "Add a room name to continue."
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
