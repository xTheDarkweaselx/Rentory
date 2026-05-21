//
//  RRHaptics.swift
//  Rentory
//
//  Thin wrapper over UIKit's haptic feedback so feature views don't
//  have to know about platform availability. Cheap to call — generator
//  instances are created lazily per call and discarded; for hot paths
//  we keep a prepared instance.
//
//  Platforms:
//    iOS / iPadOS / Mac Catalyst — full haptic feedback via UIKit.
//    macOS native — no-op (AppKit's NSHapticFeedbackManager isn't
//      meaningful without a Force Touch trackpad, and the trackpad path
//      isn't reliable in the iOS-on-Mac runtime we ship with).
//    visionOS — no-op (no haptics on Vision Pro).
//
//  Use sparingly: a haptic on every state change is noise. Reserve for
//  user-initiated commits (save, delete, favourite) where the user
//  expects acknowledgement.
//

import Foundation

#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

enum RRHaptics {
    /// Fired after a user-initiated save succeeds. The system maps this
    /// to a short upward tick on iPhone.
    static func success() {
        #if canImport(UIKit) && !os(watchOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    /// Fired after a user-initiated destructive action succeeds
    /// (delete property, delete tenancy, etc.).
    static func warning() {
        #if canImport(UIKit) && !os(watchOS)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }

    /// Fired after an action fails in a way the user needs to retry.
    static func error() {
        #if canImport(UIKit) && !os(watchOS)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }

    /// Light selection feedback. Use for the favourite-star toggle and
    /// other discrete on/off flips where success/warning would be too
    /// dramatic.
    static func selection() {
        #if canImport(UIKit) && !os(watchOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
}
