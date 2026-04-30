//
//  RoomDetailView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RoomDetailView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let room: RoomRecord

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
        .background(RRColours.groupedBackground.ignoresSafeArea())
        .navigationTitle(room.name)
        .rrInlineNavigationTitle()
    }

    private var roomSummaryCard: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(room.name)
                    .font(RRTypography.title)
                    .foregroundStyle(RRColours.primary)

                Text(room.type.rawValue)
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)

                RRProgressPill(title: progressLabel)

                Text("\(checkedItemCount) of \(room.checklistItems.count) checked")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }
        }
        .frame(maxWidth: DeviceLayout.isRegularWidth(horizontalSizeClass) ? 280 : .infinity, alignment: .leading)
    }

    private var checklistHeader: some View {
        RRSectionHeader(
            title: "Checklist",
            subtitle: "\(checkedItemCount) of \(room.checklistItems.count) checked"
        )
        .accessibilityElement(children: .combine)
    }

    private var checklistRows: some View {
        LazyVStack(spacing: 12) {
            ForEach(sortedChecklistItems) { item in
                NavigationLink {
                    ChecklistItemDetailView(checklistItem: item)
                } label: {
                    ChecklistItemRowView(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
