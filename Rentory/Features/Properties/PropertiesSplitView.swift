//
//  PropertiesSplitView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI

struct PropertiesSplitView: View {
    @Query(sort: [SortDescriptor(\PropertyPack.updatedAt, order: .reverse)]) private var propertyPacks: [PropertyPack]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var entitlementManager: EntitlementManager

    @State private var isShowingCreateProperty = false
    @State private var isShowingSettings = false
    @State private var selectedPropertyID: UUID?
    @State private var detailNavigationPath = NavigationPath()
    @State private var detailResetID = UUID()
    @State private var upgradePromptContent: UpgradePromptContent?
    @State private var filterState = PropertyRecordFilterState()

    private var activePropertyPacks: [PropertyPack] {
        propertyPacks.filter { !$0.isArchived }
    }

    private var filteredPropertyPacks: [PropertyPack] {
        filterState.filteredRecords(from: activePropertyPacks)
    }

    private var realPropertyPacksCount: Int {
        propertyPacks.filter { !isSampleProperty($0) }.count
    }

    private var isOnlySampleDataUsingFreeRecord: Bool {
        propertyPacks.contains(where: isSampleProperty) && realPropertyPacksCount == 0
    }

    private var selectedPropertyPack: PropertyPack? {
        activePropertyPacks.first { $0.id == selectedPropertyID }
    }

