//
//  RRDialogContent.swift
//  Rentory
//
//  Created by Adam Ibrahim on 01/05/2026.
//

import SwiftUI

struct RRDialogContent: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let confirmTitle: String
    let cancelTitle: String
    let confirmRole: ButtonRole?

    init(
        title: String,
        message: String,
        confirmTitle: String,
        cancelTitle: String = "Cancel",
        confirmRole: ButtonRole? = nil
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
        self.confirmRole = confirmRole
    }
}
