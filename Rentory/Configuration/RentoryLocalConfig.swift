//
//  RentoryLocalConfig.swift
//  Rentory
//
//  App-level configuration constants. Committed to the repo so clean
//  checkouts (Xcode Cloud, fresh clones, CI) build with no extra setup.
//

import Foundation

enum RentoryLocalConfig {
    /// Inbox that "Send feedback" submissions are addressed to. Used to
    /// build the `mailto:` URL when the user taps "Open in Mail".
    static let feedbackRecipientEmail = "adam_ib2006@outlook.com"
}
