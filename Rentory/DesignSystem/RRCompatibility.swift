//
//  RRCompatibility.swift
//  Rentory
//
//  Small availability shims so the app can deploy back to iOS 17 / macOS 14
//  while keeping the newest look on iOS 26 / macOS 26. Each helper applies
//  the latest API when the OS supports it and a visually-equivalent fallback
//  otherwise — the iOS 26 / macOS 26 appearance is unchanged.
//

import SwiftUI

extension View {
    /// Liquid Glass button style on iOS 26 / macOS 26; the closest bordered
    /// style on older systems so the button still reads as a primary or
    /// secondary action.
    @ViewBuilder
    func rrGlassButtonStyle(prominent: Bool) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            if prominent {
                buttonStyle(.glassProminent)
            } else {
                buttonStyle(.glass)
            }
        } else {
            if prominent {
                buttonStyle(.borderedProminent)
            } else {
                buttonStyle(.bordered)
            }
        }
    }

    /// macOS window-chrome refinements (hidden toolbar background and removed
    /// window title) that only exist on macOS 15+. Applied when available,
    /// and a no-op otherwise — including on non-macOS platforms.
    @ViewBuilder
    func rrMacWindowChrome() -> some View {
        #if os(macOS)
        if #available(macOS 15.0, *) {
            toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .toolbar(removing: .title)
        } else {
            self
        }
        #else
        self
        #endif
    }
}
