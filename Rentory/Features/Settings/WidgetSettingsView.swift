//
//  WidgetSettingsView.swift
//  Rentory
//
//  Read-only inventory of the widgets and watch surfaces Rentory ships,
//  plus a snapshot freshness indicator so the user knows when each
//  surface last received fresh data from the main app. There's nothing
//  to toggle — widgets are added via the Home Screen / watch face,
//  not via the app — but users still want a single place to see
//  "what's available, how do I add it, and is it up to date?".
//

import SwiftUI
import WidgetKit

@MainActor
struct WidgetSettingsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.rrUsesEmbeddedNavigationLayout) private var usesEmbeddedNavigationLayout
    @AppStorage(RentoryUserProfile.storageKey) private var profileRawValue = RentoryUserProfile.defaultProfile.rawValue

    @State private var lastSnapshotWrittenAt: Date?
    @State private var snapshotPropertyCount: Int = 0
    @State private var snapshotReminderCount: Int = 0
    @State private var isRefreshing = false

    /// Monthly Finance is only meaningful on the landlord profile. Hide
    /// its row on renter so renters aren't shown widget surfaces that
    /// won't do anything useful for them.
    private var showsLandlordWidgets: Bool {
        (RentoryUserProfile(rawValue: profileRawValue) ?? .defaultProfile) == .landlord
    }

    var body: some View {
        Group {
            if PlatformLayout.isPhone && horizontalSizeClass != .regular {
                compactView
            } else if usesEmbeddedNavigationLayout {
                RRFormContainer(maxWidth: 880) {
                    RRResponsiveFormGrid(items: gridItems)
                }
            } else {
                RRMacSheetContainer(maxWidth: 880, minHeight: PlatformLayout.isMac ? 520 : nil) {
                    VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                        RRSheetHeader(
                            title: "Widgets",
                            subtitle: "Glanceable Rentory tiles for iPhone, iPad and Apple Watch.",
                            systemImage: "square.grid.2x2"
                        )

                        RRResponsiveFormGrid(items: gridItems)
                    }
                }
            }
        }
        .navigationTitle("Widgets")
        .rrInlineNavigationTitle()
        .task {
            await loadSnapshotMetadata()
        }
    }

    // MARK: - Compact (iPhone)

    private var compactView: some View {
        Form {
            Section {
                snapshotFreshnessRow
                refreshButton
            } header: {
                Text("Last refreshed")
            } footer: {
                Text("Widgets read the latest snapshot Rentory wrote to its shared container. Open the app to refresh; tap “Refresh now” if a widget looks out of date.")
            }

            Section {
                widgetRow(
                    title: "Next reminder",
                    summary: "The single next reminder due across your records.",
                    families: "Small · Medium",
                    systemImage: "bell.fill"
                )
                if showsLandlordWidgets {
                    widgetRow(
                        title: "Monthly finance",
                        summary: "This month’s rent in, expenses out and net.",
                        families: "Small · Medium",
                        systemImage: "sterlingsign.circle.fill"
                    )
                }
                widgetRow(
                    title: "Next step",
                    summary: "Your top record’s next suggested action and completion progress.",
                    families: "Small · Medium",
                    systemImage: "list.bullet.clipboard"
                )
            } header: {
                Text("Home Screen widgets")
            } footer: {
                Text("Long-press your Home Screen, tap the + in the top-left, search “Rentory”, then choose the widget and size.")
            }

            Section {
                watchSurfaceRow(
                    title: "Reminders tab",
                    summary: "Upcoming reminders with urgency-tinted countdowns."
                )
                watchSurfaceRow(
                    title: "Records tab",
                    summary: "Property snapshots with completion ring and next step."
                )
                watchSurfaceRow(
                    title: "Quick add",
                    summary: "Capture a new reminder via Scribble / dictation."
                )
                watchSurfaceRow(
                    title: "Next reminder complication",
                    summary: "Watch-face complication across circular, rectangular, inline and corner families."
                )
                watchSurfaceRow(
                    title: "Record progress complication",
                    summary: "Top record’s completion ring and next step on the watch face."
                )
            } header: {
                Text("Apple Watch")
            } footer: {
                Text("Install Rentory on your paired Apple Watch from the Watch app. Long-press the watch face to add a Rentory complication.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
    }

    // MARK: - Regular (iPad / Mac)

    private var gridItems: [RRResponsiveFormGridItem] {
        var items: [RRResponsiveFormGridItem] = [
            RRResponsiveFormGridItem(span: .fullWidth) {
                snapshotFreshnessCard
            },
            RRResponsiveFormGridItem(span: .fullWidth) {
                settingsSubsection(
                    title: "Home Screen widgets",
                    subtitle: "Long-press your Home Screen, tap the + in the top-left, search “Rentory”, then choose the widget and size."
                )
            },
            RRResponsiveFormGridItem {
                widgetCard(
                    title: "Next reminder",
                    summary: "The single next reminder due across your records.",
                    families: "Small · Medium",
                    systemImage: "bell.fill"
                )
            },
        ]
        if showsLandlordWidgets {
            items.append(
                RRResponsiveFormGridItem {
                    widgetCard(
                        title: "Monthly finance",
                        summary: "This month’s rent in, expenses out and net.",
                        families: "Small · Medium",
                        systemImage: "sterlingsign.circle.fill"
                    )
                }
            )
        }
        items.append(contentsOf: [
            RRResponsiveFormGridItem {
                widgetCard(
                    title: "Next step",
                    summary: "Your top record’s next suggested action and completion progress.",
                    families: "Small · Medium",
                    systemImage: "list.bullet.clipboard"
                )
            },
            RRResponsiveFormGridItem(span: .fullWidth) {
                settingsSubsection(
                    title: "Apple Watch",
                    subtitle: "Install Rentory on your paired Apple Watch from the Watch app on iPhone. Long-press the watch face to add a Rentory complication."
                )
            },
            RRResponsiveFormGridItem {
                watchSurfaceCard(
                    title: "Watch app",
                    summary: "Three-tab layout: Reminders, Records and Quick Add — kept shallow so glances stay glances."
                )
            },
            RRResponsiveFormGridItem {
                watchSurfaceCard(
                    title: "Complications",
                    summary: "Next reminder + Record progress complications, supporting accessoryCircular, accessoryRectangular, accessoryInline and accessoryCorner families."
                )
            },
        ])
        return items
    }

    // MARK: - Cards / rows

    private var snapshotFreshnessRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(lastUpdatedTitle)
                .font(RRTypography.body.weight(.semibold))
                .foregroundStyle(RRColours.primary)
            Text(lastUpdatedSubtitle)
                .font(RRTypography.footnote)
                .foregroundStyle(RRColours.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var snapshotFreshnessCard: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text("Last refreshed")
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)

                Text(lastUpdatedSubtitle)
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 18) {
                    statValue(label: "Properties", value: "\(snapshotPropertyCount)")
                    statValue(label: "Upcoming reminders", value: "\(snapshotReminderCount)")
                }

                refreshButton
            }
        }
    }

    private var refreshButton: some View {
        Button {
            Task {
                await reloadAllWidgets()
            }
        } label: {
            HStack(spacing: 6) {
                if isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(isRefreshing ? "Refreshing widgets…" : "Refresh widgets now")
                    .font(RRTypography.body.weight(.semibold))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(RRColours.secondary)
        .disabled(isRefreshing)
        .accessibilityHint("Asks iOS to reload Rentory widgets and watch complications.")
    }

    private func widgetRow(title: String, summary: String, families: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RRColours.secondary)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(RRTypography.body.weight(.semibold))
                    .foregroundStyle(RRColours.primary)
                Text(summary)
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(families)
                    .font(RRTypography.caption.weight(.semibold))
                    .foregroundStyle(RRColours.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func widgetCard(title: String, summary: String, families: String, systemImage: String) -> some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(RRColours.secondary)
                    Text(title)
                        .font(RRTypography.headline)
                        .foregroundStyle(RRColours.primary)
                }

                Text(summary)
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(families)
                    .font(RRTypography.footnote.weight(.semibold))
                    .foregroundStyle(RRColours.secondary)
            }
        }
    }

    private func watchSurfaceRow(title: String, summary: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(RRTypography.body.weight(.semibold))
                .foregroundStyle(RRColours.primary)
            Text(summary)
                .font(RRTypography.footnote)
                .foregroundStyle(RRColours.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    private func watchSurfaceCard(title: String, summary: String) -> some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                Text(title)
                    .font(RRTypography.headline)
                    .foregroundStyle(RRColours.primary)
                Text(summary)
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func statValue(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(RRTypography.headline)
                .foregroundStyle(RRColours.primary)
            Text(label)
                .font(RRTypography.caption.weight(.semibold))
                .foregroundStyle(RRColours.mutedText)
        }
    }

    private func settingsSubsection(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
            Text(title)
                .font(RRTypography.headline)
                .foregroundStyle(RRColours.primary)
            Text(subtitle)
                .font(RRTypography.footnote)
                .foregroundStyle(RRColours.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, RRTheme.smallSpacing)
    }

    // MARK: - Copy

    private var lastUpdatedTitle: String {
        guard let written = lastSnapshotWrittenAt, written.timeIntervalSince1970 > 0 else {
            return "No snapshot yet"
        }
        return "Refreshed \(written.formatted(.relative(presentation: .named)))"
    }

    private var lastUpdatedSubtitle: String {
        guard let written = lastSnapshotWrittenAt, written.timeIntervalSince1970 > 0 else {
            return "Open a property or switch profile to publish a snapshot for the widgets and watch."
        }
        let absolute = written.formatted(date: .abbreviated, time: .shortened)
        return "\(absolute) · \(snapshotPropertyCount) propert\(snapshotPropertyCount == 1 ? "y" : "ies"), \(snapshotReminderCount) upcoming reminder\(snapshotReminderCount == 1 ? "" : "s")."
    }

    // MARK: - Actions

    private func loadSnapshotMetadata() async {
        let snapshot = RentorySharedSnapshotStore.read()
        lastSnapshotWrittenAt = snapshot.writtenAt
        snapshotPropertyCount = snapshot.properties.count
        snapshotReminderCount = snapshot.upcomingReminders.count
    }

    private func reloadAllWidgets() async {
        isRefreshing = true
        defer { isRefreshing = false }
        WidgetCenter.shared.reloadAllTimelines()
        // Tiny artificial delay so the spinner doesn't flash off before
        // the user perceives the action — purely affordance, not work.
        try? await Task.sleep(nanoseconds: 350_000_000)
        await loadSnapshotMetadata()
    }
}
