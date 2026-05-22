//
//  PropertyDashboardView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI

struct PropertyDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext

    let propertyPack: PropertyPack

    @State private var activeSheet: DashboardSheet?
    @State private var isShowingExportOptions = false
    @State private var isShowingProgressView = false
    @State private var isShowingRemindersList = false
    @State private var isShowingTenanciesList = false
    @State private var selectedReminder: Reminder?
    @State private var infoAlertContent: RRAlertContent?
    @State private var csvShareItem: CSVShareItem?

    @AppStorage(RentoryUserProfile.storageKey) private var profileRawValue = RentoryUserProfile.defaultProfile.rawValue

    private var profile: RentoryUserProfile {
        RentoryUserProfile(rawValue: profileRawValue) ?? .defaultProfile
    }

    private var isLandlord: Bool { profile == .landlord }

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

    @AppStorage(AppColourTheme.storageKey) private var appColourThemeRawValue = AppColourTheme.defaultLook.rawValue

    private var activeStage: TenancyStage { propertyPack.effectiveTenancyStage }

    private var stageBinding: Binding<TenancyStage> {
        Binding(
            get: { propertyPack.effectiveTenancyStage },
            set: { newStage in
                propertyPack.manualTenancyStage = newStage
                propertyPack.updatedAt = .now
                try? modelContext.save()
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PropertySummaryCard(propertyPack: propertyPack, showsLastUpdated: true)
                stageSelector
                RemindersCard(
                    propertyPack: propertyPack,
                    onSelectReminder: { reminder in selectedReminder = reminder },
                    onViewAllReminders: { isShowingRemindersList = true },
                    onAddReminder: { activeSheet = .addReminder }
                )
                if isLandlord {
                    TenanciesCard(
                        propertyPack: propertyPack,
                        onAddTenancy: { activeSheet = .addTenancy },
                        onViewAllTenancies: { isShowingTenanciesList = true }
                    )
                    ComplianceCard(
                        propertyPack: propertyPack,
                        onSelectReminder: { reminder in selectedReminder = reminder },
                        onViewAllReminders: { isShowingRemindersList = true },
                        onAddReminder: { activeSheet = .addReminder }
                    )
                    FinanceSummaryCard(
                        propertyPack: propertyPack,
                        onAddExpense: { activeSheet = .addExpense },
                        onViewAllExpenses: { activeSheet = .addExpense },
                        onExportCSV: { exportFinanceCSV() }
                    )
                }
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
                        activeSheet = .addRoom
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
                    Button {
                        activeSheet = .photoTargetPicker
                    } label: {
                        quickActionCard(
                            title: "Add photo",
                            icon: "camera",
                            message: "Choose a room item, then add photo evidence."
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add photo")
                    .accessibilityHint("Choose the room and checklist item for this photo.")
                    Button {
                        activeSheet = .addDocument
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
                        activeSheet = .addEvent
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
                        activeSheet = .addReminder
                    } label: {
                        RRGlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                RRIconBadge(systemName: "checklist", tint: RRColours.secondary)

                                Text("Add reminder")
                                    .font(RRTypography.headline)
                                    .foregroundStyle(RRColours.primary)

                                Text("Track repairs to chase, inspections to attend and dates to remember.")
                                    .font(RRTypography.caption)
                                    .foregroundStyle(RRColours.mutedText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add reminder")
                    .accessibilityHint("Adds a reminder to track for this rental record.")
                    if isLandlord {
                        Button {
                            activeSheet = .addTenancy
                        } label: {
                            RRGlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    RRIconBadge(systemName: "person.2", tint: RRColours.secondary)

                                    Text("Add tenancy")
                                        .font(RRTypography.headline)
                                        .foregroundStyle(RRColours.primary)

                                    Text("Record a new tenancy — tenants, dates, deposit and rent.")
                                        .font(RRTypography.caption)
                                        .foregroundStyle(RRColours.mutedText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add tenancy")
                        .accessibilityHint("Records a new tenancy for this property.")

                        Button {
                            activeSheet = .addExpense
                        } label: {
                            RRGlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    RRIconBadge(systemName: "creditcard", tint: RRColours.secondary)

                                    Text("Add expense")
                                        .font(RRTypography.headline)
                                        .foregroundStyle(RRColours.primary)

                                    Text("Log an outgoing — repair, insurance, agent fee, anything you pay.")
                                        .font(RRTypography.caption)
                                        .foregroundStyle(RRColours.mutedText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add expense")
                        .accessibilityHint("Records an expense for this property.")
                    }
                    Button {
                        isShowingProgressView = true
                    } label: {
                        quickActionCard(
                            title: "View progress",
                            icon: "chart.line.uptrend.xyaxis",
                            message: "See what is complete and what still needs attention."
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View progress")
                    .accessibilityHint("Shows the completion checklist for this record.")
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

                RoomsListSection(rooms: propertyPack.rooms, stage: activeStage) {
                    activeSheet = .addRoom
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
        .navigationDestination(isPresented: $isShowingRemindersList) {
            RemindersListView(propertyPack: propertyPack)
                .dismissOnPropertySelectionChange()
        }
        .navigationDestination(isPresented: $isShowingTenanciesList) {
            TenanciesListView(propertyPack: propertyPack)
                .dismissOnPropertySelectionChange()
        }
        .navigationDestination(item: $selectedReminder) { reminder in
            ReminderDetailView(reminder: reminder, propertyPack: propertyPack)
                .dismissOnPropertySelectionChange()
        }
        .toolbar {
            ToolbarItem(placement: .rrPrimaryAction) {
                Button("Edit") {
                    activeSheet = .edit
                }
                .accessibilityHint("Edits this rental record.")
            }
        }
        .sheet(item: $activeSheet) { sheet in
            dashboardSheetContent(for: sheet)
                .rrAdaptiveSheetPresentation()
        }
        .sheet(item: $csvShareItem) { item in
            // SwiftUI's ShareLink isn't programmatically triggerable;
            // a sheet hosting a ShareLink button keeps the flow native
            // and lets the user pick AirDrop / Mail / Files.
            VStack(spacing: RRTheme.sectionSpacing) {
                RRSheetHeader(
                    title: "Finance CSV ready",
                    subtitle: "Share or save the file for your tax records.",
                    systemImage: "tablecells.fill"
                )
                Text(item.url.lastPathComponent)
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
                    .multilineTextAlignment(.center)
                ShareLink(item: item.url) {
                    Label("Share CSV", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding()
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

    @ViewBuilder
    private func dashboardSheetContent(for sheet: DashboardSheet) -> some View {
        switch sheet {
        case .edit:
            EditPropertyView(propertyPack: propertyPack) {
                dismiss()
            }
        case .addDocument:
            AddDocumentView(propertyPack: propertyPack)
        case .photoTargetPicker:
            PhotoChecklistItemPickerView(propertyPack: propertyPack) { item in
                activeSheet = .addPhoto(item)
            }
        case .addPhoto(let item):
            AddPhotoFlowView(checklistItem: item)
        case .addRoom:
            AddRoomView(propertyPack: propertyPack)
        case .addEvent:
            AddTimelineEventView(propertyPack: propertyPack)
        case .addReminder:
            AddReminderView(propertyPack: propertyPack)
        case .addTenancy:
            AddTenancyView(propertyPack: propertyPack)
        case .addExpense:
            AddPropertyExpenseView(propertyPack: propertyPack)
        }
    }

    private func resetPresentedViews() {
        activeSheet = nil
        isShowingExportOptions = false
        isShowingProgressView = false
        isShowingRemindersList = false
        isShowingTenanciesList = false
        selectedReminder = nil
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
                        activeSheet = .addDocument
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
                    activeSheet = .addDocument
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
                        activeSheet = .addEvent
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
        eventType.symbolName
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

    private var stageSelector: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Stage")
                        .font(RRTypography.footnote.weight(.semibold))
                        .foregroundStyle(RRColours.mutedText)
                        .textCase(.uppercase)

                    Spacer()

                    Image(systemName: activeStage.systemImage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(RRColours.secondary)
                }

                Picker("Stage", selection: stageBinding) {
                    ForEach(TenancyStage.allCases) { stage in
                        Text(stage.shortTitle).tag(stage)
                    }
                }
                .pickerStyle(.segmented)

                Text(activeStage.description)
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
                    .fixedSize(horizontal: false, vertical: true)

                if propertyPack.hasStageMismatch, let derived = propertyPack.derivedTenancyStage {
                    stageMismatchBanner(derived: derived)
                }
            }
            .accessibilityElement(children: .contain)
        }
    }

    private func stageMismatchBanner(derived: TenancyStage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(RRColours.warning)

            VStack(alignment: .leading, spacing: 6) {
                Text("Your tenancy dates suggest \(derived.shortTitle).")
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    propertyPack.manualTenancyStage = nil
                    propertyPack.updatedAt = .now
                    try? modelContext.save()
                } label: {
                    Text("Switch to \(derived.shortTitle)")
                        .font(RRTypography.footnote.weight(.semibold))
                        .foregroundStyle(RRColours.secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: RRTheme.inlineBannerRadius, style: .continuous)
                .fill(RRColours.warning.opacity(0.12))
        )
    }

    private func quickActionCard(title: String, icon: String, message: String) -> some View {
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

    private func exportFinanceCSV() {
        let exporter = LandlordFinanceCSVExporter()
        let range = LandlordFinanceCSVExporter.currentUKTaxYear()
        do {
            let url = try exporter.createCSV(for: propertyPack, range: range)
            csvShareItem = CSVShareItem(url: url)
            RRHaptics.success()
        } catch {
            RRHaptics.error()
            infoAlertContent = RRAlertContent(
                title: "CSV could not be created",
                message: "Rentory could not save the finance CSV just now. Please try again."
            )
        }
    }
}

private struct CSVShareItem: Identifiable {
    let url: URL
    var id: URL { url }
}

private enum DashboardSheet: Identifiable {
    case edit
    case addDocument
    case photoTargetPicker
    case addPhoto(ChecklistItemRecord)
    case addRoom
    case addEvent
    case addReminder
    case addTenancy
    case addExpense

    var id: String {
        switch self {
        case .edit:
            return "edit"
        case .addDocument:
            return "addDocument"
        case .photoTargetPicker:
            return "photoTargetPicker"
        case .addPhoto(let item):
            return "addPhoto-\(item.id.uuidString)"
        case .addRoom:
            return "addRoom"
        case .addEvent:
            return "addEvent"
        case .addReminder:
            return "addReminder"
        case .addTenancy:
            return "addTenancy"
        case .addExpense:
            return "addExpense"
        }
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

    @AppStorage(AppColourTheme.storageKey) private var appColourThemeRawValue = AppColourTheme.defaultLook.rawValue

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
        .id(appColourThemeRawValue)
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
        event.eventType.symbolName
    }
}
