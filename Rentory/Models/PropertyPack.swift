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
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var isArchived: Bool = false

    @Relationship(deleteRule: .cascade) var rooms: [RoomRecord] = []
    @Relationship(deleteRule: .cascade) var documents: [DocumentRecord] = []
    @Relationship(deleteRule: .cascade) var timelineEvents: [TimelineEvent] = []

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
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isArchived: Bool = false,
        rooms: [RoomRecord] = [],
        documents: [DocumentRecord] = [],
        timelineEvents: [TimelineEvent] = []
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
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.rooms = rooms
        self.documents = documents
        self.timelineEvents = timelineEvents
    }
}

extension PropertyPack {
    var recordType: PropertyRecordType {
        get { PropertyRecordType(rawValue: recordTypeRawValue) ?? .house }
        set { recordTypeRawValue = newValue.rawValue }
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
        let textParts = [
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
        ] + rooms.map(\.name) + rooms.map(\.typeRawValue) + rooms.flatMap(\.checklistItems).map(\.title) + documents.map(\.displayName) + documents.map(\.documentTypeRawValue) + timelineEvents.map(\.title) + timelineEvents.map(\.eventTypeRawValue)

        return textParts
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .lowercased()
    }
}
