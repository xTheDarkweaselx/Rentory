//
//  PlatformImageDisplay.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

#if canImport(UIKit)
import UIKit

extension Image {
    init(rrImage: UIImage) {
        self = Image(uiImage: rrImage)
    }
}
#elseif canImport(AppKit)
import AppKit

extension Image {
    init(rrImage: UIImage) {
        self = Image(nsImage: rrImage)
    }
}
#endif
