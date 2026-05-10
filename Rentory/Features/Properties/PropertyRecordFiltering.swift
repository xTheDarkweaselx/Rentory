//
//  PropertyRecordFiltering.swift
//  Rentory
//
//  Created by OpenAI on 10/05/2026.
//

import Foundation

enum PropertyRecordTypeFilter: String, CaseIterable, Identifiable {
    case all = "All types"
    case house = "House"
    case flat = "Flat"
    case apartment = "Apartment"
    case garage = "Garage"
    case annex = "Annex"
    case other = "Other"

    var id: String { rawValue }

    var recordType: PropertyRecordType? {
        switch self {
        case .all:
            return nil
        case .house:
            return .house
        case .flat:
            return .flat
        case .apartment:
            return .apartment
        case .garage:
            return .garage
        case .annex:
            return .annex
        case .other:
            return .other
        }
    }
}

struct PropertyRecordFilterState: Equatable {
    var searchText = ""
    var typeFilter: PropertyRecordTypeFilter = .all
    var showsFavouritesOnly = false

    var hasActiveFilters: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        typeFilter != .all ||
        showsFavouritesOnly
    }

    func filteredRecords(from records: [PropertyPack]) -> [PropertyPack] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return records.filter { record in
            if showsFavouritesOnly, !record.isFavourite {
                return false
            }

            if let selectedRecordType = typeFilter.recordType, record.recordType != selectedRecordType {
                return false
            }

            guard !trimmedSearchText.isEmpty else {
                return true
            }

            return record.searchableText.contains(trimmedSearchText)
        }
    }
}
