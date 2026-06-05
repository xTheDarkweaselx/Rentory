//
//  RentorySnapshotPublisher.swift
//  Rentory
//
//  Owns building RentorySharedSnapshot from the main app's SwiftData
//  context and writing it to the shared App Group container. Triggered:
//    - On app launch (.task)
//    - On scene-active (so edits made elsewhere on the device are picked up)
//    - After Reminder save / delete / complete via the existing notification
//      reschedule flow
//
//  The publisher's design is intentionally synchronous and idempotent.
//  Multiple back-to-back triggers produce identical files.
//

import Foundation
import SwiftData
#if canImport(WidgetKit)
import WidgetKit
#endif

@MainActor
final class RentorySnapshotPublisher {
    private let calendar: Calendar
    private let maxProperties: Int
    private let maxUpcomingReminders: Int
    private let upcomingReminderWindowDays: Int

    init(
        calendar: Calendar = .autoupdatingCurrent,
        maxProperties: Int = 20,
        maxUpcomingReminders: Int = 20,
        upcomingReminderWindowDays: Int = 21
    ) {
        self.calendar = calendar
        self.maxProperties = maxProperties
        self.maxUpcomingReminders = maxUpcomingReminders
        self.upcomingReminderWindowDays = upcomingReminderWindowDays
    }

