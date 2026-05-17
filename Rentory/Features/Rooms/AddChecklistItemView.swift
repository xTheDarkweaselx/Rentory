//
//  AddChecklistItemView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 18/05/2026.
//

import SwiftData
import SwiftUI

struct AddChecklistItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let room: RoomRecord

    @State private var customTitle = ""
    @State private var validationMessage: String?

    private var existingTitlesLowercased: Set<String> {
        Set(room.checklistItems.map { $0.title.lowercased() })
    }

    private var suggestions: [String] {
        RoomTemplateService
            .defaultChecklistTitles(for: room.type)
            .filter { !existingTitlesLowercased.contains($0.lowercased()) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RRBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Add an item",
                            subtitle: "Tap a suggestion for this room, or type your own under Other.",
                            systemImage: "checklist"
                        )

                        if let validationMessage {
                            RRGlassPanel {
                                Text(validationMessage)
                                    .font(RRTypography.footnote.weight(.semibold))
                                    .foregroundStyle(RRColours.danger)
                            }
                        }

                        if !suggestions.isEmpty {
                            RRGlassPanel {
                                VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                                    RRSectionHeader(
                                        title: "\(room.type.rawValue) suggestions",
                                        subtitle: "Tap an item to add it to this room."
                                    )

                                    VStack(spacing: 0) {
                                        ForEach(Array(suggestions.enumerated()), id: \.element) { index, title in
                                            if index > 0 {
                                                Divider()
                                                    .background(RRColours.border)
                                            }
                                            suggestionRow(title: title)
                                        }
                                    }
                                }
                            }
                        } else {
                            RRGlassPanel {
                                Text("All suggestions for this room type are already added. Use Other to add anything extra.")
                                    .font(RRTypography.footnote)
                                    .foregroundStyle(RRColours.mutedText)
                            }
                        }

                        RRGlassPanel {
                            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                                RRSectionHeader(
                                    title: "Other",
                                    subtitle: "Add a custom item with your own name."
                                )

                                TextField("Item name", text: $customTitle)
                                    .textFieldStyle(.roundedBorder)
                                    .rrTextInputAutocapitalizationWords()

                                RRPrimaryButton(
                                    title: "Add custom item",
                                    isDisabled: customTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ) {
                                    addItem(withTitle: customTitle)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: PlatformLayout.preferredDialogWidth, alignment: .leading)
                    .padding(RRTheme.screenPadding)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Add an item")
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

    private func suggestionRow(title: String) -> some View {
        Button {
            addItem(withTitle: title)
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(RRColours.secondary)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add \(title)")
        .accessibilityHint("Adds this item to the room checklist.")
    }

    private func addItem(withTitle title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            validationMessage = "Add a name to continue."
            return
        }

        if existingTitlesLowercased.contains(trimmed.lowercased()) {
            validationMessage = "This room already has an item with that name."
            return
        }

        let item = ChecklistItemRecord(
            title: trimmed,
            sortOrder: room.checklistItems.count
        )
        room.checklistItems.append(item)
        room.updatedAt = .now

        do {
            try modelContext.save()
            dismiss()
        } catch {
            validationMessage = "Could not save the item. Try again."
        }
    }
}
