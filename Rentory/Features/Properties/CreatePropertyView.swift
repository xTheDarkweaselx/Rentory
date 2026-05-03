//
//  CreatePropertyView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI

struct CreatePropertyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @Query private var propertyPacks: [PropertyPack]

    @State private var nickname = ""
    @State private var addressLine1 = ""
    @State private var addressLine2 = ""
    @State private var townCity = ""
    @State private var postcode = ""
    @State private var hasTenancyStartDate = false
    @State private var tenancyStartDate = Date()
    @State private var hasTenancyEndDate = false
    @State private var tenancyEndDate = Date()
    @State private var landlordOrAgentName = ""
    @State private var landlordOrAgentEmail = ""
    @State private var depositSchemeName = ""
    @State private var depositReference = ""
    @State private var notes = ""
    @State private var validationMessage: String?
    @State private var upgradePromptContent: UpgradePromptContent?

    var body: some View {
        NavigationStack {
            PropertyFormView(
                title: "Create a record",
                subtitle: "Start with a property name. You can add more details now or later.",
                systemImage: "house",
                validationMessage: validationMessage,
                nickname: $nickname,
                addressLine1: $addressLine1,
                addressLine2: $addressLine2,
                townCity: $townCity,
                postcode: $postcode,
                hasTenancyStartDate: $hasTenancyStartDate,
                tenancyStartDate: $tenancyStartDate,
                hasTenancyEndDate: $hasTenancyEndDate,
                tenancyEndDate: $tenancyEndDate,
                landlordOrAgentName: $landlordOrAgentName,
                landlordOrAgentEmail: $landlordOrAgentEmail,
                depositSchemeName: $depositSchemeName,
                depositReference: $depositReference,
                notes: $notes
            ) {
                footerButtons
            }
            .navigationTitle("Create a record")
            .rrInlineNavigationTitle()
        }
        .sheet(item: $upgradePromptContent) { content in
            LimitReachedView(title: content.title, message: content.message)
        }
    }

    private var footerButtons: some View {
        RRGlassPanel {
            Group {
                if PlatformLayout.prefersFooterButtons {
                    HStack(spacing: RRTheme.controlSpacing) {
                        Spacer()
                        RRSecondaryButton(title: "Cancel") {
                            dismiss()
                        }
                        .frame(width: 150)

                        RRPrimaryButton(title: "Save") {
                            saveProperty()
                        }
                        .frame(width: 150)
                    }
                } else {
                    VStack(spacing: RRTheme.controlSpacing) {
                        RRPrimaryButton(title: "Save") {
                            saveProperty()
                        }

                        RRSecondaryButton(title: "Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func saveProperty() {
        let trimmedNickname = trimmed(nickname)
        let trimmedEmail = trimmed(landlordOrAgentEmail)

        guard !trimmedNickname.isEmpty else {
            validationMessage = "Add a property name to continue."
            return
        }

        guard isValidDateRange else {
            validationMessage = "Check the tenancy dates. The end date can’t be before the start date."
            return
        }

        guard trimmedEmail.isEmpty || isLightweightEmail(trimmedEmail) else {
            validationMessage = "Check the email address or leave it blank."
            return
        }

        guard FeatureAccessService.canCreateProperty(
            currentPropertyCount: propertyPacks.count,
            isUnlocked: entitlementManager.isUnlocked
        ) else {
            upgradePromptContent = FeatureAccessService.propertyLimitPrompt
            return
        }

        let propertyPack = PropertyPack(
            nickname: trimmedNickname,
            addressLine1: optionalText(addressLine1),
            addressLine2: optionalText(addressLine2),
            townCity: optionalText(townCity),
            postcode: optionalText(postcode),
            tenancyStartDate: hasTenancyStartDate ? tenancyStartDate : nil,
            tenancyEndDate: hasTenancyEndDate ? tenancyEndDate : nil,
            landlordOrAgentName: optionalText(landlordOrAgentName),
            landlordOrAgentEmail: trimmedEmail.isEmpty ? nil : trimmedEmail,
            depositSchemeName: optionalText(depositSchemeName),
            depositReference: optionalText(depositReference),
            notes: optionalText(notes),
            createdAt: .now,
            updatedAt: .now
        )

        modelContext.insert(propertyPack)
        dismiss()
    }

    private var isValidDateRange: Bool {
        guard hasTenancyStartDate, hasTenancyEndDate else {
            return true
        }

        return tenancyEndDate >= tenancyStartDate
    }
}
