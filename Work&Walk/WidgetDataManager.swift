import Foundation
import WidgetKit

struct WidgetDataManager {
    // 👇 Ton App Group (C'est parfait, ne change rien)
    static let appGroup = "group.com.alan.WorkAndWalk"
    
    enum Keys {
        static let steps = "widget_steps"
        static let hours = "widget_hours"
        static let calories = "widget_calories"
        static let salary = "widget_salary" // 👈 AJOUTÉ
        static let lastUpdate = "widget_lastUpdate"
    }
    
    // J'ai ajouté le paramètre 'salary' ici
    static func save(steps: Double, hours: String, calories: Double, salary: Double) {
        print("💾 SAUVEGARDE WIDGET (Background/Foregound)...")
        
        guard let sharedDefaults = UserDefaults(suiteName: appGroup) else {
            print("❌ ERREUR : Impossible d'accéder au App Group")
            return
        }
        
        sharedDefaults.set(steps, forKey: Keys.steps)
        sharedDefaults.set(hours, forKey: Keys.hours)
        sharedDefaults.set(calories, forKey: Keys.calories)
        sharedDefaults.set(salary, forKey: Keys.salary) // 👈 AJOUTÉ
        sharedDefaults.set(Date(), forKey: Keys.lastUpdate)
        
        // Force le widget à se mettre à jour
        WidgetCenter.shared.reloadAllTimelines()
        print("✅ Widget notifié avec succès (Salaire: \(salary)€)")
    }
    
    static func load() -> (steps: Double, hours: String, calories: Double, salary: Double) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroup) else {
            return (0, "0h 0m", 0, 0.0)
        }
        
        let steps = sharedDefaults.double(forKey: Keys.steps)
        let hours = sharedDefaults.string(forKey: Keys.hours) ?? "0h 0m"
        let calories = sharedDefaults.double(forKey: Keys.calories)
        let salary = sharedDefaults.double(forKey: Keys.salary) // 👈 AJOUTÉ
        
        return (steps, hours, calories, salary)
    }
}
