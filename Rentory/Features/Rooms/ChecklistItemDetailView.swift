//
//  ChecklistItemDetailView.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import SwiftData
import SwiftUI

struct ChecklistItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(AppColourTheme.storageKey) private var appColourThemeRawValue = AppColourTheme.defaultLook.rawValue

    let checklistItem: ChecklistItemRecord
    var stage: TenancyStage? = nil

    @State private var title: String
    @State private var moveInCondition: EvidenceCondition
    @State private var moveOutCondition: EvidenceCondition
    @State private var moveInSummary: String
    @State private var moveOutSummary: String
    @State private var newCommentBody: String = ""
    @State private var newCommentPhase: EvidencePhase? = nil
    @State private var isShowingAddPhotoFlow = false
    @State private var alertContent: RRAlertContent?
    @State private var isShowingDeleteConfirmation = false

    init(checklistItem: ChecklistItemRecord, stage: TenancyStage? = nil) {
        self.checklistItem = checklistItem
        self.stage = stage
        _title = State(initialValue: checklistItem.title)
        _moveInCondition = State(initialValue: checklistItem.moveInCondition)
        _moveOutCondition = State(initialValue: checklistItem.moveOutCondition)
        _moveInSummary = State(initialValue: checklistItem.moveInNotes ?? "")
        _moveOutSummary = State(initialValue: checklistItem.moveOutNotes ?? "")
    }

    /// True when the tenancy is in a phase where move-out evidence
    /// makes sense to capture. During move-in or while living we hide
    /// the move-out controls so the user isn't tempted to record an
    /// exit summary mid-tenancy. With no tenancy dates set at all we
    /// fall back to showing everything — the user has opted out of the
    /// staged flow.
    private var showsMoveOutControls: Bool {
        switch stage {
        case .moveIn, .living: return false
        case .moveOut, .none: return true
        }
    }

    /// A small hint shown in place of the move-out controls so the user
    /// understands *why* they're missing, not just that they vanished.
    private var moveOutLockedHint: String? {
        switch stage {
        case .moveIn:
            return "Move-out unlocks when you reach the end of your tenancy."
        case .living:
            return "Move-out unlocks when your tenancy is ending."
        case .moveOut, .none:
            return nil
        }
    }

    private var moveInPhotos: [EvidencePhoto] {
        checklistItem.photos.filter { $0.evidencePhase == .moveIn }
    }

    private var duringTenancyPhotos: [EvidencePhoto] {
        checklistItem.photos.filter { $0.evidencePhase == .duringTenancy }
    }

    private var moveOutPhotos: [EvidencePhoto] {
        checklistItem.photos.filter { $0.evidencePhase == .moveOut }
    }

    private var sortedComments: [ItemComment] {
        checklistItem.comments.sorted {
            if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
            return $0.createdAt < $1.createdAt
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RRTheme.sectionSpacing) {
                RRSheetHeader(
                    title: "Item",
                    subtitle: "Update the title, conditions, summaries or comments — and manage photos.",
                    systemImage: "checklist"
                )

                detailsPanel
                summariesPanel
                commentsPanel
                photosPanel

                RRDestructiveButton(title: "Delete item") {
                    isShowingDeleteConfirmation = true
                }
            }
            .frame(maxWidth: DeviceLayout.contentWidth(for: horizontalSizeClass, maximum: PlatformLayout.preferredDialogWidth), alignment: .leading)
            .padding(RRTheme.screenPadding)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .scrollIndicators(.hidden)
        .background(RRBackgroundView())
        .navigationTitle(checklistItem.title)
        .rrInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .rrPrimaryAction) {
                Button("Save") {
                    saveChanges()
                }
            }
        }
        .confirmationDialog(
            "Delete item?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteItem()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This item and any comments or photos attached to it will be removed from this room.")
        }
        .alert(item: $alertContent) { content in
            Alert(
                title: Text(content.title),
                message: Text(content.message),
                dismissButton: .cancel(Text(content.buttonTitle))
            )
        }
        .sheet(isPresented: $isShowingAddPhotoFlow) {
            AddPhotoFlowView(checklistItem: checklistItem, stage: stage)
        }
    }

    // MARK: - Panels

    private var detailsPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                RRSectionHeader(
                    title: "Details",
                    subtitle: showsMoveOutControls
                        ? "Name the item and record the move-in and move-out conditions."
                        : "Name the item and record the move-in condition."
                )

                labelledField(label: "Title") {
                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .rrTextInputAutocapitalizationWords()
                }

                conditionRow(label: "Move-in condition", selection: $moveInCondition)

                if showsMoveOutControls {
                    conditionRow(label: "Move-out condition", selection: $moveOutCondition)
                } else if let hint = moveOutLockedHint {
                    lockedFieldHint(label: "Move-out condition", hint: hint)
                }
            }
        }
    }

    private var summariesPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                RRSectionHeader(
                    title: "Summaries",
                    subtitle: showsMoveOutControls
                        ? "A short note for each phase."
                        : "A short note for the move-in phase."
                )

                labelledField(label: "Move-in summary") {
                    TextField("Add a short summary", text: $moveInSummary, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }

                if showsMoveOutControls {
                    labelledField(label: "Move-out summary") {
                        TextField("Add a short summary", text: $moveOutSummary, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                } else if let hint = moveOutLockedHint {
                    lockedFieldHint(label: "Move-out summary", hint: hint)
                }
            }
        }
    }

    private var commentsPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                RRSectionHeader(
                    title: "Comments",
                    subtitle: sortedComments.isEmpty
                        ? "Add notes as you go."
                        : "\(sortedComments.count) comment\(sortedComments.count == 1 ? "" : "s")"
                )

                if !sortedComments.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(sortedComments.enumerated()), id: \.element.id) { index, comment in
                            if index > 0 {
                                Divider()
                                    .background(RRColours.border)
                            }
                            commentRow(comment)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(RRColours.cardBackground.opacity(0.55))
                    )
                }

                addCommentEditor
            }
        }
    }

    private var photosPanel: some View {
        RRGlassPanel {
            VStack(alignment: .leading, spacing: RRTheme.controlSpacing) {
                RRSectionHeader(
                    title: "Photos",
                    subtitle: checklistItem.photos.isEmpty
                        ? "Add photos when you want a clearer record of this item."
                        : "\(checklistItem.photos.count) photo\(checklistItem.photos.count == 1 ? "" : "s")"
                )

                RRSecondaryButton(title: "Add a photo") {
                    isShowingAddPhotoFlow = true
                }
                .accessibilityHint("Adds a photo to this checklist item.")

                if !moveInPhotos.isEmpty {
                    EvidencePhotoGridView(title: "Move-in", photos: moveInPhotos)
                }
                if !duringTenancyPhotos.isEmpty {
                    EvidencePhotoGridView(title: "During tenancy", photos: duringTenancyPhotos)
                }
                if !moveOutPhotos.isEmpty {
                    EvidencePhotoGridView(title: "Move-out", photos: moveOutPhotos)
                }
            }
        }
    }

    // MARK: - Comment row + editor

    @ViewBuilder
    private func commentRow(_ comment: ItemComment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(comment.body)
                    .font(RRTypography.body)
                    .foregroundStyle(RRColours.primary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    if let phase = comment.evidencePhase {
                        Text(phase.rawValue)
                            .font(RRTypography.caption.weight(.semibold))
                            .foregroundStyle(RRColours.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(RRColours.secondary.opacity(0.14))
                            )
                    }
                    Text(comment.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(RRTypography.caption)
                        .foregroundStyle(RRColours.mutedText)
                }
            }

            Spacer(minLength: 8)

            Button {
                deleteComment(comment)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RRColours.danger)
                    .padding(6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete comment")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var addCommentEditor: some View {
        VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
            Text("Add a comment")
                .font(RRTypography.footnote.weight(.semibold))
                .foregroundStyle(RRColours.mutedText)

            TextField("What did you notice?", text: $newCommentBody, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...5)

            HStack(spacing: 12) {
                Picker("Phase", selection: $newCommentPhase) {
                    Text("No phase").tag(EvidencePhase?.none)
                    ForEach(EvidencePhase.allCases, id: \.self) { phase in
                        Text(phase.rawValue).tag(EvidencePhase?.some(phase))
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                Button {
                    addComment()
                } label: {
                    Label("Add comment", systemImage: "plus.circle.fill")
                        .labelStyle(.titleAndIcon)
                        .font(RRTypography.footnote.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(canAddComment ? RRColours.secondary : RRColours.secondary.opacity(0.3))
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(!canAddComment)
                .accessibilityLabel("Add comment")
            }
        }
    }

    private var canAddComment: Bool {
        !newCommentBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Helpers

    @ViewBuilder
    private func labelledField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: RRTheme.smallSpacing) {
            Text(label)
                .font(RRTypography.footnote.weight(.semibold))
                .foregroundStyle(RRColours.mutedText)

            content()
        }
    }

    @ViewBuilder
    private func lockedFieldHint(label: String, hint: String) -> some View {
        labelledField(label: label) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(RRColours.mutedText)
                Text(hint)
                    .font(RRTypography.footnote)
                    .foregroundStyle(RRColours.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(RRColours.cardBackground.opacity(0.55))
            )
        }
    }

    @ViewBuilder
    private func conditionRow(label: String, selection: Binding<EvidenceCondition>) -> some View {
        labelledField(label: label) {
            Picker(label, selection: selection) {
                ForEach(EvidenceCondition.allCases, id: \.self) { condition in
                    Text(condition.rawValue).tag(condition)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Actions

    private func addComment() {
        let trimmed = newCommentBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let comment = ItemComment(
            body: trimmed,
            phase: newCommentPhase,
            sortOrder: checklistItem.comments.count
        )
        checklistItem.comments.append(comment)
        checklistItem.updatedAt = .now

        do {
            try modelContext.save()
            newCommentBody = ""
            newCommentPhase = nil
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeSaved)
        }
    }

    private func deleteComment(_ comment: ItemComment) {
        modelContext.delete(comment)
        checklistItem.updatedAt = .now

        do {
            try modelContext.save()
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeSaved)
        }
    }

    private func saveChanges() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            alertContent = RRAlertContent(
                title: "Item not saved",
                message: "Add a title to continue."
            )
            return
        }

        checklistItem.title = trimmedTitle
        checklistItem.moveInCondition = moveInCondition
        checklistItem.moveInNotes = optionalText(moveInSummary)
        // Only persist move-out fields when the staged flow allows
        // capturing them — protects against stale local state being
        // written back over a previously-untouched value.
        if showsMoveOutControls {
            checklistItem.moveOutCondition = moveOutCondition
            checklistItem.moveOutNotes = optionalText(moveOutSummary)
        }
        checklistItem.updatedAt = .now

        do {
            try modelContext.save()
        } catch {
            alertContent = RRAlertContent(error: .recordCouldNotBeSaved)
        }
    }

    private func deleteItem() {
        modelContext.delete(checklistItem)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            alertContent = RRAlertContent(
                title: "Item not deleted",
                message: "This item could not be deleted. Please try again."
            )
        }
    }
}
