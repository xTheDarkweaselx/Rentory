//
//  PrivacyNoticeContent.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation

struct PrivacyNoticeSection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}

enum PrivacyNoticeContent {
    static let sections: [PrivacyNoticeSection] = [
        PrivacyNoticeSection(
            title: "Private by design",
            body: "Your rental records stay on your device by default. You do not need an account to use Rentory."
        ),
        PrivacyNoticeSection(
            title: "Your records, your choice",
            body: "When you create a report, you choose what to include and where to share it."
        ),
        PrivacyNoticeSection(
            title: "Helpful, but not advice",
            body: "Rentory helps you keep your own records organised. It does not give legal, financial or tenancy advice."
        ),
        PrivacyNoticeSection(
            title: "Only add what you need",
            body: "You only need a property name to get started. Details like the address, landlord, agent and deposit reference are optional."
        )
    ]
}
