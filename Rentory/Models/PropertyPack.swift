//
//  PropertyPack.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation
import SwiftData

@Model
final class PropertyPack {
    var id: UUID = UUID()
    var nickname: String = ""
    var recordTypeRawValue: String = PropertyRecordType.house.rawValue
    var isFavourite: Bool = false
    var addressLine1: String?
    var addressLine2: String?
    var townCity: String?
    var postcode: String?
    var buildingName: String?
    var spaceIdentifier: String?
    var floorLevel: String?
    var mainPropertyName: String?
    var accessDetails: String?
    var tenancyStartDate: Date?
    var tenancyEndDate: Date?
    var landlordOrAgentName: String?
    var landlordOrAgentEmail: String?
    var depositSchemeName: String?
    var depositReference: String?
    var notes: String?
    var manualTenancyStageRawValue: String?
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var isArchived: Bool = false

    @Relationship(deleteRule: .cascade) var rooms: [RoomRecord] = []
    @Relationship(deleteRule: .cascade) var documents: [DocumentRecord] = []
    @Relationship(deleteRule: .cascade) var timelineEvents: [TimelineEvent] = []
    @Relationship(deleteRule: .cascade) var reminders: [Reminder] = []

    init(
        id: UUID = UUID(),
        nickname: String,
        recordType: PropertyRecordType = .house,
        isFavourite: Bool = false,
        addressLine1: String? = nil,
        addressLine2: String? = nil,
        townCity: String? = nil,
        postcode: String? = nil,
        buildingName: String? = nil,
        spaceIdentifier: String? = nil,
        floorLevel: String? = nil,
        mainPropertyName: String? = nil,
        accessDetails: String? = nil,
        tenancyStartDate: Date? = nil,
        tenancyEndDate: Date? = nil,
        landlordOrAgentName: String? = nil,
        landlordOrAgentEmail: String? = nil,
        depositSchemeName: String? = nil,
        depositReference: String? = nil,
        notes: String? = nil,
        manualTenancyStageRawValue: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isArchived: Bool = false,
        rooms: [RoomRecord] = [],
        documents: [DocumentRecord] = [],
        timelineEvents: [TimelineEvent] = [],
        reminders: [Reminder] = []
    ) {
        self.id = id
        self.nickname = nickname
        self.recordTypeRawValue = recordType.rawValue
        self.isFavourite = isFavourite
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.townCity = townCity
        self.postcode = postcode
        self.buildingName = buildingName
        self.spaceIdentifier = spaceIdentifier
        self.floorLevel = floorLevel
        self.mainPropertyName = mainPropertyName
        self.accessDetails = accessDetails
        self.tenancyStartDate = tenancyStartDate
        self.tenancyEndDate = tenancyEndDate
        self.landlordOrAgentName = landlordOrAgentName
        self.landlordOrAgentEmail = landlordOrAgentEmail
        self.depositSchemeName = depositSchemeName
        self.depositReference = depositReference
        self.notes = notes
        self.manualTenancyStageRawValue = manualTenancyStageRawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.rooms = rooms
        self.documents = documents
        self.timelineEvents = timelineEvents
        self.reminders = reminders
    }
}

extension PropertyPack {
    var recordType: PropertyRecordType {
        get { PropertyRecordType(rawValue: recordTypeRawValue) ?? .house }
        set { recordTypeRawValue = newValue.rawValue }
    }

    var manualTenancyStage: TenancyStage? {
        get { manualTenancyStageRawValue.flatMap(TenancyStage.init(rawValue:)) }
        set { manualTenancyStageRawValue = newValue?.rawValue }
    }

    var derivedTenancyStage: TenancyStage? {
        TenancyStage.derive(from: tenancyStartDate, to: tenancyEndDate)
    }

    /// The stage the UI should display. Prefers a manual override; falls
    /// back to the date-derived stage; defaults to .moveIn for fresh
    /// records with no dates yet.
    var effectiveTenancyStage: TenancyStage {
        manualTenancyStage ?? derivedTenancyStage ?? .moveIn
    }

    /// True when the user has set a manual stage that disagrees with the
    /// stage their tenancy dates would imply. Drives the nudge banner.
    var hasStageMismatch: Bool {
        guard let manual = manualTenancyStage, let derived = derivedTenancyStage else { return false }
        return manual != derived
    }

    var recordIconName: String {
        recordType.iconName
    }

    var typeDetailSummary: String? {
        let values = [
            buildingName,
            spaceIdentifier,
            floorLevel.map { "Floor \($0)" },
            mainPropertyName,
            accessDetails,
        ]

        let trimmedValues = values.compactMap { value -> String? in
            guard let value else { return nil }
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedValue.isEmpty ? nil : trimmedValue
        }

        guard !trimmedValues.isEmpty else {
            return nil
        }

        return trimmedValues.joined(separator: " · ")
    }

    var searchableText: String {
        var components: [String] = []

        let optionalFields: [String?] = [
            nickname,
            recordType.rawValue,
            addressLine1,
            addressLine2,
            townCity,
            postcode,
            buildingName,
            spaceIdentifier,
            floorLevel,
            mainPropertyName,
            accessDetails,
            landlordOrAgentName,
            landlordOrAgentEmail,
            depositSchemeName,
            depositReference,
            notes,
        ]
        components.append(contentsOf: optionalFields.compactMap { $0 })

        components.append(contentsOf: rooms.map(\.name))
        components.append(contentsOf: rooms.map(\.typeRawValue))
        components.append(contentsOf: rooms.flatMap(\.checklistItems).map(\.title))
        components.append(contentsOf: rooms.flatMap(\.checklistItems).flatMap(\.comments).map(\.body))
        components.append(contentsOf: documents.map(\.displayName))
        components.append(contentsOf: documents.map(\.documentTypeRawValue))
        components.append(contentsOf: timelineEvents.map(\.title))
        components.append(contentsOf: timelineEvents.map(\.eventTypeRawValue))
        components.append(contentsOf: reminders.map(\.title))
        components.append(contentsOf: reminders.compactMap { $0.notes })

        return components
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .lowercased()
    }
}
