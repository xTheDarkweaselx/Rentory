//
//  ViewPlatformModifiers.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

extension View {
    @ViewBuilder
    func rrInlineNavigationTitle() -> some View {
#if os(macOS)
        self
#else
        navigationBarTitleDisplayMode(.inline)
#endif
    }

    @ViewBuilder
    func rrTextInputAutocapitalizationWords() -> some View {
#if os(macOS)
        self
#else
        textInputAutocapitalization(.words)
#endif
    }

    @ViewBuilder
    func rrTextInputAutocapitalizationCharacters() -> some View {
#if os(macOS)
        self
#else
        textInputAutocapitalization(.characters)
#endif
    }

    @ViewBuilder
    func rrTextInputAutocapitalizationNever() -> some View {
#if os(macOS)
        self
#else
        textInputAutocapitalization(.never)
#endif
    }

    @ViewBuilder
    func rrEmailKeyboard() -> some View {
#if os(macOS)
        self
#else
        keyboardType(.emailAddress)
#endif
    }

    /// Hides the navigation bar on platforms that support it. No-op on macOS
    /// (where `.navigationBar` is not an available toolbar placement).
    @ViewBuilder
    func rrHiddenNavigationBar() -> some View {
#if os(macOS)
        self
#else
        toolbar(.hidden, for: .navigationBar)
#endif
    }
}

extension ToolbarItemPlacement {
    static var rrPrimaryAction: ToolbarItemPlacement {
#if os(macOS)
        .automatic
#else
        .topBarTrailing
#endif
    }

    static var rrSecondaryAction: ToolbarItemPlacement {
#if os(macOS)
        .navigation
#else
        .topBarLeading
#endif
    }
}
