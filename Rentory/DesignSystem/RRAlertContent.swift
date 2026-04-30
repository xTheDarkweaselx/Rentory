//
//  RRAlertContent.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

struct RRAlertContent: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let buttonTitle: String

    init(title: String, message: String, buttonTitle: String = "OK") {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
    }

    init(error: UserFacingError) {
        self.title = error.title
        self.message = error.message
        self.buttonTitle = error.recoveryActionTitle ?? "OK"
    }
}
