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
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var isShowingCreateProperty = false
    @State private var isShowingSettings = false
    @State private var upgradePromptContent: UpgradePromptContent?

    private var activePropertyPacks: [PropertyPack] {
        propertyPacks.filter { !$0.isArchived }
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

                    if activePropertyPacks.isEmpty {
                        RREmptyStateView(
                            symbolName: "house",
                            title: "No rental records yet",
                            message: "Create your first record when you are ready.",
                            buttonTitle: "Create a record",
                            buttonAction: showCreatePropertyOrUpgradePrompt
                        )
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(activePropertyPacks) { propertyPack in
                                NavigationLink {
                                    PropertyDashboardView(propertyPack: propertyPack)
                                } label: {
                                    PropertySummaryCard(propertyPack: propertyPack, showsLastUpdated: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(RRTheme.screenPadding)
            }
            .background(RRBackgroundView())
            .navigationTitle("Rentory")
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
#if DEBUG
        DemoModeSettings.matchesDemoRecord(propertyPack)
#else
        false
#endif
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
