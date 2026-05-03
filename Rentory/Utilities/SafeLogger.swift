//
//  SafeLogger.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

enum SafeLogger {
    // Do not log personal details, notes, photos, document details or rental records.
    // Keep messages generic and developer-focused only.
    static func debug(_ message: StaticString) {
        _ = message
    }

    static func error(_ message: StaticString) {
        _ = message
    }
}
