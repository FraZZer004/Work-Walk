import Foundation
import StoreKit
import Combine

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published var subscriptions: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    
    private var updateListenerTask: Task<Void, Error>? = nil
    let productIDs = ["workwalk_premium_annual", "workwalk_premium_monthly"]
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await fetchProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func fetchProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIDs)
            self.subscriptions = storeProducts.sorted(by: { $0.price < $1.price })
        } catch {
            print("❌ Erreur StoreKit : \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            _ = try checkVerified(verification)
            await updatePurchasedProducts()
        default: break
        }
    }
    
    func updatePurchasedProducts() async {
        var newPurchasedProductIDs = Set<String>()
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate == nil {
                newPurchasedProductIDs.insert(transaction.productID)
            }
        }
        self.purchasedProductIDs = newPurchasedProductIDs
        
        // Sécurité Master : On ne met à jour via Apple QUE si l'admin n'a pas déjà forcé le mode
        if !UserDefaults.standard.bool(forKey: "is_admin_premium") {
            PremiumManager.shared.isPremium = !newPurchasedProductIDs.isEmpty
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let safe): return safe
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    _ = try await self.checkVerified(result)
                    await self.updatePurchasedProducts()
                } catch {
                    print("Transaction update error")
                }
            }
        }
    }
}

// 👇 C'EST CE PETIT BOUT DE CODE QUI TE MANQUAIT
enum StoreError: Error {
    case failedVerification
}
