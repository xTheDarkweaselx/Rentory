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
    var id: UUID
    var nickname: String
    var addressLine1: String?
    var addressLine2: String?
    var townCity: String?
    var postcode: String?
    var tenancyStartDate: Date?
    var tenancyEndDate: Date?
    var landlordOrAgentName: String?
    var landlordOrAgentEmail: String?
    var depositSchemeName: String?
    var depositReference: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    @Relationship(deleteRule: .cascade) var rooms: [RoomRecord]
    @Relationship(deleteRule: .cascade) var documents: [DocumentRecord]
    @Relationship(deleteRule: .cascade) var timelineEvents: [TimelineEvent]

    init(
        id: UUID = UUID(),
        nickname: String,
        addressLine1: String? = nil,
        addressLine2: String? = nil,
        townCity: String? = nil,
        postcode: String? = nil,
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
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.townCity = townCity
        self.postcode = postcode
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
