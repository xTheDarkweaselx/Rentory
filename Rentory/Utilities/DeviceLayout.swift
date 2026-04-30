//
//  DeviceLayout.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

enum DeviceLayout {
    static func isRegularWidth(_ sizeClass: UserInterfaceSizeClass?) -> Bool {
        sizeClass == .regular
    }

    static func contentWidth(for sizeClass: UserInterfaceSizeClass?, maximum: CGFloat) -> CGFloat? {
        isRegularWidth(sizeClass) ? maximum : nil
    }
}
