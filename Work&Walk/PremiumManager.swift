import SwiftUI
import Combine

class PremiumManager: ObservableObject {
    static let shared = PremiumManager()
    
    // On utilise @Published pour que l'interface se mette à jour instantanément
    @Published var isPremium: Bool {
        didSet {
            // Dès que la variable change, on sauvegarde dans la mémoire du téléphone
            UserDefaults.standard.set(isPremium, forKey: "isPremiumUser")
        }
    }
    
    // Initialisation : on charge la valeur sauvegardée au démarrage
    private init() {
        self.isPremium = UserDefaults.standard.bool(forKey: "isPremiumUser")
    }
    
    // --- RÈGLES DE BRIDAGE ---
    
    // 1. ANALYSE & SANTÉ
    func canViewDetailedMetrics() -> Bool {
        return isPremium
    }
    
    // 2. SALAIRE
    func canExportSalaryPDF() -> Bool {
        return isPremium
    }
    
    // 3. HISTORIQUE (Fenêtre Glissante)
    func canViewHistory(for date: Date) -> Bool {
        if isPremium { return true }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Calcul de la fenêtre autorisée (Semaine courante + précédente)
        guard let startOfCurrentWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let startOfAllowedWindow = calendar.date(byAdding: .day, value: -7, to: startOfCurrentWeek)
        else { return true }
        
        return calendar.compare(date, to: startOfAllowedWindow, toGranularity: .day) != .orderedAscending
    }
}
