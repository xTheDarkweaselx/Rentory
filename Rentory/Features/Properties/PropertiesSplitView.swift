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

    @State private var isShowingCreateProperty = false
    @State private var isShowingSettings = false
    @State private var selectedPropertyID: UUID?

    private var activePropertyPacks: [PropertyPack] {
        propertyPacks.filter { !$0.isArchived }
    }

    private var selectedPropertyPack: PropertyPack? {
        activePropertyPacks.first { $0.id == selectedPropertyID }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedPropertyID) {
                if activePropertyPacks.isEmpty {
                    ContentUnavailableView {
                        Label("No rental records yet", systemImage: "house")
                    } description: {
                        Text("Create your first record when you are ready.")
                    } actions: {
                        Button("Create a record") {
                            isShowingCreateProperty = true
                        }
                    }
                } else {
                    ForEach(activePropertyPacks) { propertyPack in
                        PropertySidebarRow(propertyPack: propertyPack)
                            .tag(propertyPack.id)
                    }
                }
            }
            .navigationTitle("Rentory")
            .toolbar {
                ToolbarItem(placement: .rrPrimaryAction) {
                    Button {
                        isShowingCreateProperty = true
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
            NavigationStack {
                if let selectedPropertyPack {
                    PropertyDashboardView(propertyPack: selectedPropertyPack)
                } else {
                    RREmptyStateView(
                        symbolName: "rectangle.on.rectangle",
                        title: "Choose a rental record",
                        message: "Select a record from the sidebar, or create a new one when you are ready.",
                        buttonTitle: "Create a record"
                    ) {
                        isShowingCreateProperty = true
                    }
                    .padding(32)
                    .navigationTitle("Rentory")
                }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $isShowingCreateProperty) {
            CreatePropertyView()
        }
        .onChange(of: activePropertyPacks.map(\.id)) { _, newIDs in
            if let selectedPropertyID, !newIDs.contains(selectedPropertyID) {
                self.selectedPropertyID = nil
            }
        }
    }
}

private struct PropertySidebarRow: View {
    let propertyPack: PropertyPack

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(propertyPack.nickname)
                .font(RRTypography.headline)
                .foregroundStyle(RRColours.primary)

            if let location = locationSummary {
                Text(location)
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
            }

            Text("Updated \(propertyPack.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(RRTypography.caption)
                .foregroundStyle(RRColours.mutedText)
        }
        .padding(.vertical, 4)
    }

    private var locationSummary: String? {
        [propertyPack.townCity, propertyPack.postcode]
            .compactMap { value in
                let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmedValue?.isEmpty == false ? trimmedValue : nil
            }
            .first
    }
}
