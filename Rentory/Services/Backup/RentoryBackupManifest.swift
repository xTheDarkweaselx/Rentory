//
//  RentoryBackupManifest.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import Foundation

struct RentoryBackupManifest: Codable, Equatable {
    let backupVersion: Int
    let appName: String
    let createdAt: Date
    let appVersion: String?
    let propertyCount: Int
    let roomCount: Int
    let photoCount: Int
    let documentCount: Int
    let timelineEventCount: Int
}
