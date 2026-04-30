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
    @Published var alertMessage: String?

    private let appLockService: AppLockService
    private let userDefaults: UserDefaults
    private let lockDelay: TimeInterval
    private let appLockPreferenceKey = "isAppLockEnabled"

    init(
        appLockService: AppLockService = AppLockService(),
        userDefaults: UserDefaults = .standard,
        lockDelay: TimeInterval = 30
    ) {
        self.appLockService = appLockService
        self.userDefaults = userDefaults
        self.lockDelay = lockDelay

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
            if isAppLockEnabled, shouldLockAfterBackground {
                isLocked = true
            }
            shouldShowPrivacyCover = isLocked
        case .inactive:
            shouldShowPrivacyCover = true
        case .background:
            lastBackgroundedAt = .now
            shouldShowPrivacyCover = true
        @unknown default:
            break
        }
    }

    func unlockApp() async {
        guard isAppLockEnabled else {
            isLocked = false
            shouldShowPrivacyCover = false
            return
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let didAuthenticate = try await appLockService.authenticate()

            if didAuthenticate {
                isLocked = false
                shouldShowPrivacyCover = false
                alertMessage = nil
            } else {
                alertMessage = "Rentory could not be unlocked. Try again when you are ready."
            }
        } catch let error as AppLockError {
            alertMessage = error.errorDescription
        } catch {
            alertMessage = "Rentory could not be unlocked. Try again when you are ready."
        }
    }

    func setAppLockEnabled(_ isEnabled: Bool) async -> Bool {
        guard isEnabled != isAppLockEnabled else {
            return true
        }

        guard isAppLockAvailable else {
            alertMessage = AppLockError.notAvailable.errorDescription
            return false
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let didAuthenticate = try await appLockService.authenticate()

            guard didAuthenticate else {
                alertMessage = "Rentory could not be unlocked. Try again when you are ready."
                return false
            }

            persistAppLockPreference(isEnabled)
            isAppLockEnabled = isEnabled
            isLocked = false
            shouldShowPrivacyCover = false
            alertMessage = nil

            if !isEnabled {
                lastBackgroundedAt = nil
                isLocked = false
                shouldShowPrivacyCover = false
            }

            return true
        } catch let error as AppLockError {
            alertMessage = error.errorDescription
            return false
        } catch {
            alertMessage = "Rentory could not be unlocked. Try again when you are ready."
            return false
        }
    }

    private var shouldLockAfterBackground: Bool {
        guard let lastBackgroundedAt else {
            return true
        }

        return Date().timeIntervalSince(lastBackgroundedAt) >= lockDelay
    }

    private func persistAppLockPreference(_ isEnabled: Bool) {
        userDefaults.set(isEnabled, forKey: appLockPreferenceKey)
    }
}
