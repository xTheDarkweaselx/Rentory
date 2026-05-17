//
//  RoomConditionAggregationTests.swift
//  RentoryTests
//
//  Created by Adam Ibrahim on 17/05/2026.
//

import Foundation
import Testing

@testable import Rentory

struct RoomConditionAggregationTests {
    private func makeItem(
        title: String,
        moveIn: EvidenceCondition,
        moveOut: EvidenceCondition,
        sortOrder: Int = 0
    ) -> ChecklistItemRecord {
        ChecklistItemRecord(
            title: title,
            sortOrder: sortOrder,
            moveInConditionRawValue: moveIn.rawValue,
            moveOutConditionRawValue: moveOut.rawValue
        )
    }

    @Test func aggregateConditionFallsBackToNotCheckedWhenNoItems() {
        let room = RoomRecord(name: "Empty", type: .other, sortOrder: 0)
        #expect(room.aggregateCondition == .notChecked)
        #expect(room.displayCondition == .notChecked)
    }

    @Test func aggregateConditionExcludesNotCheckedAndNotApplicable() {
        let room = RoomRecord(name: "Kitchen", type: .kitchen, sortOrder: 0)
        room.checklistItems = [
            makeItem(title: "A", moveIn: .notChecked, moveOut: .notApplicable),
        ]
        #expect(room.aggregateCondition == .notChecked)
        #expect(room.displayCondition == .notChecked)
    }

    @Test func aggregateConditionTakesWorstAcrossItems() {
        let room = RoomRecord(name: "Kitchen", type: .kitchen, sortOrder: 0)
        room.checklistItems = [
            makeItem(title: "Walls", moveIn: .good, moveOut: .good),
            makeItem(title: "Oven", moveIn: .fair, moveOut: .damaged, sortOrder: 1),
        ]
        #expect(room.aggregateCondition == .damaged)
        #expect(room.displayCondition == .damaged)
    }

    @Test func aggregateConditionRecognisesMissingAsMostSevere() {
        let room = RoomRecord(name: "Living room", type: .livingRoom, sortOrder: 0)
        room.checklistItems = [
            makeItem(title: "Sofa", moveIn: .damaged, moveOut: .damaged),
            makeItem(title: "Curtains", moveIn: .missing, moveOut: .missing, sortOrder: 1),
        ]
        #expect(room.aggregateCondition == .missing)
    }

    @Test func manualConditionOverrideTakesPrecedenceOverAggregate() {
        let room = RoomRecord(name: "Bathroom", type: .bathroom, sortOrder: 0)
        room.checklistItems = [
            makeItem(title: "Sink", moveIn: .damaged, moveOut: .poor),
        ]
        room.manualConditionOverride = .good
        #expect(room.aggregateCondition == .damaged)
        #expect(room.displayCondition == .good)
    }

    @Test func manualOverridePersistsWhenAddingNewItem() {
        let room = RoomRecord(name: "Bedroom", type: .bedroom, sortOrder: 0)
        room.checklistItems = [
            makeItem(title: "Walls", moveIn: .good, moveOut: .good),
        ]
        room.manualConditionOverride = .fair

        room.checklistItems.append(
            makeItem(title: "Wardrobe", moveIn: .damaged, moveOut: .damaged, sortOrder: 1)
        )

        #expect(room.manualConditionOverride == .fair)
        #expect(room.displayCondition == .fair)
        #expect(room.aggregateCondition == .damaged)
    }

    @Test func clearingManualOverrideRevealsAggregate() {
        let room = RoomRecord(name: "Hallway", type: .hallway, sortOrder: 0)
        room.checklistItems = [
            makeItem(title: "Floor", moveIn: .poor, moveOut: .poor),
        ]
        room.manualConditionOverride = .good
        #expect(room.displayCondition == .good)

        room.manualConditionOverride = nil
        #expect(room.displayCondition == .poor)
    }

    @Test func itemCommentExposesEvidencePhase() {
        let comment = ItemComment(body: "Leak by sink", phase: .moveIn)
        #expect(comment.evidencePhase == .moveIn)

        comment.evidencePhase = .moveOut
        #expect(comment.evidencePhaseRawValue == EvidencePhase.moveOut.rawValue)

        comment.evidencePhase = nil
        #expect(comment.evidencePhaseRawValue == nil)
    }

    @Test func checklistItemHoldsCommentsRelationship() {
        let item = ChecklistItemRecord(
            title: "Walls",
            sortOrder: 0,
            comments: [
                ItemComment(body: "Crack near ceiling", phase: .moveIn),
                ItemComment(body: "Repaired", phase: .duringTenancy, sortOrder: 1),
            ]
        )

        #expect(item.comments.count == 2)
        #expect(item.comments[0].body == "Crack near ceiling")
        #expect(item.comments[1].evidencePhase == .duringTenancy)
    }
}
