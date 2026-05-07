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
