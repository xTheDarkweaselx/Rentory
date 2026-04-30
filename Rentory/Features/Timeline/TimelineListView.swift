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

    private var groupedEvents: [(title: String, events: [TimelineEvent])] {
        let grouped = Dictionary(grouping: propertyPack.timelineEvents) { event in
            monthFormatter.string(from: event.eventDate)
        }

        return grouped
            .map { title, events in
                (
                    title: title,
                    events: events.sorted { $0.eventDate < $1.eventDate }
                )
            }
            .sorted { lhs, rhs in
                guard let lhsDate = lhs.events.first?.eventDate,
                      let rhsDate = rhs.events.first?.eventDate else {
                    return lhs.title < rhs.title
                }

                return lhsDate < rhsDate
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if groupedEvents.isEmpty {
                    RREmptyStateView(
                        symbolName: "calendar",
                        title: "No timeline events yet",
                        message: "Add key dates, updates or notes when something useful happens."
                    )
                } else {
                    ForEach(groupedEvents, id: \.title) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.title)
                                .font(RRTypography.headline)
                                .foregroundStyle(RRColours.primary)
                                .accessibilityAddTraits(.isHeader)

                            LazyVStack(spacing: 12) {
                                ForEach(group.events) { event in
                                    NavigationLink {
                                        TimelineEventDetailView(event: event)
                                    } label: {
                                        TimelineEventRowView(event: event)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: DeviceLayout.contentWidth(for: horizontalSizeClass, maximum: 900), alignment: .leading)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(RRColours.groupedBackground.ignoresSafeArea())
        .navigationTitle("Timeline")
        .rrInlineNavigationTitle()
    }

    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}
