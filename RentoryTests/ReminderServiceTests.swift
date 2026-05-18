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

    private func makeProperty(reminders: [Reminder] = []) -> PropertyPack {
        let pack = PropertyPack(nickname: "Home")
        pack.reminders = reminders
        return pack
    }

    @Test func emptyPropertyHasNoOpenActions() {
        let result = ReminderService.overview(for: makeProperty(), on: referenceDate)

        #expect(result.overdueCount == 0)
        #expect(result.dueSoonCount == 0)
        #expect(result.totalOpenCount == 0)
        #expect(result.upcomingItems.isEmpty)
        #expect(result.statusTitle == "Nothing due")
    }

    @Test func overdueActionIsCounted() {
        let property = makeProperty(reminders: [
            Reminder(title: "Submit deposit", dueDate: referenceDate.addingTimeInterval(-oneDay)),
        ])

        let result = ReminderService.overview(for: property, on: referenceDate)

        #expect(result.overdueCount == 1)
        #expect(result.dueSoonCount == 0)
        #expect(result.totalOpenCount == 1)
        #expect(result.upcomingItems.first?.urgency == .overdue)
        #expect(result.statusTitle.contains("overdue"))
    }

    @Test func dueWithinNextSevenDaysIsCountedAsDueSoon() {
        let property = makeProperty(reminders: [
            Reminder(title: "Gas safety", dueDate: referenceDate.addingTimeInterval(3 * oneDay)),
        ])

        let result = ReminderService.overview(for: property, on: referenceDate)

        #expect(result.overdueCount == 0)
        #expect(result.dueSoonCount == 1)
        #expect(result.upcomingItems.first?.urgency == .dueSoon)
        #expect(result.statusTitle.contains("due this week"))
    }

    @Test func dueAfterSevenDaysCountsAsOpenButNotDueSoon() {
        let property = makeProperty(reminders: [
            Reminder(title: "Inspection", dueDate: referenceDate.addingTimeInterval(14 * oneDay)),
        ])

        let result = ReminderService.overview(for: property, on: referenceDate)

        #expect(result.overdueCount == 0)
        #expect(result.dueSoonCount == 0)
        #expect(result.totalOpenCount == 1)
    }

    @Test func completedActionIsExcluded() {
        let property = makeProperty(reminders: [
            Reminder(
                title: "Reported leak",
                dueDate: referenceDate.addingTimeInterval(-oneDay),
                completedAt: referenceDate.addingTimeInterval(-oneDay / 2)
            ),
        ])

        let result = ReminderService.overview(for: property, on: referenceDate)

        #expect(result.overdueCount == 0)
        #expect(result.dueSoonCount == 0)
        #expect(result.totalOpenCount == 0)
    }

    @Test func upcomingItemsAreSortedOverdueFirstThenDueAscending() {
        let property = makeProperty(reminders: [
            Reminder(title: "Tomorrow", dueDate: referenceDate.addingTimeInterval(oneDay)),
            Reminder(title: "Three days ago", dueDate: referenceDate.addingTimeInterval(-3 * oneDay)),
            Reminder(title: "In two days", dueDate: referenceDate.addingTimeInterval(2 * oneDay)),
            Reminder(title: "Yesterday", dueDate: referenceDate.addingTimeInterval(-oneDay)),
        ])

        let result = ReminderService.overview(for: property, on: referenceDate)

        #expect(result.upcomingItems.count == 4)
        #expect(result.upcomingItems[0].title == "Three days ago")
        #expect(result.upcomingItems[1].title == "Yesterday")
        #expect(result.upcomingItems[2].title == "Tomorrow")
        #expect(result.upcomingItems[3].title == "In two days")
    }

    @Test func undatedActionsAreOpenButNeitherOverdueNorDueSoon() {
        let property = makeProperty(reminders: [
            Reminder(title: "Open-ended task"),
        ])

        let result = ReminderService.overview(for: property, on: referenceDate)

        #expect(result.overdueCount == 0)
        #expect(result.dueSoonCount == 0)
        #expect(result.totalOpenCount == 1)
    }

    @Test func upcomingItemsAreCappedAtFive() {
        let reminders = (0..<8).map { offset in
            Reminder(title: "Action \(offset)", dueDate: referenceDate.addingTimeInterval(Double(offset) * oneDay))
        }
        let property = makeProperty(reminders: reminders)

        let result = ReminderService.overview(for: property, on: referenceDate)

        #expect(result.upcomingItems.count == 5)
    }

    @Test func overdueOutranksDueSoonInStatusTitle() {
        let property = makeProperty(reminders: [
            Reminder(title: "Overdue", dueDate: referenceDate.addingTimeInterval(-oneDay)),
            Reminder(title: "Soon", dueDate: referenceDate.addingTimeInterval(oneDay)),
        ])

        let result = ReminderService.overview(for: property, on: referenceDate)

        #expect(result.overdueCount == 1)
        #expect(result.dueSoonCount == 1)
        #expect(result.statusTitle.contains("overdue"))
    }

    @Test func urgencyClassifierCoversAllStates() {
        let overdue = Reminder(title: "x", dueDate: referenceDate.addingTimeInterval(-oneDay))
        let dueSoon = Reminder(title: "x", dueDate: referenceDate.addingTimeInterval(oneDay))
        let upcoming = Reminder(title: "x", dueDate: referenceDate.addingTimeInterval(30 * oneDay))
        let undated = Reminder(title: "x")
        let completed = Reminder(title: "x", completedAt: referenceDate)

        #expect(ReminderService.urgency(for: overdue, on: referenceDate) == .overdue)
        #expect(ReminderService.urgency(for: dueSoon, on: referenceDate) == .dueSoon)
        #expect(ReminderService.urgency(for: upcoming, on: referenceDate) == .upcoming)
        #expect(ReminderService.urgency(for: undated, on: referenceDate) == .undated)
        #expect(ReminderService.urgency(for: completed, on: referenceDate) == .completed)
    }
}
