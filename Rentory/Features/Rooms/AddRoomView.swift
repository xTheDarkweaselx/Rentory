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
            ZStack {
                RRBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Add a room",
                            subtitle: "Choose a room type and Rentory will add a simple checklist to get you started.",
                            systemImage: "door.left.hand.open"
                        )

                        if let validationMessage {
                            validationCard(validationMessage)
                        }

                        RRGlassPanel {
                            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                                RRSectionHeader(
                                    title: "Room details",
                                    subtitle: "Give the room a clear name and choose the closest room type."
                                )

                                VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                                    Text("Room name")
                                        .font(RRTypography.footnote.weight(.semibold))
                                        .foregroundStyle(RRColours.mutedText)

                                    TextField("Room name", text: $roomName)
                                        .textFieldStyle(.roundedBorder)
                                        .rrTextInputAutocapitalizationWords()
                                }

                                VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
                                    Text("Room type")
                                        .font(RRTypography.footnote.weight(.semibold))
                                        .foregroundStyle(RRColours.mutedText)

                                    Picker("Room type", selection: $roomType) {
                                        ForEach(RoomType.allCases, id: \.self) { type in
                                            Text(type.rawValue).tag(type)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                        }

                        if !PlatformLayout.isMac {
                            RRGlassPanel {
                                ViewThatFits(in: .horizontal) {
                                    HStack(spacing: RRTheme.controlSpacing) {
                                        Spacer()
                                        actionButtons
                                    }

                                    VStack(spacing: RRTheme.controlSpacing) {
                                        actionButtons
                                    }
                                }
                            }
                            .tint(RRColours.secondary)
                        }
                    }
                    .frame(maxWidth: PlatformLayout.preferredDialogWidth, alignment: .leading)
                    .padding(RRTheme.screenPadding)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .scrollIndicators(.hidden)
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
        .sheet(item: $upgradePromptContent) { content in
            LimitReachedView(title: content.title, message: content.message)
        }
    }

    private var actionButtons: some View {
        Group {
            RRSecondaryButton(title: "Cancel") {
                dismiss()
            }
            .frame(maxWidth: PlatformLayout.prefersFooterButtons ? 150 : .infinity)

            RRPrimaryButton(title: "Save room") {
                saveRoom()
            }
            .frame(maxWidth: PlatformLayout.prefersFooterButtons ? 150 : .infinity)
        }
    }

    private func validationCard(_ message: String) -> some View {
        RRGlassPanel {
            Text(message)
                .font(RRTypography.footnote.weight(.semibold))
                .foregroundStyle(RRColours.danger)
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
