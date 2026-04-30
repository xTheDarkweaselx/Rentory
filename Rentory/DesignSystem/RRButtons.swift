//
//  RRButtons.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct RRPrimaryButton: View {
    let title: String
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isDisabled)
    }
}

struct RRSecondaryButton: View {
    let title: String
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(isDisabled)
    }
}

struct RRDestructiveButton: View {
    let title: String
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(title, role: .destructive, action: action)
            .buttonStyle(.bordered)
            .tint(RRColours.danger)
            .controlSize(.large)
            .disabled(isDisabled)
    }
}
