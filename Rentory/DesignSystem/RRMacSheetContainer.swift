//
//  RRMacSheetContainer.swift
//  Rentory
//
//  Created by OpenAI on 03/05/2026.
//

import SwiftUI

struct RRMacSheetContainer<Content: View>: View {
    var maxWidth: CGFloat = PlatformLayout.preferredDialogWidth
    private let content: Content

    init(
        maxWidth: CGFloat = PlatformLayout.preferredDialogWidth,
        @ViewBuilder content: () -> Content
    ) {
        self.maxWidth = maxWidth
        self.content = content()
    }

    var body: some View {
        Group {
            if PlatformLayout.isMac {
                RRFormContainer(maxWidth: maxWidth) {
                    content
                        .frame(minHeight: PlatformLayout.sheetMinHeight, alignment: .top)
                }
            } else {
                content
            }
        }
    }
}
