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

    let checklistItem: ChecklistItemRecord

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

    init(checklistItem: ChecklistItemRecord) {
        self.checklistItem = checklistItem
        _title = State(initialValue: checklistItem.title)
        _moveInCondition = State(initialValue: checklistItem.moveInCondition)
        _moveOutCondition = State(initialValue: checklistItem.moveOutCondition)
        _moveInSummary = State(initialValue: checklistItem.moveInNotes ?? "")
        _moveOutSummary = State(initialValue: checklistItem.moveOutNotes ?? "")
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
        Form {
            Section {
                RRSheetHeader(
                    title: "Item",
                    subtitle: "Update the title, conditions, summary or comments — and manage photos.",
                    systemImage: "checklist"
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Item") {
                TextField("Title", text: $title)
                    .rrTextInputAutocapitalizationWords()
            }

            Section("Conditions") {
                Picker("Move-in", selection: $moveInCondition) {
                    ForEach(EvidenceCondition.allCases, id: \.self) { condition in
                        Text(condition.rawValue).tag(condition)
                    }
                }

                Picker("Move-out", selection: $moveOutCondition) {
                    ForEach(EvidenceCondition.allCases, id: \.self) { condition in
                        Text(condition.rawValue).tag(condition)
                    }
                }
            }

            Section("Move-in summary") {
                TextField("Add a short summary", text: $moveInSummary, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Move-out summary") {
                TextField("Add a short summary", text: $moveOutSummary, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Comments") {
                if sortedComments.isEmpty {
                    Text("No comments yet.")
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                } else {
                    ForEach(sortedComments) { comment in
                        commentRow(comment)
                    }
                    .onDelete(perform: deleteComments)
                }

                addCommentEditor
            }

            Section("Photos") {
                if checklistItem.photos.isEmpty {
                    Text("No photos yet.")
                        .font(RRTypography.footnote)
                        .foregroundStyle(RRColours.mutedText)
                }

                Button {
                    isShowingAddPhotoFlow = true
                } label: {
                    Label("Add a photo", systemImage: "camera")
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

            Section {
                RRDestructiveButton(title: "Delete item") {
                    isShowingDeleteConfirmation = true
                }
            }
        }
        .navigationTitle(checklistItem.title)
        .rrInlineNavigationTitle()
        .scrollContentBackground(.hidden)
        .background(RRBackgroundView())
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
            AddPhotoFlowView(checklistItem: checklistItem)
        }
    }

    @ViewBuilder
    private func commentRow(_ comment: ItemComment) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(comment.body)
                .font(RRTypography.body)
                .foregroundStyle(RRColours.primary)

            HStack(spacing: 8) {
                if let phase = comment.evidencePhase {
                    Text(phase.rawValue)
                        .font(RRTypography.caption.weight(.semibold))
                        .foregroundStyle(RRColours.secondary)
                }
                Text(comment.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(RRTypography.caption)
                    .foregroundStyle(RRColours.mutedText)
            }
        }
    }

    private var addCommentEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Add a comment", text: $newCommentBody, axis: .vertical)
                .lineLimit(2...4)

            HStack {
                Picker("Phase", selection: $newCommentPhase) {
                    Text("No phase").tag(EvidencePhase?.none)
                    ForEach(EvidencePhase.allCases, id: \.self) { phase in
                        Text(phase.rawValue).tag(EvidencePhase?.some(phase))
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                Button("Add comment") {
                    addComment()
                }
                .disabled(newCommentBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

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

    private func deleteComments(at offsets: IndexSet) {
        let comments = sortedComments
        for offset in offsets {
            let comment = comments[offset]
            modelContext.delete(comment)
        }
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
        checklistItem.moveOutCondition = moveOutCondition
        checklistItem.moveInNotes = optionalText(moveInSummary)
        checklistItem.moveOutNotes = optionalText(moveOutSummary)
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
