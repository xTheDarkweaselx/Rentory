//
//  AppSecurityState.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class AppSecurityState: ObservableObject {
    @Published private(set) var isAppLockEnabled: Bool
    @Published var isLocked: Bool
    @Published var isAuthenticating = false
    @Published var lastBackgroundedAt: Date?
    @Published var shouldShowPrivacyCover: Bool
    @Published var alertContent: RRAlertContent?

    private let appLockService: AppLockService
    private let userDefaults: UserDefaults
    private let appLockPreferenceKey = "isAppLockEnabled"

    convenience init() {
        self.init(
            appLockService: AppLockService(),
            userDefaults: .standard
        )
    }

    init(
        appLockService: AppLockService,
        userDefaults: UserDefaults = .standard
    ) {
        self.appLockService = appLockService
        self.userDefaults = userDefaults

        let storedPreference = userDefaults.bool(forKey: appLockPreferenceKey)
        let isAvailable = appLockService.isAuthenticationAvailable()

        self.isAppLockEnabled = storedPreference && isAvailable
        self.isLocked = storedPreference && isAvailable
        self.shouldShowPrivacyCover = storedPreference && isAvailable

        if storedPreference && !isAvailable {
            userDefaults.set(false, forKey: appLockPreferenceKey)
        }
    }

    var isAppLockAvailable: Bool {
        appLockService.isAuthenticationAvailable()
    }

    func handleScenePhaseChange(_ scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            if isAppLockEnabled, lastBackgroundedAt != nil {
                isLocked = true
                shouldShowPrivacyCover = true
            } else {
                shouldShowPrivacyCover = isLocked
            }
        case .inactive:
            shouldShowPrivacyCover = true
        case .background:
            lastBackgroundedAt = .now
            if isAppLockEnabled {
                isLocked = true
            }
            shouldShowPrivacyCover = true
        @unknown default:
            break
        }
    }

    func unlockApp() async {
        guard isAppLockEnabled else {
            isLocked = false
            shouldShowPrivacyCover = false
            lastBackgroundedAt = nil
            return
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let didAuthenticate = try await appLockService.authenticate()

            if didAuthenticate {
                isLocked = false
                shouldShowPrivacyCover = false
                lastBackgroundedAt = nil
                alertContent = nil
            } else {
                alertContent = DialogCopy.appLockStillOn
            }
        } catch let error as AppLockError {
            alertContent = alertContent(for: error)
        } catch {
            alertContent = DialogCopy.appLockStillOn
        }
    }

    func setAppLockEnabled(_ isEnabled: Bool) async -> Bool {
        guard isEnabled != isAppLockEnabled else {
            return true
        }

        guard isAppLockAvailable else {
            alertContent = DialogCopy.appLockUnavailable
            return false
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let didAuthenticate = try await appLockService.authenticate(
                reason: isEnabled
                    ? "Confirm it is you before turning on App Lock."
                    : "Confirm it is you before turning off App Lock."
            )

            guard didAuthenticate else {
                alertContent = isEnabled ? DialogCopy.appLockNotTurnedOn : DialogCopy.appLockStillOn
                return false
            }

            persistAppLockPreference(isEnabled)
            isAppLockEnabled = isEnabled
            lastBackgroundedAt = nil

            if isEnabled {
                isLocked = false
                shouldShowPrivacyCover = false
                alertContent = DialogCopy.appLockTurnedOn
            } else {
                lastBackgroundedAt = nil
                isLocked = false
                shouldShowPrivacyCover = false
                alertContent = DialogCopy.appLockTurnedOff
            }

            return true
        } catch let error as AppLockError {
            if case .notAvailable = error {
                alertContent = DialogCopy.appLockUnavailable
            } else {
                alertContent = isEnabled ? DialogCopy.appLockNotTurnedOn : DialogCopy.appLockStillOn
            }
            return false
        } catch {
            alertContent = isEnabled ? DialogCopy.appLockNotTurnedOn : DialogCopy.appLockStillOn
            return false
        }
    }

    private func persistAppLockPreference(_ isEnabled: Bool) {
        userDefaults.set(isEnabled, forKey: appLockPreferenceKey)
    }

    private func alertContent(for error: AppLockError) -> RRAlertContent {
        switch error {
        case .notAvailable:
            DialogCopy.appLockUnavailable
        case .unableToUnlock, .tryAgainLater:
            DialogCopy.appLockStillOn
        }
    }
}
