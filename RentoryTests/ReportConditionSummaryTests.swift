//
//  ReportConditionSummaryTests.swift
//  RentoryTests
//
//  Covers the check-in / check-out condition rollup + change detection,
//  and that each report type renders a materially different rooms
//  section (so a check-out report can't read identically to a check-in).
//

import Testing

@testable import Rentory

struct ReportConditionSummaryTests {
    private func summary(_ pairs: [(EvidenceCondition, EvidenceCondition)]) -> ReportConditionSummary {
        ReportConditionSummary(conditionPairs: pairs.map { (moveIn: $0.0, moveOut: $0.1) })
    }

    @Test func aggregatesWorstContributingCondition() {
        let result = summary([(.good, .good), (.fair, .damaged), (.notChecked, .notApplicable)])
        #expect(result.moveInAggregate == .fair)     // worst assessed move-in (good, fair)
        #expect(result.moveOutAggregate == .damaged) // worst assessed move-out (good, damaged)
    }

    @Test func aggregateIsNotCheckedWhenNothingAssessed() {
        let result = summary([(.notChecked, .notApplicable), (.notApplicable, .notChecked)])
        #expect(result.moveInAggregate == .notChecked)
        #expect(result.moveOutAggregate == .notChecked)
    }

    @Test func countsOnlyItemsThatGotWorse() {
        let result = summary([
            (.good, .damaged),       // worsened ✓
            (.fair, .fair),          // unchanged
            (.poor, .good),          // improved
            (.notChecked, .damaged), // move-in unknown — can't call it a change
            (.good, .notChecked),    // move-out unknown — can't call it a change
        ])
        #expect(result.worsenedItemCount == 1)
    }

    @Test func suggestedReportTypeFollowsTheStage() {
        #expect(ReportType.suggested(for: .moveIn) == .checkIn)
        #expect(ReportType.suggested(for: .living) == .fullRecord)
        #expect(ReportType.suggested(for: .moveOut) == .checkOut)
    }

    @Test func isWorseningRequiresBothEndsAssessedAndMoreSevere() {
        #expect(ReportConditionSummary.isWorsening(from: .good, to: .damaged))
        #expect(!ReportConditionSummary.isWorsening(from: .damaged, to: .good))       // improved
        #expect(!ReportConditionSummary.isWorsening(from: .good, to: .good))          // unchanged
        #expect(!ReportConditionSummary.isWorsening(from: .notChecked, to: .damaged)) // move-in unknown
        #expect(!ReportConditionSummary.isWorsening(from: .good, to: .notApplicable)) // move-out not real
    }

    // MARK: - Builder integration: each report type reads differently

    @MainActor
    private func roomsText(for reportType: ReportType) -> String {
        let item = ChecklistItemRecord(
            title: "Oven",
            sortOrder: 0,
            moveInConditionRawValue: EvidenceCondition.good.rawValue,
            moveOutConditionRawValue: EvidenceCondition.damaged.rawValue
        )
        let room = RoomRecord(name: "Kitchen", type: .kitchen, sortOrder: 0, checklistItems: [item])
        let pack = PropertyPack(nickname: "Home", rooms: [room])
        let snapshot = PDFReportSnapshot(propertyPack: pack)
        let sections = PDFReportBuilder().makeReportSections(
            for: snapshot,
            options: ExportOptions(reportType: reportType)
        )
        return sections.first { $0.title.contains("Rooms") }?.lines.joined(separator: "\n") ?? ""
    }

    @Test @MainActor func checkInShowsOnlyMoveInCondition() {
        let text = roomsText(for: .checkIn)
        #expect(text.contains("Condition: Good"))
        #expect(text.contains("Overall condition: Good"))
        #expect(!text.contains("Move-out")) // a check-in must not surface move-out data
    }

    @Test @MainActor func checkOutShowsBeforeAfterAndFlagsTheChange() {
        let text = roomsText(for: .checkOut)
        #expect(text.contains("Move-in: Good — Move-out: Damaged"))
        #expect(text.contains("(worse than move-in)"))
        #expect(text.contains("Overall condition: Damaged"))
    }

    @Test @MainActor func fullRecordShowsBothConditionsOnSeparateLines() {
        let text = roomsText(for: .fullRecord)
        #expect(text.contains("Move-in: Good"))
        #expect(text.contains("Move-out: Damaged"))
        #expect(!text.contains("—")) // full record keeps the original separate-lines layout
    }