    func publish(context: ModelContext, activeProfile: RentoryUserProfile) {
        let snapshot = makeSnapshot(context: context, activeProfile: activeProfile)
        try? RentorySharedSnapshotStore.write(snapshot)
        onPublish?(snapshot)
        #if canImport(WidgetKit)
        // Nudge Home Screen / StandBy widgets to re-read the snapshot we
        // just wrote. Without this they only refresh on their own timeline
        // cadence (midnight / +4h / +6h), so a freshly added reminder or
        // payment — or a profile switch — would otherwise show stale data
        // until the next scheduled refresh.
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    /// Optional hook fired after each successful publish. Used to mirror the
    /// snapshot to the paired Apple Watch via WatchSyncService without
    /// coupling the publisher to WatchConnectivity directly.
    var onPublish: ((RentorySharedSnapshot) -> Void)?

    /// NotificationCenter name posted by feature views after any
    /// `try modelContext.save()` that mutates data the widgets, watch
    /// surfaces or upcoming-reminder snapshot care about. RootView
    /// listens and republishes using the current model context and
    /// active profile.
    static let snapshotShouldRepublish = Notification.Name("rentorySnapshotShouldRepublish")

    /// Post the republish notification. Call this after a save that
    /// changes records visible to widgets / watch. Cheap — the publisher
    /// debounces by virtue of being idempotent.
    static func requestRepublish() {
        NotificationCenter.default.post(name: snapshotShouldRepublish, object: nil)
    }

    /// Pure builder, separated so tests can drive it without filesystem
    /// side effects.
    func makeSnapshot(
        context: ModelContext,
        activeProfile: RentoryUserProfile,
        now: Date = .now
    ) -> RentorySharedSnapshot {
        let propertyPacks = (try? context.fetch(FetchDescriptor<PropertyPack>())) ?? []
        let scopedPropertyPacks = propertyPacks.filter { $0.profileRawValue == activeProfile.rawValue }
        // Reminders + counts are scoped to the active profile so widgets,
        // watch surfaces and the upcoming-reminder list never reference
        // a property the user can't see in their current profile.
        let reminderEntries = upcomingReminderEntries(from: scopedPropertyPacks, now: now)
        let totalReminderCount = scopedPropertyPacks
            .flatMap(\.reminders)
            .filter { $0.completedAt == nil }
            .count

        let propertyEntries = scopedPropertyPacks
            .sorted { lhs, rhs in
                if lhs.isFavourite != rhs.isFavourite { return lhs.isFavourite && !rhs.isFavourite }
                return lhs.updatedAt > rhs.updatedAt
            }
            .prefix(maxProperties)
            .map { makePropertyEntry(for: $0, now: now) }

        return RentorySharedSnapshot(
            writtenAt: now,
            activeProfileRawValue: activeProfile.rawValue,
            totalReminderCount: totalReminderCount,
            properties: Array(propertyEntries),
            upcomingReminders: reminderEntries
        )
    }

    private func makePropertyEntry(for propertyPack: PropertyPack, now: Date) -> RentorySharedSnapshot.PropertyEntry {
        let score = CompletionScoreService.score(for: propertyPack)
        let recentEvent = propertyPack.timelineEvents
            .sorted { $0.eventDate > $1.eventDate }
            .first?.title

        let monthRentTotal: Double?
        let monthExpenseTotal: Double?
        let monthNetTotal: Double?
        let currencyCode: String?
        let activeTenancyCount: Int?
        let primaryTenant: String?
        let tenancyEndDate: Date?

        if propertyPack.profile == .landlord {
            let payments = propertyPack.tenancies
                .flatMap(\.rentPayments)
                .filter { $0.isPaid && calendar.isDate($0.paidDate ?? $0.dueDate, equalTo: now, toGranularity: .month) }
            let expenses = propertyPack.expenses
                .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }

            let rentIn = payments.reduce(0) { $0 + $1.amount }
            let expensesOut = expenses.reduce(0) { $0 + $1.amount }
            monthRentTotal = rentIn
            monthExpenseTotal = expensesOut
            monthNetTotal = rentIn - expensesOut
            currencyCode = propertyPack.expenses.first?.currencyCode
                ?? propertyPack.tenancies.flatMap(\.rentPayments).first?.currencyCode
                ?? "GBP"

            let activeTenancies = propertyPack.tenancies.filter { $0.status == .active }
            activeTenancyCount = activeTenancies.count
            let primary = activeTenancies
                .compactMap(\.primaryTenant)
                .map(\.name)
                .first
            primaryTenant = primary
            tenancyEndDate = activeTenancies.compactMap(\.endDate).min()
        } else {
            monthRentTotal = nil
            monthExpenseTotal = nil
            monthNetTotal = nil
            currencyCode = nil
            activeTenancyCount = nil
            primaryTenant = nil
            tenancyEndDate = nil
        }

        return RentorySharedSnapshot.PropertyEntry(
            id: propertyPack.id,
            nickname: propertyPack.nickname,
            recordTypeRawValue: propertyPack.recordTypeRawValue,
            profileRawValue: propertyPack.profileRawValue,
            isFavourite: propertyPack.isFavourite,
            completionPercent: score.percentage,
            completionStatusTitle: score.statusTitle,
            nextActionTitle: score.suggestedNextItems.first,
            recentEventTitle: recentEvent,
            activeTenancyCount: activeTenancyCount,
            primaryTenantName: primaryTenant,
            tenancyEndDate: tenancyEndDate,
            monthRentReceived: monthRentTotal,
            monthExpenses: monthExpenseTotal,
            monthNet: monthNetTotal,
            currencyCode: currencyCode
        )
    }

    private func upcomingReminderEntries(from propertyPacks: [PropertyPack], now: Date) -> [RentorySharedSnapshot.ReminderEntry] {
        let windowEnd = calendar.date(byAdding: .day, value: upcomingReminderWindowDays, to: now) ?? now

        let candidates: [RentorySharedSnapshot.ReminderEntry] = propertyPacks.flatMap { pack in
            pack.reminders.compactMap { reminder -> RentorySharedSnapshot.ReminderEntry? in
                guard reminder.completedAt == nil,
                      let dueDate = reminder.dueDate,
                      dueDate <= windowEnd else {
                    return nil
                }
                return RentorySharedSnapshot.ReminderEntry(
                    id: reminder.id,
                    propertyID: pack.id,
                    propertyNickname: pack.nickname,
                    title: reminder.title,
                    kindRawValue: reminder.kindRawValue,
                    priorityRawValue: reminder.priorityRawValue,
                    dueDate: dueDate
                )
            }
        }

        return Array(candidates.sorted { $0.dueDate < $1.dueDate }.prefix(maxUpcomingReminders))
    }
}
