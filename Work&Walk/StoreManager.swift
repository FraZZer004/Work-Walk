import Foundation
import StoreKit
import Combine

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published var subscriptions: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var isPremium: Bool = false
    
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
    
    // 1. CHARGEMENT
    func fetchProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIDs)
            self.subscriptions = storeProducts.sorted(by: { $0.price < $1.price })
        } catch {
            print("❌ Erreur StoreKit : \(error)")
        }
    }
    
    // 2. ACHAT
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Ici on est dans une fonction async du MainActor, donc l'appel est direct
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
        case .userCancelled, .pending:
            break
        default:
            break
        }
    }
    
    // 3. RESTAURATION
    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }
    
    // 4. VÉRIFICATION
    func updatePurchasedProducts() async {
        var newPurchasedProductIDs = Set<String>()
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate == nil {
                newPurchasedProductIDs.insert(transaction.productID)
            }
        }
        
        self.purchasedProductIDs = newPurchasedProductIDs
        
        // Logique Admin vs Apple
        if UserDefaults.standard.bool(forKey: "is_admin_premium") {
            PremiumManager.shared.isPremium = true
            self.isPremium = true
        } else {
            let hasActiveSubscription = !newPurchasedProductIDs.isEmpty
            PremiumManager.shared.isPremium = hasActiveSubscription
            self.isPremium = hasActiveSubscription
        }
    }
    
    // 👇 LE FIX EST ICI : "nonisolated"
    // Cela permet à la fonction d'être appelée depuis la Task.detached sans erreur
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let safe): return safe
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        // Task.detached tourne en arrière-plan
        Task.detached {
            for await result in Transaction.updates {
                do {
                    // Grâce à 'nonisolated', on peut appeler checkVerified ici sans 'await'
                    let transaction = try self.checkVerified(result)
                    
                    // Pour mettre à jour l'UI, on doit repasser sur le MainActor (await)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction update error")
                }
            }
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
