//
//  RRMacSheetContainer.swift
//  Rentory
//
//  Created by OpenAI on 03/05/2026.
//

import SwiftUI

private struct RRUsesEmbeddedNavigationLayoutKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var rrUsesEmbeddedNavigationLayout: Bool {
        get { self[RRUsesEmbeddedNavigationLayoutKey.self] }
        set { self[RRUsesEmbeddedNavigationLayoutKey.self] = newValue }
    }
}

extension View {
    func rrUsesEmbeddedNavigationLayout(_ value: Bool = true) -> some View {
        environment(\.rrUsesEmbeddedNavigationLayout, value)
    }
}

private struct RREmbeddedLeafDismissKey: EnvironmentKey {
    static let defaultValue: (@MainActor () -> Void)? = nil
}

extension EnvironmentValues {
    /// A "go back" action a Settings leaf can call to dismiss itself when
    /// it's shown inside the wide embedded panel — where the standard
    /// `@Environment(\.dismiss)` has no sheet or navigation push to act
    /// on. The wide layout injects this (it clears its `selectedDetail`);
    /// standalone presentations leave it `nil`, so the leaf falls back to
    /// the normal `dismiss()`.
    var rrEmbeddedLeafDismiss: (@MainActor () -> Void)? {
        get { self[RREmbeddedLeafDismissKey.self] }
        set { self[RREmbeddedLeafDismissKey.self] = newValue }
    }
}

struct RRMacSheetContainer<Content: View>: View {
    var preferredWidth: CGFloat = PlatformLayout.preferredDialogWidth
    var preferredHeight: CGFloat? = PlatformLayout.sheetMinHeight
    private let content: Content

    init(
        maxWidth: CGFloat = PlatformLayout.preferredDialogWidth,
        minHeight: CGFloat? = PlatformLayout.sheetMinHeight,
        @ViewBuilder content: () -> Content
    ) {
        self.preferredWidth = maxWidth
        self.preferredHeight = minHeight
        self.content = content()
    }

    var body: some View {
        Group {
            if PlatformLayout.isMac || PlatformLayout.isPad {
                RRFormContainer(maxWidth: preferredWidth) {
                    content
                        .frame(minHeight: preferredHeight, alignment: .top)
                        .frame(maxWidth: preferredWidth, alignment: .topLeading)
                }
            } else {
                content
            }
        }
    }
}
