//
//  ActionPulseServiceTests.swift
//  RentoryTests
//
//  Created by Adam Ibrahim on 17/05/2026.
//

import Foundation
import Testing

@testable import Rentory

struct ActionPulseServiceTests {
    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let oneDay: TimeInterval = 86_400

    private func makeProperty(actions: [ActionItem] = []) -> PropertyPack {
        let pack = PropertyPack(nickname: "Home")
        pack.actions = actions
        return pack
    }

    @Test func emptyPropertyHasNoOpenActions() {
        let result = ActionPulseService.pulse(for: makeProperty(), on: referenceDate)

        #expect(result.overdueCount == 0)
        #expect(result.dueSoonCount == 0)
        #expect(result.totalOpenCount == 0)
        #expect(result.upcomingItems.isEmpty)
        #expect(result.statusTitle == "Nothing due")
    }

    @Test func overdueActionIsCounted() {
        let property = makeProperty(actions: [
            ActionItem(title: "Submit deposit", dueDate: referenceDate.addingTimeInterval(-oneDay)),
        ])

        let result = ActionPulseService.pulse(for: property, on: referenceDate)

        #expect(result.overdueCount == 1)
        #expect(result.dueSoonCount == 0)
        #expect(result.totalOpenCount == 1)
        #expect(result.upcomingItems.first?.urgency == .overdue)
        #expect(result.statusTitle.contains("overdue"))
    }

    @Test func dueWithinNextSevenDaysIsCountedAsDueSoon() {
        let property = makeProperty(actions: [
            ActionItem(title: "Gas safety", dueDate: referenceDate.addingTimeInterval(3 * oneDay)),
        ])

        let result = ActionPulseService.pulse(for: property, on: referenceDate)

        #expect(result.overdueCount == 0)
        #expect(result.dueSoonCount == 1)
        #expect(result.upcomingItems.first?.urgency == .dueSoon)
        #expect(result.statusTitle.contains("due this week"))
    }

    @Test func dueAfterSevenDaysCountsAsOpenButNotDueSoon() {
        let property = makeProperty(actions: [
            ActionItem(title: "Inspection", dueDate: referenceDate.addingTimeInterval(14 * oneDay)),
        ])

        let result = ActionPulseService.pulse(for: property, on: referenceDate)

        #expect(result.overdueCount == 0)
        #expect(result.dueSoonCount == 0)
        #expect(result.totalOpenCount == 1)
    }

    @Test func completedActionIsExcluded() {
        let property = makeProperty(actions: [
            ActionItem(
                title: "Reported leak",
                dueDate: referenceDate.addingTimeInterval(-oneDay),
                completedAt: referenceDate.addingTimeInterval(-oneDay / 2)
            ),
        ])

        let result = ActionPulseService.pulse(for: property, on: referenceDate)

        #expect(result.overdueCount == 0)
        #expect(result.dueSoonCount == 0)
        #expect(result.totalOpenCount == 0)
    }

    @Test func upcomingItemsAreSortedOverdueFirstThenDueAscending() {
        let property = makeProperty(actions: [
            ActionItem(title: "Tomorrow", dueDate: referenceDate.addingTimeInterval(oneDay)),
            ActionItem(title: "Three days ago", dueDate: referenceDate.addingTimeInterval(-3 * oneDay)),
            ActionItem(title: "In two days", dueDate: referenceDate.addingTimeInterval(2 * oneDay)),
            ActionItem(title: "Yesterday", dueDate: referenceDate.addingTimeInterval(-oneDay)),
        ])

        let result = ActionPulseService.pulse(for: property, on: referenceDate)

        #expect(result.upcomingItems.count == 4)
        #expect(result.upcomingItems[0].title == "Three days ago")
        #expect(result.upcomingItems[1].title == "Yesterday")
        #expect(result.upcomingItems[2].title == "Tomorrow")
        #expect(result.upcomingItems[3].title == "In two days")
    }

    @Test func undatedActionsAreOpenButNeitherOverdueNorDueSoon() {
        let property = makeProperty(actions: [
            ActionItem(title: "Open-ended task"),
        ])

        let result = ActionPulseService.pulse(for: property, on: referenceDate)

        #expect(result.overdueCount == 0)
        #expect(result.dueSoonCount == 0)
        #expect(result.totalOpenCount == 1)
    }

    @Test func upcomingItemsAreCappedAtFive() {
        let actions = (0..<8).map { offset in
            ActionItem(title: "Action \(offset)", dueDate: referenceDate.addingTimeInterval(Double(offset) * oneDay))
        }
        let property = makeProperty(actions: actions)

        let result = ActionPulseService.pulse(for: property, on: referenceDate)

        #expect(result.upcomingItems.count == 5)
    }

    @Test func overdueOutranksDueSoonInStatusTitle() {
        let property = makeProperty(actions: [
            ActionItem(title: "Overdue", dueDate: referenceDate.addingTimeInterval(-oneDay)),
            ActionItem(title: "Soon", dueDate: referenceDate.addingTimeInterval(oneDay)),
        ])

        let result = ActionPulseService.pulse(for: property, on: referenceDate)

        #expect(result.overdueCount == 1)
        #expect(result.dueSoonCount == 1)
        #expect(result.statusTitle.contains("overdue"))
    }

    @Test func urgencyClassifierCoversAllStates() {
        let overdue = ActionItem(title: "x", dueDate: referenceDate.addingTimeInterval(-oneDay))
        let dueSoon = ActionItem(title: "x", dueDate: referenceDate.addingTimeInterval(oneDay))
        let upcoming = ActionItem(title: "x", dueDate: referenceDate.addingTimeInterval(30 * oneDay))
        let undated = ActionItem(title: "x")
        let completed = ActionItem(title: "x", completedAt: referenceDate)

        #expect(ActionPulseService.urgency(for: overdue, on: referenceDate) == .overdue)
        #expect(ActionPulseService.urgency(for: dueSoon, on: referenceDate) == .dueSoon)
        #expect(ActionPulseService.urgency(for: upcoming, on: referenceDate) == .upcoming)
        #expect(ActionPulseService.urgency(for: undated, on: referenceDate) == .undated)
        #expect(ActionPulseService.urgency(for: completed, on: referenceDate) == .completed)
    }
}
