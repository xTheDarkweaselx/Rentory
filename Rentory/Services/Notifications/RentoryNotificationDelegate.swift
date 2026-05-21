//
//  RentoryNotificationDelegate.swift
//  Rentory
//
//  Bridges UNUserNotificationCenter taps + foreground presentation into
//  the rest of the app. Owned by RentoryApp; set as the global UN
//  delegate at launch so notification taps reliably reach the deep link
//  router.
//

import Foundation
import Combine
import UserNotifications

@MainActor
final class RentoryNotificationDelegate: NSObject, ObservableObject {
    private weak var router: RentoryDeepLinkRouter?

    /// Attach the router this delegate forwards to. Called once from
    /// RentoryApp after both objects are available. Passing weak so
    /// the delegate doesn't extend the router's lifetime artificially.
    func attach(router: RentoryDeepLinkRouter) {
        self.router = router
    }
}

extension RentoryNotificationDelegate: @preconcurrency UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show the banner + play sound even while Rentory is foregrounded;
        // missing today's reminder because the user happens to be in the
        // app is worse than a tiny banner interruption.
        return [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        router?.handleNotificationUserInfo(userInfo)
    }
}
