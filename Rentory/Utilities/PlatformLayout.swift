//
//  PlatformLayout.swift
//  Rentory
//
//  Created by OpenAI on 03/05/2026.
//

import SwiftUI

enum PlatformLayout {
    #if os(macOS)
    static let isMac = true
    #elseif targetEnvironment(macCatalyst)
    static let isMac = true
    #else
    static let isMac = false
    #endif

    #if os(iOS)
    static let isPad = UIDevice.current.userInterfaceIdiom == .pad
    static let isPhone = UIDevice.current.userInterfaceIdiom == .phone
    #else
    static let isPad = false
    static let isPhone = false
    #endif

    static let preferredFormMaxWidth: CGFloat = isMac ? 1120 : (isPad ? 1000 : .infinity)
    static let preferredDialogWidth: CGFloat = isMac ? 760 : (isPad ? 700 : .infinity)
    static let preferredContentMaxWidth: CGFloat = isMac ? 980 : (isPad ? 860 : .infinity)
    static let preferredRecordDialogWidth: CGFloat = isMac ? 1120 : (isPad ? 1000 : .infinity)
    static let preferredSettingsDialogWidth: CGFloat = isMac ? 1180 : (isPad ? 1000 : .infinity)
    static let preferredSidebarMinWidth: CGFloat = isMac ? 280 : 250
    static let preferredSidebarIdealWidth: CGFloat = isMac ? 320 : 280
    static let preferredSidebarMaxWidth: CGFloat = isMac ? 360 : 320

    static let preferredWindowWidth: CGFloat = 1220
    static let preferredWindowHeight: CGFloat = 820
    static let minimumWindowWidth: CGFloat = 1100
    static let minimumWindowHeight: CGFloat = 760

    static func prefersSplitView(for sizeClass: UserInterfaceSizeClass?) -> Bool {
        isMac || sizeClass == .regular
    }

    static var formHorizontalPadding: CGFloat {
        isMac ? 32 : 20
    }

    static var formVerticalPadding: CGFloat {
        isMac ? 28 : 20
    }

    static var sheetMinHeight: CGFloat? {
        isMac ? 560 : nil
    }

    static var prefersFooterButtons: Bool {
        isMac || isPad
    }

    static func responsiveColumnCount(for width: CGFloat) -> Int {
        if width < 720 {
            return 1
        } else if width <= 1050 {
            return 2
        } else {
            return 3
        }
    }
}
