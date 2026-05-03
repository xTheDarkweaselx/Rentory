//
//  EntitlementManager.swift
//  Rentory
//
//  Created by Adam Ibrahim on 30/04/2026.
//

import Combine
import Foundation
import StoreKit

@MainActor
final class EntitlementManager: ObservableObject {
    static let lifetimeUnlockProductID = "com.fusionstudios.rentory.lifetimeunlock"

    @Published private(set) var isUnlocked = false
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInProgress = false
    @Published var lastError: UserFacingError?

    private var transactionListenerTask: Task<Void, Never>?

    init() {
        transactionListenerTask = listenForTransactions()

        Task {
            await updatePurchasedProducts()
            await loadProducts()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // For local testing, attach a StoreKit configuration file to the Rentory scheme in Xcode
    // and use Debug > StoreKit > Manage Transactions to reset the lifetime unlock state.
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            products = try await Product.products(for: [Self.lifetimeUnlockProductID])
                .sorted { $0.displayName < $1.displayName }
        } catch {
            products = []
            lastError = .purchaseCouldNotBeChecked
        }
    }

    func purchaseLifetimeUnlock() async {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        guard let product = await lifetimeUnlockProduct() else {
            lastError = .purchaseCouldNotBeChecked
            return
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                guard let transaction = verifiedTransaction(from: verification) else {
                    lastError = .purchaseCouldNotBeChecked
                    return
                }

                isUnlocked = true
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                lastError = .purchaseNotCompleted
            @unknown default:
                lastError = .purchaseNotCompleted
            }
        } catch {
            lastError = .purchaseNotCompleted
        }
    }

    func restorePurchases() async {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()

            if !isUnlocked {
                lastError = .purchaseCouldNotBeRestored
            }
        } catch {
            lastError = .purchaseCouldNotBeRestored
        }
    }

    func updatePurchasedProducts() async {
        var hasLifetimeUnlock = false

        for await verification in Transaction.currentEntitlements {
            guard let transaction = verifiedTransaction(from: verification) else {
                continue
            }

            guard transaction.revocationDate == nil else {
                continue
            }

            if transaction.productID == Self.lifetimeUnlockProductID {
                hasLifetimeUnlock = true
            }
        }

        isUnlocked = hasLifetimeUnlock
    }

    func clearLastError() {
        lastError = nil
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            guard let self else { return }

            for await verification in Transaction.updates {
                guard !Task.isCancelled else { return }
                await self.handleTransactionUpdate(verification)
            }
        }
    }

    private func handleTransactionUpdate(_ verification: VerificationResult<Transaction>) async {
        guard let transaction = verifiedTransaction(from: verification) else {
            return
        }

        if transaction.productID == Self.lifetimeUnlockProductID, transaction.revocationDate == nil {
            isUnlocked = true
        } else if transaction.productID == Self.lifetimeUnlockProductID {
            isUnlocked = false
        }

        await transaction.finish()
    }

    private func verifiedTransaction(from verification: VerificationResult<Transaction>) -> Transaction? {
        switch verification {
        case .verified(let transaction):
            transaction
        case .unverified:
            nil
        }
    }

    private func lifetimeUnlockProduct() async -> Product? {
        if let product = products.first(where: { $0.id == Self.lifetimeUnlockProductID }) {
            return product
        }

        await loadProducts()
        return products.first(where: { $0.id == Self.lifetimeUnlockProductID })
    }
}
