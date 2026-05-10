//
//  PropertyDashboardView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct PropertyDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let propertyPack: PropertyPack

    @State private var isShowingAddDocumentView = false
    @State private var isShowingExportOptions = false
    @State private var isShowingAddRoomView = false
    @State private var isShowingEditView = false
    @State private var isShowingAddEventView = false
    @State private var isShowingProgressView = false
    @State private var infoAlertContent: RRAlertContent?

    private var recentDocuments: [DocumentRecord] {
        propertyPack.documents.sorted { $0.addedAt > $1.addedAt }
    }

    private var completionScore: CompletionScoreResult {
        CompletionScoreService.score(for: propertyPack)
    }

    private var shouldShowExportNote: Bool {
        completionScore.percentage < 34
    }

    private var quickActionColumns: [GridItem] {
        DeviceLayout.isRegularWidth(horizontalSizeClass)
            ? [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ]
            : [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PropertySummaryCard(propertyPack: propertyPack, showsLastUpdated: true)
                CompletionScoreCard(result: completionScore) {
                    isShowingProgressView = true
                }

                RRSectionHeader(title: "Quick actions", subtitle: "Build your record one step at a time.") {
                    RRProgressPill(title: completionScore.statusTitle)
                }

                LazyVGrid(
                    columns: quickActionColumns,
                    spacing: 12
                ) {
                    Button {
                        isShowingAddRoomView = true
                    } label: {
                        RRGlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                RRIconBadge(systemName: "square.grid.2x2", tint: RRColours.secondary)

                                Text("Add room")
                                    .font(RRTypography.headline)
                                    .foregroundStyle(RRColours.primary)

                                Text("Add your rooms to get started.")
                                    .font(RRTypography.caption)
                                    .foregroundStyle(RRColours.mutedText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add room")
                    .accessibilityHint("Adds a room to this rental record.")
                    quickActionButton(title: "Add photo", icon: "camera", message: "Open a room item to add photos where they belong.")
                    Button {
                        isShowingAddDocumentView = true
                    } label: {
                        RRGlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                RRIconBadge(systemName: "doc", tint: RRColours.secondary)

                                Text("Add document")
                                    .font(RRTypography.headline)
                                    .foregroundStyle(RRColours.primary)

                                Text("Keep useful paperwork with this record.")
                                    .font(RRTypography.caption)
                                    .foregroundStyle(RRColours.mutedText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add document")
                    .accessibilityHint("Adds a document to this rental record.")
                    Button {
                        isShowingAddEventView = true
                    } label: {
                        RRGlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                RRIconBadge(systemName: "calendar.badge.plus", tint: RRColours.secondary)

                                Text("Add event")
                                    .font(RRTypography.headline)
                                    .foregroundStyle(RRColours.primary)

                                Text("Keep key dates and updates together.")
                                    .font(RRTypography.caption)
                                    .foregroundStyle(RRColours.mutedText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add event")
                    .accessibilityHint("Adds a timeline event to this rental record.")
                    Button {
                        isShowingExportOptions = true
                    } label: {
                        RRGlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                RRIconBadge(systemName: "square.and.arrow.up", tint: RRColours.secondary)

                                Text("Export report")
                                    .font(RRTypography.headline)
                                    .foregroundStyle(RRColours.primary)

                                Text("Choose what to include before you create it.")
                                    .font(RRTypography.caption)
                                    .foregroundStyle(RRColours.mutedText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Create report")
                    .accessibilityHint("Choose what to include in a report.")
                }

                RoomsListSection(rooms: propertyPack.rooms) {
                    isShowingAddRoomView = true
                }

                documentsSection
                timelineSection

                VStack(alignment: .leading, spacing: 16) {
                    RRSectionHeader(
                        title: "Report",
                        subtitle: shouldShowExportNote
                            ? "You can create a report now, or add more details first."
                            : "Choose what to include before you create your report."
                    ) {
                        RRSecondaryButton(title: "Create report") {
                            isShowingExportOptions = true
                        }
                    }

                    ExportPreviewSummaryView(options: ExportOptions())
                }
            }
            .frame(maxWidth: DeviceLayout.contentWidth(for: horizontalSizeClass, maximum: 980), alignment: .leading)
            .padding(RRTheme.screenPadding)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(RRBackgroundView())
        .navigationTitle(propertyPack.nickname)
        .rrInlineNavigationTitle()
        .navigationDestination(isPresented: $isShowingProgressView) {
            CompletionChecklistView(result: completionScore)
                .dismissOnPropertySelectionChange()
        }
        .navigationDestination(isPresented: $isShowingExportOptions) {
            ExportOptionsView(propertyPack: propertyPack, showsHelpfulNote: shouldShowExportNote)
                .dismissOnPropertySelectionChange()
        }
        .toolbar {
            ToolbarItem(placement: .rrPrimaryAction) {
                Button("Edit") {
                    isShowingEditView = true
                }
                .accessibilityHint("Edits this rental record.")
            }
        }
        .sheet(isPresented: $isShowingEditView) {
            EditPropertyView(propertyPack: propertyPack) {
                dismiss()
            }
            .rrAdaptiveSheetPresentation()
        }
        .sheet(isPresented: $isShowingAddDocumentView) {
            AddDocumentView(propertyPack: propertyPack)
                .rrAdaptiveSheetPresentation()
        }
        .sheet(isPresented: $isShowingAddRoomView) {
            AddRoomView(propertyPack: propertyPack)
                .rrAdaptiveSheetPresentation()
        }
        .sheet(isPresented: $isShowingAddEventView) {
            AddTimelineEventView(propertyPack: propertyPack)
                .rrAdaptiveSheetPresentation()
        }
        .alert(item: $infoAlertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
        .onChange(of: propertyPack.id) { _, _ in
            resetPresentedViews()
        }
    }

    private func resetPresentedViews() {
        isShowingAddDocumentView = false
        isShowingExportOptions = false
        isShowingAddRoomView = false
        isShowingEditView = false
        isShowingAddEventView = false
        isShowingProgressView = false
        infoAlertContent = nil
    }

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            RRSectionHeader(
                title: "Documents",
                subtitle: propertyPack.documents.isEmpty
                    ? "Keep useful paperwork together in one place."
                    : "\(propertyPack.documents.count) saved."
            ) {
                NavigationLink("View all") {
                    DocumentsListView(propertyPack: propertyPack)
                        .dismissOnPropertySelectionChange()
                }
                .font(RRTypography.footnote.weight(.semibold))
            }

            if recentDocuments.isEmpty {
                RREmptyStateView(
                    symbolName: "doc",
                    title: "No documents yet",
                    message: "Add tenancy paperwork, receipts or other useful files when you need them.",
                    buttonTitle: "Add document",
                    buttonAction: {
                        isShowingAddDocumentView = true
                    }
                )
            } else {
                NavigationLink {
                    DocumentsListView(propertyPack: propertyPack)
                        .dismissOnPropertySelectionChange()
                } label: {
                    RRGlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(recentDocuments.prefix(3)) { document in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(document.displayName)
                                        .font(RRTypography.headline)
                                        .foregroundStyle(RRColours.primary)

                                    Text(document.documentType.rawValue)
                                        .font(RRTypography.footnote)
                                        .foregroundStyle(RRColours.mutedText)
                                }
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                RRSecondaryButton(title: "Add document") {
                    isShowingAddDocumentView = true
                }
            }
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            RRSectionHeader(
                title: "Timeline",
                subtitle: propertyPack.timelineEvents.isEmpty
                    ? "Keep key moments together in one place."
                    : "\(propertyPack.timelineEvents.count) saved."
            ) {
                NavigationLink("View all") {
                    TimelineListView(propertyPack: propertyPack)
                        .dismissOnPropertySelectionChange()
                }
                .font(RRTypography.footnote.weight(.semibold))
            }

            if propertyPack.timelineEvents.isEmpty {
                RREmptyStateView(
                    symbolName: "calendar",
                    title: "No timeline events yet",
                    message: "Add key dates, updates or notes when something useful happens.",
                    buttonTitle: "Add event",
                    buttonAction: {
                        isShowingAddEventView = true
                    }
                )
            } else {
                NavigationLink {
                    TimelineListView(propertyPack: propertyPack)
                        .dismissOnPropertySelectionChange()
                } label: {
                    RRGlassCard {
                        VStack(alignment: .leading, spacing: 0) {
                            let previewEvents = Array(propertyPack.timelineEvents.sorted(by: { $0.eventDate > $1.eventDate }).prefix(3))
                            ForEach(Array(previewEvents.enumerated()), id: \.element.id) { index, event in
                                DashboardTimelinePreviewRow(
                                    event: event,
                                    isFirst: index == 0,
                                    isLast: index == previewEvents.count - 1
                                )
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func timelineSymbol(for eventType: TimelineEventType) -> String {
        switch eventType {
        case .moveIn:
            return "key.fill"
        case .inventoryReviewed:
            return "checkmark.square.fill"
        case .issueNoticed:
            return "exclamationmark.circle.fill"
        case .issueReported:
            return "paperplane.fill"
        case .repairRequested:
            return "wrench.fill"
        case .repairCompleted:
            return "checkmark.seal.fill"
        case .cleaningCompleted:
            return "sparkles"
        case .inspection:
            return "magnifyingglass"
        case .moveOut:
            return "rectangle.portrait.and.arrow.right"
        case .depositDiscussion:
            return "sterlingsign.circle.fill"
        case .other:
            return "circle.fill"
        }
    }

    private func detailSection(title: String, message: String) -> some View {
        RRCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)

                Text(message)
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)
            }
        }
    }

    private func quickActionButton(title: String, icon: String, message: String) -> some View {
        Button {
            infoAlertContent = RRAlertContent(title: title, message: message)
        } label: {
            RRGlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    RRIconBadge(systemName: icon, tint: RRColours.secondary)

                    Text(title)
                        .font(RRTypography.headline)
                        .foregroundStyle(RRColours.primary)

                    Text(message)
                        .font(RRTypography.caption)
                        .foregroundStyle(RRColours.mutedText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(message)
    }
}

private extension View {
    func dismissOnPropertySelectionChange() -> some View {
        modifier(DismissOnPropertySelectionChangeModifier())
    }
}

private struct DismissOnPropertySelectionChangeModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.task {
            let notifications = NotificationCenter.default.notifications(named: .rentoryPropertySelectionDidChange)
            for await _ in notifications {
                dismiss()
            }
        }
    }
}

private struct DashboardTimelinePreviewRow: View {
    let event: TimelineEvent
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            previewConnector

            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)
                    .lineLimit(2)

                Text("\(event.eventType.rawValue) • \(event.eventDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
                    .lineLimit(2)
            }
            .padding(.vertical, 10)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(event.title), \(event.eventType.rawValue), \(event.eventDate.formatted(date: .abbreviated, time: .omitted))")
    }

    private var previewConnector: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isFirst ? Color.clear : RRColours.border.opacity(0.55))
                    .frame(width: 2, height: 14)

                Rectangle()
                    .fill(isLast ? Color.clear : RRColours.border.opacity(0.55))
                    .frame(width: 2)
            }
            .frame(width: 32)

            ZStack {
                Circle()
                    .fill(.thinMaterial)
                    .overlay {
                        Circle()
                            .stroke(RRColours.secondary.opacity(0.26), lineWidth: 1)
                    }

                Image(systemName: symbolName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(RRColours.secondary)
            }
            .frame(width: 32, height: 32)
        }
        .frame(minWidth: 32, idealWidth: 32, maxWidth: 32, minHeight: 68, alignment: .top)
    }

    private var symbolName: String {
        switch event.eventType {
        case .moveIn:
            return "key.fill"
        case .inventoryReviewed:
            return "checkmark.square.fill"
        case .issueNoticed:
            return "exclamationmark.circle.fill"
        case .issueReported:
            return "paperplane.fill"
        case .repairRequested:
            return "wrench.fill"
        case .repairCompleted:
            return "checkmark.seal.fill"
        case .cleaningCompleted:
            return "sparkles"
        case .inspection:
            return "magnifyingglass"
        case .moveOut:
            return "rectangle.portrait.and.arrow.right"
        case .depositDiscussion:
            return "sterlingsign.circle.fill"
        case .other:
            return "circle.fill"
        }
    }
}
