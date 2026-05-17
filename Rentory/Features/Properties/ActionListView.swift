//
//  ActionListView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 17/05/2026.
//

import SwiftData
import SwiftUI

struct ActionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let propertyPack: PropertyPack

    @State private var isShowingAddSheet = false
    @State private var alertContent: RRAlertContent?

    private var openActions: [ActionItem] {
        propertyPack.actions
            .filter { !$0.isCompleted }
            .sorted { lhs, rhs in
                let lhsDate = lhs.dueDate ?? .distantFuture
                let rhsDate = rhs.dueDate ?? .distantFuture
                if lhsDate != rhsDate {
                    return lhsDate < rhsDate
                }
                return lhs.createdAt < rhs.createdAt
            }
    }

    private var completedActions: [ActionItem] {
        propertyPack.actions
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private var openGroups: [(ActionUrgency, [ActionItem])] {
        let now = Date.now
        let order: [ActionUrgency] = [.overdue, .dueSoon, .upcoming, .undated]
        return order.compactMap { urgency in
            let items = openActions.filter { ActionPulseService.urgency(for: $0, on: now) == urgency }
            return items.isEmpty ? nil : (urgency, items)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                if propertyPack.actions.isEmpty {
                    RREmptyStateView(
                        symbolName: "checklist",
                        title: "No actions yet",
                        message: "Track what needs doing so nothing slips. Things like submitting the deposit form, chasing a repair, or attending an inspection all fit here.",
                        buttonTitle: "Add an action",
                        buttonAction: { isShowingAddSheet = true }
                    )
                } else {
                    ForEach(openGroups, id: \.0) { urgency, items in
                        sectionView(title: title(for: urgency), tint: tint(for: urgency), actions: items)
                    }

                    if !completedActions.isEmpty {
                        sectionView(title: "Completed", tint: RRColours.success, actions: completedActions)
                    }
                }
            }
            .frame(maxWidth: DeviceLayout.contentWidth(for: horizontalSizeClass, maximum: 980), alignment: .leading)
            .padding(RRTheme.screenPadding)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(RRBackgroundView())
        .navigationTitle("All actions")
        .rrInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .rrPrimaryAction) {
                Button {
                    isShowingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add action")
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            AddActionView(propertyPack: propertyPack)
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

    @ViewBuilder
    private func sectionView(title: String, tint: Color, actions: [ActionItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(RRTypography.headline)
                    .foregroundStyle(tint)

                Spacer()

                Text("\(actions.count)")
                    .font(RRTypography.footnote.weight(.semibold))
                    .foregroundStyle(RRColours.mutedText)
            }

            VStack(spacing: 0) {
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    if index > 0 {
                        Divider()
                            .background(RRColours.border)
                    }
                    NavigationLink {
                        ActionDetailView(action: action, propertyPack: propertyPack)
                    } label: {
                        actionRow(action: action)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(RRColours.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    @ViewBuilder
    private func actionRow(action: ActionItem) -> some View {
        let urgency = ActionPulseService.urgency(for: action)
        HStack(spacing: 12) {
            Image(systemName: action.kind.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(RRColours.secondary)
                .frame(width: 28, height: 28)
                .background(RRColours.cardHighlight, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(action.title)
                    .font(RRTypography.headline)
                    .foregroundStyle(action.isCompleted ? RRColours.mutedText : RRColours.primary)
                    .strikethrough(action.isCompleted)
                    .lineLimit(2)

                rowSubtitle(action: action, urgency: urgency)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(RRColours.mutedText)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func rowSubtitle(action: ActionItem, urgency: ActionUrgency) -> some View {
        if action.isCompleted, let completedAt = action.completedAt {
            Text("Completed \(formattedDate(completedAt))")
                .font(RRTypography.footnote)
                .foregroundStyle(RRColours.success)
        } else if let dueDate = action.dueDate {
            Text("Due \(formattedDate(dueDate))")
                .font(RRTypography.footnote)
                .foregroundStyle(tint(for: urgency))
        } else {
            Text(action.kind.rawValue)
                .font(RRTypography.footnote)
                .foregroundStyle(RRColours.mutedText)
        }
    }

    private func title(for urgency: ActionUrgency) -> String {
        switch urgency {
        case .overdue: return "Overdue"
        case .dueSoon: return "Due this week"
        case .upcoming: return "Later"
        case .undated: return "No due date"
        case .completed: return "Completed"
        }
    }

    private func tint(for urgency: ActionUrgency) -> Color {
        switch urgency {
        case .overdue: return RRColours.danger
        case .dueSoon: return RRColours.warning
        case .upcoming, .undated: return RRColours.mutedText
        case .completed: return RRColours.success
        }
    }

    private func formattedDate(_ date: Date) -> String {
        Self.formatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "en_GB")
        return formatter
    }()
}
