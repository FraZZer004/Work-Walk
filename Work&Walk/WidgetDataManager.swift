import Foundation
import WidgetKit

struct WidgetDataManager {
    // ⚠️ Vérifie que c'est bien ton App Group exact
    static let appGroup = "group.com.alan.WorkAndWalk"
    
    enum Keys {
        static let steps = "widget_steps"
        static let hours = "widget_hours"
        static let calories = "widget_calories"
        static let salary = "widget_salary"
        static let lastUpdateDate = "widget_last_date" // 👈 La clé magique
    }
    
    // SAUVEGARDE
    static func save(steps: Double, hours: String, calories: Double, salary: Double) {
        guard let defaults = UserDefaults(suiteName: appGroup) else { return }
        
        defaults.set(steps, forKey: Keys.steps)
        defaults.set(hours, forKey: Keys.hours)
        defaults.set(calories, forKey: Keys.calories)
        defaults.set(salary, forKey: Keys.salary)
        defaults.set(Date(), forKey: Keys.lastUpdateDate) // On marque l'heure !
        
        WidgetCenter.shared.reloadAllTimelines()
        print("💾 Widget Sauvegardé : \(hours) - \(salary)€")
    }
    
    // LECTURE (C'est ici qu'on vide les données périmées)
    static func load() -> (steps: Double, hours: String, calories: Double, salary: Double) {
        guard let defaults = UserDefaults(suiteName: appGroup) else {
            return (0, "0h", 0, 0)
        }
        
        // 1. On vérifie la date de la dernière sauvegarde
        let lastDate = defaults.object(forKey: Keys.lastUpdateDate) as? Date ?? Date.distantPast
        let calendar = Calendar.current
        
        // 🚨 SI CE N'EST PAS AUJOURD'HUI : On renvoie des zéros !
        if !calendar.isDateInToday(lastDate) {
            print("⚠️ Données datent d'hier. Reset affichage Widget.")
            return (0, "0h", 0, 0)
        }
        
        // 2. Sinon, on renvoie les vraies données
        let steps = defaults.double(forKey: Keys.steps)
        let hours = defaults.string(forKey: Keys.hours) ?? "0h"
        let calories = defaults.double(forKey: Keys.calories)
        let salary = defaults.double(forKey: Keys.salary)
        
        return (steps, hours, calories, salary)
    }
}
