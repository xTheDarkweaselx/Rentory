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
    static let debugLifetimeUnlockKey = "debugLifetimeUnlockActive"

    @Published private(set) var isUnlocked = false
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInProgress = false
    @Published private(set) var lifetimeUnlockOffer: LocalStoreKitOffer?
    @Published var lastError: UserFacingError?

    private var transactionListenerTask: Task<Void, Never>?
    private let userDefaults: UserDefaults
    private let localStoreKitConfiguration = LocalStoreKitConfiguration()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        transactionListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updatePurchasedProducts()
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
            lifetimeUnlockOffer = makeOffer(from: products.first(where: { $0.id == Self.lifetimeUnlockProductID }))

            if products.isEmpty, lifetimeUnlockOffer == nil {
                lastError = .purchaseCouldNotBeChecked
            }
        } catch {
            products = []
            lifetimeUnlockOffer = localStoreKitConfiguration.lifetimeUnlockOffer()

            if lifetimeUnlockOffer == nil {
                lastError = .purchaseCouldNotBeChecked
            }
        }
    }

    func purchaseLifetimeUnlock() async {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        if let product = products.first(where: { $0.id == Self.lifetimeUnlockProductID }) {
            await purchaseStoreKitProduct(product)
            return
        }

        guard lifetimeUnlockOffer != nil else {
            lastError = .purchaseCouldNotBeChecked
            return
        }

#if DEBUG
        userDefaults.set(true, forKey: Self.debugLifetimeUnlockKey)
        isUnlocked = true
#else
        lastError = .purchaseCouldNotBeChecked
#endif
    }

    func restorePurchases() async {
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()

            if !isUnlocked {
#if DEBUG
                if userDefaults.bool(forKey: Self.debugLifetimeUnlockKey) {
                    isUnlocked = true
                } else {
                    lastError = .purchaseCouldNotBeRestored
                }
#else
                lastError = .purchaseCouldNotBeRestored
#endif
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

        isUnlocked = hasLifetimeUnlock || userDefaults.bool(forKey: Self.debugLifetimeUnlockKey)
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

        if let fallbackOffer = localStoreKitConfiguration.lifetimeUnlockOffer() {
            lifetimeUnlockOffer = fallbackOffer
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

                userDefaults.set(false, forKey: Self.debugLifetimeUnlockKey)
                isUnlocked = true
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

    private func makeOffer(from product: Product?) -> LocalStoreKitOffer? {
        if let product {
            return LocalStoreKitOffer(
                productID: product.id,
                displayName: product.displayName,
                description: product.description,
                displayPrice: product.displayPrice
            )
        }

        return localStoreKitConfiguration.lifetimeUnlockOffer()
    }
}
struct LocalStoreKitOffer {
    let productID: String
    let displayName: String
    let description: String
    let displayPrice: String
}

private struct LocalStoreKitConfiguration {
    private struct ConfigurationFile: Decodable {
        struct ProductConfiguration: Decodable {
            struct Localization: Decodable {
                let description: String
                let displayName: String
                let locale: String
            }

            let displayPrice: String?
            let localizations: [Localization]
            let productID: String
        }

        struct Settings: Decodable {
            let locale: String?

            private enum CodingKeys: String, CodingKey {
                case locale = "_locale"
            }
        }

        let products: [ProductConfiguration]
        let settings: Settings?
    }

    func lifetimeUnlockOffer() -> LocalStoreKitOffer? {
        guard
            let url = Bundle.main.url(forResource: "Rentory", withExtension: "storekit"),
            let data = try? Data(contentsOf: url),
            let configuration = try? JSONDecoder().decode(ConfigurationFile.self, from: data),
            let product = configuration.products.first(where: { $0.productID == PurchaseCatalog.lifetimeUnlockProductID })
        else {
            return nil
        }

        let localisation = product.localizations.first(where: { $0.locale == configuration.settings?.locale })
            ?? product.localizations.first

        let localeIdentifier = localisation?.locale ?? configuration.settings?.locale ?? "en_GB"
        let formattedPrice = formatPrice(product.displayPrice, localeIdentifier: localeIdentifier)

        return LocalStoreKitOffer(
            productID: product.productID,
            displayName: localisation?.displayName ?? "Rentory Lifetime Unlock",
            description: localisation?.description ?? "Unlock unlimited rental records, rooms, photos, full reports and App Lock.",
            displayPrice: formattedPrice ?? "£14.99"
        )
    }

    private func formatPrice(_ rawPrice: String?, localeIdentifier: String) -> String? {
        guard let rawPrice, let amount = Decimal(string: rawPrice) else {
            return nil
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.currencyCode = currencyCode(for: localeIdentifier)

        return formatter.string(from: amount as NSDecimalNumber)
    }

    private func currencyCode(for localeIdentifier: String) -> String {
        switch localeIdentifier {
        case "en_GB":
            return "GBP"
        default:
            return Locale(identifier: localeIdentifier).currency?.identifier ?? "GBP"
        }
    }
}
