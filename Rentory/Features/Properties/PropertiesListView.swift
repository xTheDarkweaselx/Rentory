//
//  PropertiesListView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI

struct PropertiesListView: View {
    @Query(sort: [SortDescriptor(\PropertyPack.updatedAt, order: .reverse)]) private var propertyPacks: [PropertyPack]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var isShowingCreateProperty = false
    @State private var isShowingSettings = false
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RRSectionHeader(
                        title: "Your rental records",
                        subtitle: "Everything stays on your device by default."
                    ) {
                        RRProgressPill(title: activePropertyPacks.isEmpty ? "Getting started" : "Good progress")
                    }

                    if !activePropertyPacks.isEmpty {
                        filtersPanel
                    }

                    if activePropertyPacks.isEmpty {
                        RREmptyStateView(
                            symbolName: "house",
                            title: "No rental records yet",
                            message: "Create your first record when you are ready.",
                            buttonTitle: "Create a record",
                            buttonAction: showCreatePropertyOrUpgradePrompt
                        )
                    } else if filteredPropertyPacks.isEmpty {
                        RREmptyStateView(
                            symbolName: "line.3.horizontal.decrease.circle",
                            title: "No matching records",
                            message: "Try changing the search or filters.",
                            buttonTitle: "Clear filters",
                            buttonAction: clearFilters
                        )
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(filteredPropertyPacks) { propertyPack in
                                NavigationLink {
                                    PropertyDashboardView(propertyPack: propertyPack)
                                } label: {
                                    PropertySummaryCard(propertyPack: propertyPack, showsLastUpdated: true)
                                }
                                .buttonStyle(.plain)
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
                }
                .padding(RRTheme.screenPadding)
            }
            .background(RRBackgroundView())
            .navigationTitle("Rentory")
            .searchable(text: $filterState.searchText, prompt: "Search records")
            .toolbar {
                ToolbarItem(placement: .rrPrimaryAction) {
                    Button {
                        showCreatePropertyOrUpgradePrompt()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create a record")
                    .accessibilityHint("Creates a new rental record.")
                }

                ToolbarItem(placement: .rrSecondaryAction) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityHint("Opens settings.")
                }
            }
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
    }

    private var filtersPanel: some View {
        RRGlassPanel {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: RRTheme.controlSpacing) {
                    primaryFilterControls
                    clearFiltersButton
                }

                VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                    primaryFilterControls
                    clearFiltersButton
                }
            }
        }
    }

    private var primaryFilterControls: some View {
        HStack(spacing: RRTheme.controlSpacing) {
            Picker("Record type", selection: $filterState.typeFilter) {
                ForEach(PropertyRecordTypeFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.menu)
            .frame(minWidth: 180, alignment: .leading)

            Toggle(isOn: $filterState.showsFavouritesOnly.animation()) {
                Label("Favourites", systemImage: "star.fill")
            }
            .toggleStyle(.button)
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    @ViewBuilder
    private var clearFiltersButton: some View {
        if filterState.hasActiveFilters {
            Button("Clear") {
                clearFilters()
            }
            .buttonStyle(.borderless)
        }
    }

    private func clearFilters() {
        withAnimation(RRTheme.quickAnimation) {
            filterState = PropertyRecordFilterState()
        }
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

#Preview {
    PropertiesListView()
        .modelContainer(
            for: [
                PropertyPack.self,
                RoomRecord.self,
                ChecklistItemRecord.self,
                EvidencePhoto.self,
                DocumentRecord.self,
                TimelineEvent.self,
            ],
            inMemory: true
        )
}
