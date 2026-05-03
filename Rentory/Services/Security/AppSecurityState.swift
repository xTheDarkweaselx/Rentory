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
    private let lockDelay: TimeInterval
    private let appLockPreferenceKey = "isAppLockEnabled"

    convenience init() {
        self.init(
            appLockService: AppLockService(),
            userDefaults: .standard,
            lockDelay: 30
        )
    }

    init(
        appLockService: AppLockService,
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
                alertContent = nil
            } else {
                alertContent = DialogCopy.appUnlockFailed
            }
        } catch let error as AppLockError {
            alertContent = alertContent(for: error)
        } catch {
            alertContent = DialogCopy.appUnlockFailed
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
            let didAuthenticate = try await appLockService.authenticate()

            guard didAuthenticate else {
                alertContent = DialogCopy.appUnlockFailed
                return false
            }

            persistAppLockPreference(isEnabled)
            isAppLockEnabled = isEnabled
            isLocked = false
            shouldShowPrivacyCover = false
            alertContent = nil

            if !isEnabled {
                lastBackgroundedAt = nil
                isLocked = false
                shouldShowPrivacyCover = false
            }

            return true
        } catch let error as AppLockError {
            alertContent = alertContent(for: error)
            return false
        } catch {
            alertContent = DialogCopy.appUnlockFailed
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

    private func alertContent(for error: AppLockError) -> RRAlertContent {
        switch error {
        case .notAvailable:
            DialogCopy.appLockUnavailable
        case .unableToUnlock, .tryAgainLater:
            DialogCopy.appUnlockFailed
        }
    }
}
