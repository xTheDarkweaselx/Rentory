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
            return UserFacingError.appLockNotAvailable.message
        case .unableToUnlock:
            return UserFacingError.appCouldNotBeUnlocked.title
        case .tryAgainLater:
            return UserFacingError.appCouldNotBeUnlocked.message
        }
    }
}

struct AppLockService {
    func isAuthenticationAvailable() -> Bool {
        let context = configuredContext()
        var error: NSError?
        return context.canEvaluatePolicy(primaryPolicy, error: &error)
    }

    func authenticate(reason: String = "Unlock your rental records.") async throws -> Bool {
        let context = configuredContext()
        var error: NSError?
        var policy = primaryPolicy

        if !context.canEvaluatePolicy(policy, error: &error) {
            if shouldRetryWithPasswordFallback(after: error) {
                policy = .deviceOwnerAuthentication
                error = nil

                guard context.canEvaluatePolicy(policy, error: &error) else {
                    throw mappedError(from: error)
                }
            } else {
                throw mappedError(from: error)
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(policy, localizedReason: reason) { success, evaluationError in
                if success {
                    continuation.resume(returning: true)
                    return
                }

                if let evaluationError = evaluationError as? NSError,
                   shouldRetryWithPasswordFallback(after: evaluationError) {
                    let fallbackContext = configuredContext()
                    fallbackContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { fallbackSuccess, fallbackError in
                        handleEvaluationResult(
                            success: fallbackSuccess,
                            error: fallbackError,
                            continuation: continuation
                        )
                    }
                    return
                }

                handleEvaluationResult(
                    success: success,
                    error: evaluationError,
                    continuation: continuation
                )
            }
        }
    }

    private var primaryPolicy: LAPolicy {
        .deviceOwnerAuthenticationWithBiometrics
    }

    private func configuredContext() -> LAContext {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        #if os(macOS)
        context.localizedFallbackTitle = "Use Password"
        context.touchIDAuthenticationAllowableReuseDuration = 10
        #else
        context.localizedFallbackTitle = "Use Passcode"
        #endif

        return context
    }

    private func shouldRetryWithPasswordFallback(after error: Error?) -> Bool {
        #if os(macOS)
        guard let laError = error as? LAError else { return false }
        return laError.code == .biometryLockout || laError.code == .userFallback
        #else
        return false
        #endif
    }

    private func mappedError(from error: Error?) -> AppLockError {
        guard let laError = error as? LAError else {
            return .notAvailable
        }

        switch laError.code {
        case .biometryNotAvailable, .biometryNotEnrolled, .passcodeNotSet:
            return .notAvailable
        case .biometryLockout:
            return .tryAgainLater
        default:
            return .unableToUnlock
        }
    }
}

private func handleEvaluationResult(
    success: Bool,
    error: Error?,
    continuation: CheckedContinuation<Bool, Error>
) {
    if success {
        continuation.resume(returning: true)
        return
    }

    if let laError = error as? LAError {
        switch laError.code {
        case .authenticationFailed, .userCancel, .userFallback, .systemCancel, .appCancel:
            continuation.resume(returning: false)
        case .biometryNotAvailable, .biometryNotEnrolled, .passcodeNotSet:
            continuation.resume(throwing: AppLockError.notAvailable)
        case .biometryLockout:
            continuation.resume(throwing: AppLockError.tryAgainLater)
        default:
            continuation.resume(throwing: AppLockError.unableToUnlock)
        }
        return
    }

    if error != nil {
        continuation.resume(throwing: AppLockError.unableToUnlock)
    } else {
        continuation.resume(returning: false)
    }
}
