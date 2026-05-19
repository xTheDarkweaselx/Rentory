//
//  Tenant.swift
//  Rentory
//
//  Created by Adam Ibrahim on 19/05/2026.
//

import Foundation
import SwiftData

@Model
final class Tenant {
    var id: UUID = UUID()
    var name: String = ""
    var email: String?
    var phone: String?
    var sortOrder: Int = 0
    var notes: String?
    var createdAt: Date = Date.now

    init(
        id: UUID = UUID(),
        name: String,
        email: String? = nil,
        phone: String? = nil,
        sortOrder: Int = 0,
        notes: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.sortOrder = sortOrder
        self.notes = notes
        self.createdAt = createdAt
    }
}
