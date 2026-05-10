//
//  EditPropertyView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI

struct EditPropertyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let propertyPack: PropertyPack

    @State private var nickname: String
    @State private var recordType: PropertyRecordType
    @State private var isFavourite: Bool
    @State private var buildingName: String
    @State private var spaceIdentifier: String
    @State private var floorLevel: String
    @State private var mainPropertyName: String
    @State private var accessDetails: String
    @State private var addressLine1: String
    @State private var addressLine2: String
    @State private var townCity: String
    @State private var postcode: String
    @State private var hasTenancyStartDate: Bool
    @State private var tenancyStartDate: Date
    @State private var hasTenancyEndDate: Bool
    @State private var tenancyEndDate: Date
    @State private var landlordOrAgentName: String
    @State private var landlordOrAgentEmail: String
    @State private var depositSchemeName: String
    @State private var depositReference: String
    @State private var notes: String
    @State private var validationMessage: String?
    @State private var isShowingArchiveConfirmation = false
    @State private var isShowingDeleteConfirmation = false
    @State private var deletionAlertContent: RRAlertContent?

    let onDelete: (() -> Void)?

    private let deletionService = RentoryDataDeletionService()

    init(propertyPack: PropertyPack, onDelete: (() -> Void)? = nil) {
        self.propertyPack = propertyPack
        self.onDelete = onDelete
        _nickname = State(initialValue: propertyPack.nickname)
        _recordType = State(initialValue: propertyPack.recordType)
        _isFavourite = State(initialValue: propertyPack.isFavourite)
        _buildingName = State(initialValue: propertyPack.buildingName ?? "")
        _spaceIdentifier = State(initialValue: propertyPack.spaceIdentifier ?? "")
        _floorLevel = State(initialValue: propertyPack.floorLevel ?? "")
        _mainPropertyName = State(initialValue: propertyPack.mainPropertyName ?? "")
        _accessDetails = State(initialValue: propertyPack.accessDetails ?? "")
        _addressLine1 = State(initialValue: propertyPack.addressLine1 ?? "")
        _addressLine2 = State(initialValue: propertyPack.addressLine2 ?? "")
        _townCity = State(initialValue: propertyPack.townCity ?? "")
        _postcode = State(initialValue: propertyPack.postcode ?? "")
        _hasTenancyStartDate = State(initialValue: propertyPack.tenancyStartDate != nil)
        _tenancyStartDate = State(initialValue: propertyPack.tenancyStartDate ?? .now)
        _hasTenancyEndDate = State(initialValue: propertyPack.tenancyEndDate != nil)
        _tenancyEndDate = State(initialValue: propertyPack.tenancyEndDate ?? .now)
        _landlordOrAgentName = State(initialValue: propertyPack.landlordOrAgentName ?? "")
        _landlordOrAgentEmail = State(initialValue: propertyPack.landlordOrAgentEmail ?? "")
        _depositSchemeName = State(initialValue: propertyPack.depositSchemeName ?? "")
        _depositReference = State(initialValue: propertyPack.depositReference ?? "")
        _notes = State(initialValue: propertyPack.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            PropertyFormView(
                title: "Edit record",
                subtitle: "Update your record when details change.",
                systemImage: recordType.iconName,
                validationMessage: validationMessage,
                recordType: $recordType,
                isFavourite: $isFavourite,
                nickname: $nickname,
                buildingName: $buildingName,
                spaceIdentifier: $spaceIdentifier,
                floorLevel: $floorLevel,
                mainPropertyName: $mainPropertyName,
                accessDetails: $accessDetails,
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
                filesTabSummary
            } footer: {
                footerButtons
            } manageSection: {
                RRDestructiveButton(title: "Archive record") {
                    isShowingArchiveConfirmation = true
                }
                .accessibilityHint("Keeps this record out of your active list.")

                RRDestructiveButton(title: "Delete this record") {
                    isShowingDeleteConfirmation = true
                }
                .accessibilityHint("Removes this record, including its photos and documents, from this device.")
            }
            .navigationTitle("Edit record")
            .rrInlineNavigationTitle()
            .rrConfirmationDialog(DialogCopy.archiveRecord, isPresented: $isShowingArchiveConfirmation) {
                withAnimation(RRTheme.quickAnimation) {
                    propertyPack.isArchived = true
                    propertyPack.updatedAt = .now
                    dismiss()
                }
            }
            .rrConfirmationDialog(DialogCopy.deleteRentalRecord, isPresented: $isShowingDeleteConfirmation) {
                deleteRecord()
            }
            .alert(item: $deletionAlertContent) { content in
                Alert(
                    title: Text(content.title),
                    message: Text(content.message),
                    dismissButton: .cancel(Text(content.buttonTitle))
                )
            }
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

                        RRPrimaryButton(title: "Save changes") {
                            saveChanges()
                        }
                        .frame(width: 150)
                    }
                } else {
                    VStack(spacing: RRTheme.controlSpacing) {
                        RRPrimaryButton(title: "Save changes") {
                            saveChanges()
                        }

                        RRSecondaryButton(title: "Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private var filesTabSummary: some View {
        RRResponsiveFormGrid(items: [
            RRResponsiveFormGridItem {
                RRGlassPanel {
                    VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                        Text("Files")
                            .font(RRTypography.headline)
                            .foregroundStyle(RRColours.primary)

                        Text("Documents and photos already added to this record stay available here.")
                            .font(RRTypography.body)
                            .foregroundStyle(RRColours.mutedText)
                    }
                }
            },
            RRResponsiveFormGridItem {
                RRGlassPanel {
                    VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                        Text("Current files")
                            .font(RRTypography.headline)
                            .foregroundStyle(RRColours.primary)

                        Text("\(propertyPack.documents.count) document\(propertyPack.documents.count == 1 ? "" : "s")")
                            .font(RRTypography.body)
                        Text("\(propertyPack.rooms.flatMap(\.checklistItems).flatMap(\.photos).count) photo\(propertyPack.rooms.flatMap(\.checklistItems).flatMap(\.photos).count == 1 ? "" : "s")")
                            .font(RRTypography.body)
                            .foregroundStyle(RRColours.mutedText)
                    }
                }
            },
        ])
    }

    private func saveChanges() {
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

        propertyPack.nickname = trimmedNickname
        propertyPack.recordType = recordType
        propertyPack.isFavourite = isFavourite
        propertyPack.addressLine1 = optionalText(addressLine1)
        propertyPack.addressLine2 = optionalText(addressLine2)
        propertyPack.townCity = optionalText(townCity)
        propertyPack.postcode = optionalText(postcode)
        propertyPack.buildingName = optionalText(buildingName)
        propertyPack.spaceIdentifier = optionalText(spaceIdentifier)
        propertyPack.floorLevel = optionalText(floorLevel)
        propertyPack.mainPropertyName = optionalText(mainPropertyName)
        propertyPack.accessDetails = optionalText(accessDetails)
        propertyPack.tenancyStartDate = hasTenancyStartDate ? tenancyStartDate : nil
        propertyPack.tenancyEndDate = hasTenancyEndDate ? tenancyEndDate : nil
        propertyPack.landlordOrAgentName = optionalText(landlordOrAgentName)
        propertyPack.landlordOrAgentEmail = trimmedEmail.isEmpty ? nil : trimmedEmail
        propertyPack.depositSchemeName = optionalText(depositSchemeName)
        propertyPack.depositReference = optionalText(depositReference)
        propertyPack.notes = optionalText(notes)
        propertyPack.updatedAt = .now

        dismiss()
    }

    private var isValidDateRange: Bool {
        guard hasTenancyStartDate, hasTenancyEndDate else {
            return true
        }

        return tenancyEndDate >= tenancyStartDate
    }

    private func deleteRecord() {
        do {
            try deletionService.deletePropertyPack(propertyPack, context: modelContext)
            dismiss()
            onDelete?()
        } catch let error as RentoryDataDeletionError {
            deletionAlertContent = RRAlertContent(
                title: UserFacingError.recordCouldNotBeDeleted.title,
                message: "\(error.errorDescription ?? "This record could not be deleted.") Please try again."
            )
        } catch {
            deletionAlertContent = RRAlertContent(error: .recordCouldNotBeDeleted)
        }
    }
}
