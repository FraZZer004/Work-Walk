import SwiftUI
import Foundation

// 1. Catégories réordonnées et recolorées en nuances d'orange
enum TrophyCategory: String, CaseIterable {
    // L'ordre ici détermine l'ordre d'affichage dans l'écran Succès
    case health = "Pas"
    case sessions = "Assiduité"
    case time = "Temps de Travail"
    case money = "Fortune"
    
    // Une palette monochrome "Sunset" (Coucher de soleil)
    var themeColor: Color {
        switch self {
        case .health:
            return Color.orange // L'orange standard de ton app (Dynamique)
            
        case .sessions:
            // Un orange plus "Rouge/Saumon" pour varier
            return Color(red: 1.0, green: 0.4, blue: 0.4)
            
        case .time:
            // Un orange "Jaune/Ambre" (Or)
            return Color(red: 1.0, green: 0.75, blue: 0.0)
            
        case .money:
            // Un orange "Brun/Cuivre" (Bronze/Pièce)
            return Color(red: 0.8, green: 0.4, blue: 0.0)
        }
    }
}

// 2. Le modèle
struct Trophy: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let category: TrophyCategory
    let threshold: Double
    let progress: Double
    var isUnlocked: Bool
}

class TrophyManager {
    static let shared = TrophyManager()
    
    func checkTrophies(sessions: [WorkSession], healthManager: HealthManager?) -> [TrophyCategory: [Trophy]] {
        
        // --- A. CALCULS DES TOTAUX ---
        
        let totalSessions = Double(sessions.count)
        
        let totalHours = sessions.reduce(into: 0.0) { total, session in
            let duration = session.endTime?.timeIntervalSince(session.startTime) ?? 0
            total += duration
        } / 3600.0
        
        // Calcul réel des pas (basé sur ton modèle mis à jour)
        let totalSteps = sessions.reduce(into: 0.0) { total, session in
            total += session.steps
        }
        
        // (Calcul du salaire si dispo, sinon 0)
        let totalEarnings = 0.0
        
        var allTrophies: [Trophy] = []
        
        // --- B. DÉFINITION DES TROPHÉES ---
        
        // 1. SANTÉ & PAS (Désormais en premier) 👣
        let stepsData = [
            (50_000, "Échauffement"),
            (100_000, "Randonneur"),
            (500_000, "Marathonien"),
            (1_000_000, "Millionnaire de Pas"),
            (2_500_000, "Globe Trotter"),
            (5_000_000, "Forrest Gump"),
            (10_000_000, "Voyageur Lunaire")
        ]
        
        for (threshold, title) in stepsData {
            allTrophies.append(Trophy(
                title: title,
                description: "\(formatNumber(threshold)) pas cumulés.",
                icon: "figure.walk",
                category: .health,
                threshold: Double(threshold),
                progress: totalSteps,
                isUnlocked: totalSteps >= Double(threshold)
            ))
        }
        
        // 2. SESSIONS (Assiduité) 🗓️
        let sessionData = [
            (1, "Premier Jour"),
            (10, "L'Habitué"),
            (50, "Salarié Modèle"),
            (100, "Meuble du Bureau"),
            (365, "Année Complète")
        ]
        for (threshold, title) in sessionData {
            allTrophies.append(Trophy(
                title: title,
                description: "\(threshold) sessions enregistrées.",
                icon: "calendar.badge.checkmark",
                category: .sessions,
                threshold: Double(threshold),
                progress: totalSessions,
                isUnlocked: totalSessions >= Double(threshold)
            ))
        }
        
        // 3. TEMPS ⏳
        let timeData = [
            (10, "Stagiaire"),
            (50, "Bosseur"),
            (100, "Stakhanoviste"),
            (500, "Pilier de l'entreprise"),
            (1000, "Légende vivante")
        ]
        for (threshold, title) in timeData {
            allTrophies.append(Trophy(
                title: title,
                description: "\(threshold) heures de travail.",
                icon: "clock.fill",
                category: .time,
                threshold: Double(threshold),
                progress: totalHours,
                isUnlocked: totalHours >= Double(threshold)
            ))
        }
        
        // 4. ARGENT (En dernier) 💰
        let moneyData = [
            (100, "Tirelire"),
            (1000, "Premier Salaire"),
            (5000, "Nouveau Riche"),
            (10000, "Loup de Wall Street"),
            (50000, "Empire")
        ]
        for (threshold, title) in moneyData {
            allTrophies.append(Trophy(
                title: title,
                description: "\(threshold)€ générés.",
                icon: "banknote.fill",
                category: .money,
                threshold: Double(threshold),
                progress: totalEarnings,
                isUnlocked: totalEarnings >= Double(threshold)
            ))
        }
        
        // --- C. REGROUPEMENT ---
        var grouped: [TrophyCategory: [Trophy]] = [:]
        for category in TrophyCategory.allCases {
            grouped[category] = allTrophies.filter { $0.category == category }
        }
        return grouped
    }
    
    // Fonction utilitaire de formatage
    func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
