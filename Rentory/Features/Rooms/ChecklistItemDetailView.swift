//
//  ChecklistItemDetailView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftUI

struct ChecklistItemDetailView: View {
    let checklistItem: ChecklistItemRecord

    @State private var isShowingAddPhotoFlow = false

    private var moveInPhotos: [EvidencePhoto] {
        checklistItem.photos.filter { $0.evidencePhase == .moveIn }
    }

    private var duringTenancyPhotos: [EvidencePhoto] {
        checklistItem.photos.filter { $0.evidencePhase == .duringTenancy }
    }

    private var moveOutPhotos: [EvidencePhoto] {
        checklistItem.photos.filter { $0.evidencePhase == .moveOut }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(checklistItem.title)
                            .font(RRTypography.title)
                            .foregroundStyle(RRColours.primary)

                        ViewThatFits {
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Move-in")
                                        .font(RRTypography.caption)
                                        .foregroundStyle(RRColours.mutedText)

                                    RRConditionBadge(condition: checklistItem.moveInCondition)
                                }

                                Spacer(minLength: 12)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Move-out")
                                        .font(RRTypography.caption)
                                        .foregroundStyle(RRColours.mutedText)

                                    RRConditionBadge(condition: checklistItem.moveOutCondition)
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Move-in")
                                        .font(RRTypography.caption)
                                        .foregroundStyle(RRColours.mutedText)

                                    RRConditionBadge(condition: checklistItem.moveInCondition)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Move-out")
                                        .font(RRTypography.caption)
                                        .foregroundStyle(RRColours.mutedText)

                                    RRConditionBadge(condition: checklistItem.moveOutCondition)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    RRSectionHeader(title: "Photos")

                    if checklistItem.photos.isEmpty {
                        RRCard {
                            Text("Add photos to keep a clearer record of this item.")
                                .font(RRTypography.body)
                                .foregroundStyle(RRColours.mutedText)
                        }
                    }

                    RRPrimaryButton(title: "Add a photo") {
                        isShowingAddPhotoFlow = true
                    }
                    .accessibilityHint("Adds a photo to this checklist item.")

                    EvidencePhotoGridView(title: "Move-in", photos: moveInPhotos)
                    EvidencePhotoGridView(title: "During tenancy", photos: duringTenancyPhotos)
                    EvidencePhotoGridView(title: "Move-out", photos: moveOutPhotos)
                }
            }
            .padding(20)
        }
        .background(RRColours.groupedBackground.ignoresSafeArea())
        .navigationTitle(checklistItem.title)
        .rrInlineNavigationTitle()
        .sheet(isPresented: $isShowingAddPhotoFlow) {
            AddPhotoFlowView(checklistItem: checklistItem)
        }
    }
}