    var body: some View {
        NavigationSplitView {
            List {
                if !activePropertyPacks.isEmpty {
                    Section {
                        sidebarFilters
                    }
                }

                if activePropertyPacks.isEmpty {
                    ContentUnavailableView {
                        Label("No rental records yet", systemImage: "house")
                    } description: {
                        Text("Create your first record when you are ready.")
                    } actions: {
                        Button("Create a record") {
                            showCreatePropertyOrUpgradePrompt()
                        }
                    }
                } else if filteredPropertyPacks.isEmpty {
                    ContentUnavailableView {
                        Label("No matching records", systemImage: "line.3.horizontal.decrease.circle")
                    } description: {
                        Text("Try changing the search or filters.")
                    } actions: {
                        Button("Clear filters") {
                            clearFilters()
                        }
                    }
                } else {
                    ForEach(filteredPropertyPacks) { propertyPack in
                        Button {
                            selectProperty(propertyPack)
                        } label: {
                            PropertySidebarRow(
                                propertyPack: propertyPack,
                                isSelected: selectedPropertyID == propertyPack.id
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            selectedPropertyID == propertyPack.id
                            ? RRColours.secondary.opacity(0.10)
                            : Color.clear
                        )
                        .contextMenu {
                            Button {
                                toggleFavourite(for: propertyPack)
                            } label: {
                                Label(
                                    propertyPack.isFavourite ? "Remove from favourites" : "Add to favourites",
                                    systemImage: propertyPack.isFavourite ? "star.slash" : "star"
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rentory")
            .searchable(text: $filterState.searchText, prompt: "Search records")
            .navigationSplitViewColumnWidth(
                min: PlatformLayout.preferredSidebarMinWidth,
                ideal: PlatformLayout.preferredSidebarIdealWidth,
                max: PlatformLayout.preferredSidebarMaxWidth
            )
            .toolbar {
                ToolbarItem(placement: .rrPrimaryAction) {
                    Button {
                        showCreatePropertyOrUpgradePrompt()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create a record")
                }

                ToolbarItem(placement: .rrSecondaryAction) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
        } detail: {
            NavigationStack(path: $detailNavigationPath) {
                if let selectedPropertyPack {
                    PropertyDashboardView(propertyPack: selectedPropertyPack)
                        .id(selectedPropertyPack.id)
                } else {
                    RRFormContainer(maxWidth: 620) {
                        RREmptyStateView(
                            symbolName: "rectangle.on.rectangle",
                            title: "Choose a rental record",
                            message: "Select a record from the sidebar, or create a new one when you are ready.",
                            buttonTitle: "Create a record",
                            buttonAction: showCreatePropertyOrUpgradePrompt
                        )
                    }
                    .navigationTitle("Rentory")
                }
            }
            .id(detailResetID)
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
                .rrAdaptiveSheetPresentation()
        }
        .sheet(isPresented: $isShowingCreateProperty) {
            CreatePropertyView()
                .rrAdaptiveSheetPresentation()
        }
        .sheet(item: $upgradePromptContent) { content in
            LimitReachedView(title: content.title, message: content.message)
        }
        .onChange(of: activePropertyPacks.map(\.id)) { _, newIDs in
            if let selectedPropertyID, !newIDs.contains(selectedPropertyID) {
                resetDetailNavigation()
                self.selectedPropertyID = nil
            }
        }
    }

    private var sidebarFilters: some View {
        VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
            Picker("Record type", selection: $filterState.typeFilter) {
                ForEach(PropertyRecordTypeFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.menu)

            Toggle(isOn: $filterState.showsFavouritesOnly.animation()) {
                Label("Favourites", systemImage: "star.fill")
            }

            if filterState.hasActiveFilters {
                Button("Clear filters") {
                    clearFilters()
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }

    private func clearFilters() {
        withAnimation(RRTheme.quickAnimation) {
            filterState = PropertyRecordFilterState()
        }
    }

    private func selectProperty(_ propertyPack: PropertyPack) {
        guard selectedPropertyID != propertyPack.id else { return }

        let nextPropertyID = propertyPack.id
        NotificationCenter.default.post(name: .rentoryPropertySelectionDidChange, object: nextPropertyID)
        selectedPropertyID = nextPropertyID
        resetDetailNavigation()
    }

    private func resetDetailNavigation() {
        detailNavigationPath = NavigationPath()
        detailResetID = UUID()
    }

    private func toggleFavourite(for propertyPack: PropertyPack) {
        withAnimation(RRTheme.quickAnimation) {
            propertyPack.isFavourite.toggle()
            propertyPack.updatedAt = .now
            try? modelContext.save()
        }
    }

    private func showCreatePropertyOrUpgradePrompt() {
        if FeatureAccessService.canCreateProperty(
            currentPropertyCount: propertyPacks.count,
            isUnlocked: entitlementManager.isUnlocked
        ) {
            isShowingCreateProperty = true
        } else {
            upgradePromptContent = FeatureAccessService.propertyLimitPrompt(
                isSampleDataUsingFreeRecord: isOnlySampleDataUsingFreeRecord
            )
        }
    }

    private func isSampleProperty(_ propertyPack: PropertyPack) -> Bool {
        DemoModeSettings.matchesDemoRecord(propertyPack)
    }
}

extension Notification.Name {
    static let rentoryPropertySelectionDidChange = Notification.Name("RentoryPropertySelectionDidChange")
}

private struct PropertySidebarRow: View {
    let propertyPack: PropertyPack
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: propertyPack.recordIconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? RRColours.secondary : RRColours.secondary.opacity(0.82))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(propertyPack.nickname)
                        .font(RRTypography.headline)
                        .foregroundStyle(RRColours.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if propertyPack.isFavourite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(RRColours.warning)
                    }
                }

                Text(propertyPack.recordType.rawValue)
                    .font(RRTypography.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? RRColours.secondary : RRColours.secondary.opacity(0.82))
                    .lineLimit(1)

                if let detailSummary = firstNonEmpty(propertyPack.typeDetailSummary, locationSummary) {
                    Text(detailSummary)
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Text("Updated \(propertyPack.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(RRTypography.caption)
                    .foregroundStyle(RRColours.mutedText)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private var locationSummary: String? {
        firstNonEmpty(propertyPack.townCity, propertyPack.postcode)
    }

    private func firstNonEmpty(_ values: String?...) -> String? {
        values.first(where: { value in
            guard let value else { return false }
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) ?? nil
    }
}
