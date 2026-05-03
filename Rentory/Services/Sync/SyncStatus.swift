//
//  SyncStatus.swift
//  Rentory
//
//  Created by OpenAI on 02/05/2026.
//

import Foundation

enum SyncStatus: Equatable {
    case available
    case unavailable
    case checking
    case unknown

    var title: String {
        switch self {
        case .available:
            return "Available"
        case .unavailable:
            return "Unavailable"
        case .checking:
            return "Checking"
        case .unknown:
            return "Unknown"
        }
    }
}
