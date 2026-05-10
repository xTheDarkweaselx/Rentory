//
//  ExportOptions.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

struct ExportOptions: Codable, Equatable, Sendable {
    var includePropertyName: Bool
    var includeTownOrPostcode: Bool
    var includeFullAddress: Bool
    var includeTenancyDates: Bool
    var includeLandlordOrAgentDetails: Bool
    var includeDepositDetails: Bool
    var includeRooms: Bool
    var includeChecklistNotes: Bool
    var includePhotos: Bool
    var includeDocumentsList: Bool
    var includeTimeline: Bool
    var includeDisclaimer: Bool

    init(
        includePropertyName: Bool = true,
        includeTownOrPostcode: Bool = true,
        includeFullAddress: Bool = false,
        includeTenancyDates: Bool = true,
        includeLandlordOrAgentDetails: Bool = false,
        includeDepositDetails: Bool = false,
        includeRooms: Bool = true,
        includeChecklistNotes: Bool = true,
        includePhotos: Bool = true,
        includeDocumentsList: Bool = true,
        includeTimeline: Bool = true,
        includeDisclaimer: Bool = true
    ) {
        self.includePropertyName = includePropertyName
        self.includeTownOrPostcode = includeTownOrPostcode
        self.includeFullAddress = includeFullAddress
        self.includeTenancyDates = includeTenancyDates
        self.includeLandlordOrAgentDetails = includeLandlordOrAgentDetails
        self.includeDepositDetails = includeDepositDetails
        self.includeRooms = includeRooms
        self.includeChecklistNotes = includeChecklistNotes
        self.includePhotos = includePhotos
        self.includeDocumentsList = includeDocumentsList
        self.includeTimeline = includeTimeline
        self.includeDisclaimer = includeDisclaimer ? true : true
    }
}
