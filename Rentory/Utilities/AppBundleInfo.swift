//
//  AppBundleInfo.swift
//  Rentory
//
//  Single source of truth for the app version / build strings that
//  multiple surfaces want to render (Settings, the feedback footer,
//  backup metadata). Reads from `Bundle.main` exactly once at first
//  access; cached for the lifetime of the process via `static let`.
//

import Foundation

enum AppBundleInfo {
    /// Short marketing version (e.g. "1.2") read from
    /// `CFBundleShortVersionString`. `nil` only if the bundle is
    /// missing the key (shouldn't happen in shipping builds).
    static let shortVersion: String? =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

    /// Build number (e.g. "42") read from `CFBundleVersion`.
    static let buildNumber: String? =
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

    /// Pretty "Version X.Y (Z)" string ready for direct display. `nil`
    /// only when `shortVersion` itself is unavailable.
    static let displayString: String? = {
        guard let version = shortVersion else { return nil }
        if let build = buildNumber {
            return "Version \(version) (\(build))"
        }
        return "Version \(version)"
    }()
}
