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
        }
        .navigationDestination(isPresented: $isShowingExportOptions) {
            ExportOptionsView(propertyPack: propertyPack, showsHelpfulNote: shouldShowExportNote)
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
        }
        .sheet(isPresented: $isShowingAddDocumentView) {
            AddDocumentView(propertyPack: propertyPack)
        }
        .sheet(isPresented: $isShowingAddRoomView) {
            AddRoomView(propertyPack: propertyPack)
        }
        .sheet(isPresented: $isShowingAddEventView) {
            AddTimelineEventView(propertyPack: propertyPack)
        }
        .alert(item: $infoAlertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
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
                } label: {
                    RRGlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(propertyPack.timelineEvents.sorted(by: { $0.eventDate < $1.eventDate }).prefix(3)) { event in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title)
                                        .font(RRTypography.headline)
                                        .foregroundStyle(RRColours.primary)

                                    Text("\(event.eventType.rawValue) • \(event.eventDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(RRTypography.footnote)
                                        .foregroundStyle(RRColours.mutedText)
                                }
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
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
