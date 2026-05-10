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
    static let lifetimeUnlockProductID = PurchaseCatalog.lifetimeUnlockProductID

    @Published private(set) var isUnlocked: Bool
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInProgress = false
    @Published private(set) var lifetimeUnlockProduct: Product?
    @Published var lastError: UserFacingError?

    private static let storedLifetimeUnlockKey = "rentory.hasVerifiedLifetimeUnlock"
    private let defaults: UserDefaults
    private var transactionListenerTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isUnlocked = defaults.bool(forKey: Self.storedLifetimeUnlockKey)
        transactionListenerTask = listenForTransactions()

        Task {
            await refreshEntitlements()
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
            products = try await fetchProducts()
            lifetimeUnlockProduct = products.first(where: { $0.id == Self.lifetimeUnlockProductID })

            if lifetimeUnlockProduct == nil {
                lastError = .purchaseCouldNotBeChecked
            }
        } catch {
            products = []
            lifetimeUnlockProduct = nil
            lastError = .purchaseCouldNotBeChecked
        }
    }

    func refreshEntitlements() async {
        let hasLifetimeUnlock = await hasVerifiedLifetimeUnlock()
        setUnlocked(hasLifetimeUnlock)
    }

    func purchaseLifetimeUnlock() async {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        if isUnlocked {
            return
        }

        if await hasVerifiedLifetimeUnlock() {
            setUnlocked(true)
            return
        }

        guard let product = lifetimeUnlockProduct else {
            lastError = .purchaseCouldNotBeChecked
            return
        }

        await purchaseStoreKitProduct(product)
    }

    func restorePurchases() async {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()

            if !isUnlocked {
                lastError = .purchaseCouldNotBeRestored
            }
        } catch {
            lastError = .purchaseCouldNotBeRestored
        }
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

        if transaction.productID == Self.lifetimeUnlockProductID {
            setUnlocked(transaction.revocationDate == nil)
        }

        await transaction.finish()
    }

    private func hasVerifiedLifetimeUnlock() async -> Bool {
        for await verification in Transaction.currentEntitlements(for: Self.lifetimeUnlockProductID) {
            guard let transaction = verifiedTransaction(from: verification), transaction.revocationDate == nil else {
                continue
            }
            return true
        }

        guard let latestVerification = await Transaction.latest(for: Self.lifetimeUnlockProductID),
              let latestTransaction = verifiedTransaction(from: latestVerification),
              latestTransaction.revocationDate == nil else {
            return false
        }

        return true
    }

    private func verifiedTransaction(from verification: VerificationResult<Transaction>) -> Transaction? {
        switch verification {
        case .verified(let transaction):
            transaction
        case .unverified:
            nil
        }
    }

    private func fetchProducts() async throws -> [Product] {
        for attempt in 0..<3 {
            let loadedProducts = try await Product.products(for: [Self.lifetimeUnlockProductID])
                .sorted { $0.displayName < $1.displayName }

            if !loadedProducts.isEmpty {
                return loadedProducts
            }

            if attempt < 2 {
                try? await Task.sleep(for: .milliseconds(350))
            }
        }

        return []
    }

    private func purchaseStoreKitProduct(_ product: Product) async {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                guard let transaction = verifiedTransaction(from: verification) else {
                    lastError = .purchaseCouldNotBeChecked
                    return
                }

                guard transaction.productID == Self.lifetimeUnlockProductID,
                      transaction.revocationDate == nil else {
                    lastError = .purchaseCouldNotBeChecked
                    return
                }

                setUnlocked(true)
                lastError = nil
                await transaction.finish()
            case .userCancelled:
                lastError = .purchaseCancelled
            case .pending:
                lastError = .purchaseNotCompleted
            @unknown default:
                lastError = .purchaseNotCompleted
            }
        } catch {
            lastError = .purchaseNotCompleted
        }
    }

    private func setUnlocked(_ newValue: Bool) {
        isUnlocked = newValue
        defaults.set(newValue, forKey: Self.storedLifetimeUnlockKey)
    }
}
