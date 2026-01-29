import Foundation
import WidgetKit

import Foundation
import WidgetKit

struct WidgetDataManager {
    // 👇 REMPLACE ÇA PAR TON VRAI GROUPE (copie-le depuis Signing & Capabilities)
    static let appGroup = "group.com.alan.WorkAndWalk"

    
    enum Keys {
        static let steps = "widget_steps"
        static let hours = "widget_hours"
        static let calories = "widget_calories"
        static let lastUpdate = "widget_lastUpdate"
    }
    
    static func save(steps: Double, hours: String, calories: Double) {
        print("💾 TENTATIVE DE SAUVEGARDE WIDGET...")
        print("   - Pas: \(steps)")
        
        guard let sharedDefaults = UserDefaults(suiteName: appGroup) else {
            print("❌ ERREUR CRITIQUE : Impossible d'accéder au App Group '\(appGroup)'")
            return
        }
        
        sharedDefaults.set(steps, forKey: Keys.steps)
        sharedDefaults.set(hours, forKey: Keys.hours)
        sharedDefaults.set(calories, forKey: Keys.calories)
        sharedDefaults.set(Date(), forKey: Keys.lastUpdate)
        
        print("✅ DONNÉES ÉCRITES DANS USERDEFAULTS !")
        
        WidgetCenter.shared.reloadAllTimelines()
        print("🔄 DEMANDE DE MISE À JOUR DU WIDGET ENVOYÉE")
    }
    
    static func load() -> (steps: Double, hours: String, calories: Double) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroup) else {
            print("❌ WIDGET : Impossible de lire le App Group")
            return (0, "0h 0m", 0)
        }
        
        let steps = sharedDefaults.double(forKey: Keys.steps)
        print("📥 WIDGET A LU : \(steps) pas")
        
        let hours = sharedDefaults.string(forKey: Keys.hours) ?? "0h 0m"
        let calories = sharedDefaults.double(forKey: Keys.calories)
        
        return (steps, hours, calories)
    }
}