    @Test @MainActor func checkOutWithoutMoveOutDataWarnsAndFlagsUnchecked() {
        // Move-in assessed, move-out left unchecked — must not read as clean.
        let item = ChecklistItemRecord(
            title: "Oven",
            sortOrder: 0,
            moveInConditionRawValue: EvidenceCondition.good.rawValue
        )
        let room = RoomRecord(name: "Kitchen", type: .kitchen, sortOrder: 0, checklistItems: [item])
        let pack = PropertyPack(nickname: "Home", rooms: [room])
        let snapshot = PDFReportSnapshot(propertyPack: pack)
        let sections = PDFReportBuilder().makeReportSections(
            for: snapshot,
            options: ExportOptions(reportType: .checkOut)
        )
        let text = sections.first { $0.title.contains("Rooms") }?.lines.joined(separator: "\n") ?? ""
        #expect(text.contains("No move-out condition has been recorded yet"))
        #expect(text.contains("(not re-checked at move-out)"))
    }

    // MARK: - Before / after photo pairing (check-out)

    @MainActor
    private func reportSections(for reportType: ReportType, itemPhotos: [EvidencePhoto]) -> [PDFReportSection] {
        let item = ChecklistItemRecord(
            title: "Oven",
            sortOrder: 0,
            moveInConditionRawValue: EvidenceCondition.good.rawValue,
            moveOutConditionRawValue: EvidenceCondition.damaged.rawValue,
            photos: itemPhotos
        )
        let room = RoomRecord(name: "Kitchen", type: .kitchen, sortOrder: 0, checklistItems: [item])
        let pack = PropertyPack(nickname: "Home", rooms: [room])
        return PDFReportBuilder().makeReportSections(
            for: PDFReportSnapshot(propertyPack: pack),
            options: ExportOptions(reportType: reportType)
        )
    }

    @Test @MainActor func checkOutPairsMoveInAndMoveOutPhotos() {
        let sections = reportSections(for: .checkOut, itemPhotos: [
            EvidencePhoto(localFileName: "in.jpg", phase: .moveIn, sortOrder: 0),
            EvidencePhoto(localFileName: "out.jpg", phase: .moveOut, sortOrder: 0),
        ])
        let beforeAfter = sections.first { $0.title.contains("Before & after") }
        #expect(beforeAfter != nil)
        #expect(beforeAfter?.photos.count == 2) // exactly one move-in / move-out pair

        // Order is the whole premise: move-in must be the left (first) entry,
        // move-out the right (second). The 2-column grid renders them side by side.
        #expect(beforeAfter?.photos.first?.details.contains(where: { $0.contains("Move-in") }) == true)
        #expect(beforeAfter?.photos.last?.details.contains(where: { $0.contains("Move-out") }) == true)

        let details = (beforeAfter?.photos ?? []).flatMap(\.details).joined(separator: "|")
        #expect(details.contains("Move-in — Good"))
        #expect(details.contains("Move-out — Damaged"))
        #expect(details.contains("worse than move-in"))
    }

    @Test @MainActor func checkOutFlatPhotosSectionExcludesPairedPhotos() {
        let sections = reportSections(for: .checkOut, itemPhotos: [
            EvidencePhoto(localFileName: "in.jpg", phase: .moveIn, sortOrder: 0),
            EvidencePhoto(localFileName: "out.jpg", phase: .moveOut, sortOrder: 0),
        ])
        // Both photos appear paired in "Before & after"; the flat Photos
        // section must not repeat them.
        let photosSection = sections.first { $0.title == "Photos" }
        #expect(photosSection?.photos.isEmpty == true)
    }

    @Test @MainActor func checkInHasNoBeforeAfterSection() {
        let sections = reportSections(for: .checkIn, itemPhotos: [
            EvidencePhoto(localFileName: "in.jpg", phase: .moveIn, sortOrder: 0),
            EvidencePhoto(localFileName: "out.jpg", phase: .moveOut, sortOrder: 0),
        ])
        #expect(sections.first { $0.title.contains("Before & after") } == nil)
    }

    @Test @MainActor func noBeforeAfterWhenAnItemLacksOnePhase() {
        let sections = reportSections(for: .checkOut, itemPhotos: [
            EvidencePhoto(localFileName: "in.jpg", phase: .moveIn, sortOrder: 0),
        ])
        #expect(sections.first { $0.title.contains("Before & after") } == nil)
    }
}
