//
//  ReportConditionSummary.swift
//  Rentory
//
//  Rolls a room's per-item conditions up into a check-in / check-out
//  summary for the report: the worst move-in and move-out conditions,
//  and how many items got worse between the two. Pure value logic, kept
//  separate from the PDF builder so it can be unit-tested directly.
//

import Foundation

struct ReportConditionSummary {
    /// Worst (most severe) move-in condition across items that were
    /// actually assessed. `.notChecked` when nothing was assessed.
    let moveInAggregate: EvidenceCondition

    /// Worst move-out condition across assessed items.
    let moveOutAggregate: EvidenceCondition

    /// Number of items that got worse between move-in and move-out —
    /// i.e. both ends were assessed and move-out is more severe. Items
    /// that were never checked at one end aren't counted as "changed",
    /// to avoid mistaking missing data for damage.
    let worsenedItemCount: Int

    init(conditionPairs: [(moveIn: EvidenceCondition, moveOut: EvidenceCondition)]) {
        moveInAggregate = Self.aggregate(conditionPairs.map(\.moveIn))
        moveOutAggregate = Self.aggregate(conditionPairs.map(\.moveOut))
        worsenedItemCount = conditionPairs.filter { Self.isWorsening(from: $0.moveIn, to: $0.moveOut) }.count
    }

    /// True when an item demonstrably deteriorated: both ends were real
    /// assessments and move-out is more severe than move-in.
    static func isWorsening(from moveIn: EvidenceCondition, to moveOut: EvidenceCondition) -> Bool {
        moveIn.contributesToAggregate
            && moveOut.contributesToAggregate
            && moveOut.aggregateSeverity > moveIn.aggregateSeverity
    }

    private static func aggregate(_ conditions: [EvidenceCondition]) -> EvidenceCondition {
        conditions
            .filter(\.contributesToAggregate)
            .max(by: { $0.aggregateSeverity < $1.aggregateSeverity })
            ?? .notChecked
    }
}
