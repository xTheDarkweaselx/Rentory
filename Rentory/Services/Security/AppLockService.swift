//
//  AppLockService.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Foundation
import LocalAuthentication

enum AppLockError: LocalizedError {
    case notAvailable
    case unableToUnlock
    case tryAgainLater

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "App Lock is not available on this device."
        case .unableToUnlock:
            return "Rentory could not be unlocked."
        case .tryAgainLater:
            return "Try again when you are ready."
        }
    }
}

struct AppLockService {
    func isAuthenticationAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?

        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    func authenticate(reason: String = "Unlock Rentory to view your rental records.") async throws -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw AppLockError.notAvailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, evaluationError in
                if success {
                    continuation.resume(returning: true)
                    return
                }

                if let laError = evaluationError as? LAError {
                    switch laError.code {
                    case .authenticationFailed, .userCancel, .userFallback, .systemCancel, .appCancel:
                        continuation.resume(returning: false)
                    case .biometryNotAvailable, .biometryNotEnrolled, .passcodeNotSet, .biometryLockout:
                        continuation.resume(throwing: AppLockError.notAvailable)
                    default:
                        continuation.resume(throwing: AppLockError.unableToUnlock)
                    }

                    return
                }

                if evaluationError != nil {
                    continuation.resume(throwing: AppLockError.unableToUnlock)
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }
}
