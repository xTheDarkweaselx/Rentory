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
    @State private var isShowingCreateProperty = false
    @State private var isShowingSettings = false

    private var activePropertyPacks: [PropertyPack] {
        propertyPacks.filter { !$0.isArchived }
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
                            buttonTitle: "Create a record"
                        ) {
                            isShowingCreateProperty = true
                        }
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
                .padding(20)
            }
            .background(RRColours.groupedBackground.ignoresSafeArea())
            .navigationTitle("Rentory")
            .toolbar {
                ToolbarItem(placement: .rrPrimaryAction) {
                    Button {
                        isShowingCreateProperty = true
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
        }
        .sheet(isPresented: $isShowingCreateProperty) {
            CreatePropertyView()
        }
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
