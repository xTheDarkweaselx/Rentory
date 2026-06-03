//
//  AddPhotoFlowTests.swift
//  RentoryTests
//
//  Verifies the add-photo flow's phase logic: which phases are offered
//  for a given tenancy stage, and which one the flow defaults to so the
//  common case (documenting the stage you're in) needs no extra tap.
//

import Testing

@testable import Rentory

struct AddPhotoFlowTests {
    @Test func allowedPhasesHideMoveOutDuringMoveInAndLiving() {
        #expect(AddPhotoFlowView.allowedPhases(for: .moveIn) == [.moveIn, .duringTenancy])
        #expect(AddPhotoFlowView.allowedPhases(for: .living) == [.moveIn, .duringTenancy])
    }

    @Test func allowedPhasesIncludeEverythingAtMoveOutOrNoStage() {
        #expect(AddPhotoFlowView.allowedPhases(for: .moveOut) == EvidencePhase.allCases)
        #expect(AddPhotoFlowView.allowedPhases(for: nil) == EvidencePhase.allCases)
    }

    @Test func initialPhaseFollowsTheCurrentStage() {
        #expect(
            AddPhotoFlowView.initialPhase(for: .moveIn, allowed: AddPhotoFlowView.allowedPhases(for: .moveIn)) == .moveIn
        )
        #expect(
            AddPhotoFlowView.initialPhase(for: .living, allowed: AddPhotoFlowView.allowedPhases(for: .living)) == .duringTenancy
        )
        #expect(
            AddPhotoFlowView.initialPhase(for: .moveOut, allowed: AddPhotoFlowView.allowedPhases(for: .moveOut)) == .moveOut
        )
    }

    @Test func initialPhaseDefaultsToMoveInWithoutAStage() {
        #expect(
            AddPhotoFlowView.initialPhase(for: nil, allowed: AddPhotoFlowView.allowedPhases(for: nil)) == .moveIn
        )
    }

    @Test func initialPhaseClampsToAnAllowedPhase() {
        // If the stage's preferred phase isn't in the allowed set, fall
        // back to the first allowed phase rather than an invalid selection.
        let allowed: [EvidencePhase] = [.moveIn, .duringTenancy]
        #expect(AddPhotoFlowView.initialPhase(for: .moveOut, allowed: allowed) == .moveIn)
    }
}
