//
//  RoomDetailView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI

struct RoomDetailView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext

    let room: RoomRecord
    var stage: TenancyStage? = nil

    @State private var isShowingAddItemSheet = false
    @State private var alertContent: RRAlertContent?

    private var checkedItemCount: Int {
        room.checklistItems.filter { item in
            item.moveInCondition != .notChecked || item.moveOutCondition != .notChecked
        }.count
    }

    private var progressLabel: String {
        guard !room.checklistItems.isEmpty else {
            return "Not started"
        }

        if checkedItemCount == 0 {
            return "Not started"
        }

        if checkedItemCount == room.checklistItems.count {
            return "Checked"
        }

        return "In progress"
    }

    private var sortedChecklistItems: [ChecklistItemRecord] {
        room.checklistItems.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if DeviceLayout.isRegularWidth(horizontalSizeClass) {
                    HStack(alignment: .top, spacing: 20) {
                        roomSummaryCard

                        VStack(alignment: .leading, spacing: 16) {
                            checklistHeader
                            checklistRows
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    roomSummaryCard
                    checklistHeader
                    checklistRows
                }
            }
            .frame(maxWidth: DeviceLayout.contentWidth(for: horizontalSizeClass, maximum: 980), alignment: .leading)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(RRBackgroundView())
        .navigationTitle(room.name)
        .rrInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .rrPrimaryAction) {
                Button {
                    isShowingAddItemSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add item")
            }
        }
        .sheet(isPresented: $isShowingAddItemSheet) {
            AddChecklistItemView(room: room)
                .rrAdaptiveSheetPresentation()
        }
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
    }

    private var roomSummaryCard: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                RRIconBadge(systemName: "square.grid.2x2", tint: RRColours.secondary)

                Text(room.name)
                    .font(RRTypography.title)
                    .foregroundStyle(RRColours.primary)

                Text(room.type.rawValue)
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)

                conditionOverrideMenu

                RRProgressPill(title: progressLabel)

                Text("\(checkedItemCount) of \(room.checklistItems.count) checked")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }
        }
        .frame(maxWidth: DeviceLayout.isRegularWidth(horizontalSizeClass) ? 280 : .infinity, alignment: .leading)
    }

    private var conditionOverrideMenu: some View {
        Menu {
            Button {
                setOverride(nil)
            } label: {
                if room.manualConditionOverride == nil {
                    Label("Auto (from items)", systemImage: "checkmark")
                } else {
                    Text("Auto (from items)")
                }
            }

            Divider()

            ForEach(EvidenceCondition.allCases, id: \.self) { condition in
                Button {
                    setOverride(condition)
                } label: {
                    if room.manualConditionOverride == condition {
                        Label(condition.rawValue, systemImage: "checkmark")
                    } else {
                        Text(condition.rawValue)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                RRConditionBadge(condition: room.displayCondition)

                if room.manualConditionOverride != nil {
                    Text("Manual")
                        .font(RRTypography.caption.weight(.semibold))
                        .foregroundStyle(RRColours.mutedText)
                }

                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(RRColours.secondary)
            }
        }
        .accessibilityLabel("Room condition: \(room.displayCondition.rawValue)\(room.manualConditionOverride != nil ? ", manual override" : "")")
        .accessibilityHint("Choose Auto to roll up from items, or set a manual condition.")
    }

    private func setOverride(_ condition: EvidenceCondition?) {
        room.manualConditionOverride = condition
        room.updatedAt = .now

        do {
            try modelContext.save()
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeSaved)
        }
    }

    private var checklistHeader: some View {
        RRSectionHeader(
            title: "Checklist",
            subtitle: "Check each item room by room."
        )
        .accessibilityElement(children: .combine)
    }

    private var checklistRows: some View {
        // Spacing has to clear the card's drop-shadow (radius 20, y +10)
        // and its own internal padding — at 12pt the next card landed
        // visually on top of the previous card's shadow tail and made
        // the rows feel cramped/overlapping.
        LazyVStack(spacing: 20) {
            ForEach(sortedChecklistItems) { item in
                NavigationLink {
                    ChecklistItemDetailView(checklistItem: item, stage: stage)
                } label: {
                    ChecklistItemRowView(item: item, stage: stage)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
