//
//  TimelineListView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct TimelineListView: View {
    let propertyPack: PropertyPack

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isShowingAddEventView = false
    @State private var isShowingFullTimeline = false

    private let previewEventLimit = 5

    private var sortedEvents: [TimelineEvent] {
        propertyPack.timelineEvents.sorted { $0.eventDate > $1.eventDate }
    }

    private var visibleEvents: [TimelineEvent] {
        if isShowingFullTimeline {
            return sortedEvents
        }
        return Array(sortedEvents.prefix(previewEventLimit))
    }

    private var hiddenEventCount: Int {
        max(0, sortedEvents.count - visibleEvents.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                RRSheetHeader(
                    title: "Timeline",
                    subtitle: "Keep dates, updates and notes in one place.",
                    systemImage: "calendar"
                )

                if sortedEvents.isEmpty {
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
                    RRGlassPanel {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(visibleEvents.enumerated()), id: \.element.id) { index, event in
                                NavigationLink {
                                    TimelineEventDetailView(event: event, propertyPack: propertyPack)
                                } label: {
                                    TimelineGraphEventRow(
                                        event: event,
                                        isFirst: index == 0,
                                        isLast: index == visibleEvents.count - 1 && hiddenEventCount == 0
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            if hiddenEventCount > 0 {
                                Button {
                                    withAnimation(RRTheme.quickAnimation) {
                                        isShowingFullTimeline = true
                                    }
                                } label: {
                                    HStack(spacing: 14) {
                                        timelineConnector(isFirst: false, isLast: true) {
                                            Image(systemName: "ellipsis")
                                                .font(.system(size: 14, weight: .bold))
                                        }

                                        Text("Show the full timeline")
                                            .font(RRTypography.body.weight(.semibold))
                                            .foregroundStyle(RRColours.primary)

                                        Text("\(hiddenEventCount) more")
                                            .font(RRTypography.footnote)
                                            .foregroundStyle(RRColours.mutedText)

                                        Spacer(minLength: 12)
                                    }
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Shows every timeline event for this record.")
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: DeviceLayout.contentWidth(for: horizontalSizeClass, maximum: 900), alignment: .leading)
            .padding(RRTheme.screenPadding)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(RRBackgroundView())
        .navigationTitle("Timeline")
        .rrInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .rrPrimaryAction) {
                Button {
                    isShowingAddEventView = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add event")
            }
        }
        .sheet(isPresented: $isShowingAddEventView) {
            AddTimelineEventView(propertyPack: propertyPack)
                .rrAdaptiveSheetPresentation()
        }
    }
}

private struct TimelineGraphEventRow: View {
    let event: TimelineEvent
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            timelineConnector(isFirst: isFirst, isLast: isLast) {
                Image(systemName: symbolName)
                    .font(.system(size: 13, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(event.title)
                        .font(RRTypography.headline)
                        .foregroundStyle(RRColours.primary)
                        .lineLimit(2)

                    Spacer(minLength: 12)

                    Text(event.eventDate.formatted(date: .abbreviated, time: .omitted))
                        .font(RRTypography.caption.weight(.semibold))
                        .foregroundStyle(RRColours.secondary)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        metadata
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        metadata
                    }
                }
            }
            .padding(.vertical, 14)
            .padding(.trailing, 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Opens this timeline event.")
    }

    private var metadata: some View {
        Group {
            Label(event.eventType.rawValue, systemImage: symbolName)
                .font(RRTypography.footnote)
                .foregroundStyle(RRColours.mutedText)

            if trimmed(event.notes) != nil {
                Label("Has notes", systemImage: "text.alignleft")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }
        }
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

    private var accessibilitySummary: String {
        var parts = [event.title, event.eventType.rawValue, event.eventDate.formatted(date: .abbreviated, time: .omitted)]
        if trimmed(event.notes) != nil {
            parts.append("Has notes")
        }
        return parts.joined(separator: ", ")
    }

    private func trimmed(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}

private func timelineConnector<Content: View>(
    isFirst: Bool,
    isLast: Bool,
    @ViewBuilder content: () -> Content
) -> some View {
    ZStack(alignment: .top) {
        VStack(spacing: 0) {
            Rectangle()
                .fill(isFirst ? Color.clear : RRColours.border.opacity(0.55))
                .frame(width: 2, height: 16)

            Rectangle()
                .fill(isLast ? Color.clear : RRColours.border.opacity(0.55))
                .frame(width: 2)
        }
        .frame(width: 34)

        ZStack {
            Circle()
                .fill(.thinMaterial)
                .overlay {
                    Circle()
                        .stroke(RRColours.secondary.opacity(0.26), lineWidth: 1)
                }

            content()
                .foregroundStyle(RRColours.secondary)
        }
        .frame(width: 34, height: 34)
    }
    .frame(minWidth: 34, idealWidth: 34, maxWidth: 34, minHeight: 76, alignment: .top)
}
