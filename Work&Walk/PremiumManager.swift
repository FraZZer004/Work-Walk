import SwiftUI
import Combine

class PremiumManager: ObservableObject {
    static let shared = PremiumManager()
    
    @Published var isPremium: Bool {
        didSet {
            UserDefaults.standard.set(isPremium, forKey: "isPremiumUser")
        }
    }
    
    private init() {
        // On vérifie d'abord si l'admin a débloqué l'app, sinon on prend la valeur normale
        let adminUnlocked = UserDefaults.standard.bool(forKey: "is_admin_premium")
        if adminUnlocked {
            self.isPremium = true
        } else {
            self.isPremium = UserDefaults.standard.bool(forKey: "isPremiumUser")
        }
    }
    
    // --- RÈGLES DE BRIDAGE ---
    func canViewDetailedMetrics() -> Bool { isPremium }
    func canExportSalaryPDF() -> Bool { isPremium }
    
    func canViewHistory(for date: Date) -> Bool {
        if isPremium { return true }
        let calendar = Calendar.current
        let now = Date()
        guard let startOfCurrentWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let startOfAllowedWindow = calendar.date(byAdding: .day, value: -7, to: startOfCurrentWeek)
        else { return true }
        return calendar.compare(date, to: startOfAllowedWindow, toGranularity: .day) != .orderedAscending
    }
}
