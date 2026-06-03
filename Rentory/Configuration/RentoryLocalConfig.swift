//
//  RentoryLocalConfig.swift
//  Rentory
//
//  LOCAL, NOT TRACKED IN GIT.
//
//  This file holds per-developer constants that shouldn't be visible
//  to the public repo — most importantly the email address that
//  end-user feedback submissions get sent to. A `.example` companion
//  ships with the repo (`RentoryLocalConfig.example.swift`) so a
//  fresh clone knows what shape to recreate.
//

import Foundation

enum RentoryLocalConfig {
    /// Inbox that "Send feedback" submissions are addressed to. Used
    /// to build the `mailto:` URL when the user taps "Open in Mail".
    static let feedbackRecipientEmail = "adam_ib2006@outlook.com"
}
