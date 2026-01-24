import UserNotifications
import SwiftUI

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // 1. Demander la permission
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Permission notifications accordée")
                // On programme tout par défaut si l'utilisateur accepte
                DispatchQueue.main.async {
                    self.scheduleAllNotifications()
                }
            } else {
                print("Permission refusée: \(String(describing: error))")
            }
        }
    }
    
    // 2. Programmer TOUTES les notifications
    func scheduleAllNotifications() {
        // Nettoyage préalable
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        scheduleDailyReminder()
        scheduleWeeklyRecap()
        scheduleMonthlyReport()
    }
    
    // Annuler tout (si on décoche dans les réglages)
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // --- A. RAPPEL QUOTIDIEN (Lundi -> Vendredi à 19h00) ---
    private func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Oubli ? ✍️")
        content.body = String(localized: "Avez-vous travaillé aujourd'hui ? Ajoutez vos heures pour mettre à jour votre planning.")
        content.sound = .default
        
        // 2=Lundi ... 6=Vendredi
        for weekday in 2...6 {
            var dateComponents = DateComponents()
            dateComponents.weekday = weekday
            dateComponents.hour = 19
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "daily_reminder_\(weekday)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    // --- B. BILAN HEBDOMADAIRE (Dimanche à 20h00) ---
    private func scheduleWeeklyRecap() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Bilan de la semaine 📊")
        content.body = String(localized: "Votre récapitulatif est prêt ! Découvrez vos heures et vos pas de la semaine.")
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Dimanche
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_recap", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    // --- C. BILAN MENSUEL (Le 1er du mois à 09h00) ---
    private func scheduleMonthlyReport() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Salaire du mois disponible 💰")
        content.body = String(localized: "Le mois est terminé. Venez consulter votre estimation de salaire net !")
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.day = 1 // Le 1er
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "monthly_report", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    // 3. GESTION DU CLIC (Redirection vers le bon onglet)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let id = response.notification.request.identifier
        
        DispatchQueue.main.async {
            if id == "weekly_recap" {
                NotificationCenter.default.post(name: NSNotification.Name("OpenAnalyseTab"), object: nil)
            } else if id == "monthly_report" {
                NotificationCenter.default.post(name: NSNotification.Name("OpenSalaryTab"), object: nil)
            } else if id.contains("daily_reminder") {
                NotificationCenter.default.post(name: NSNotification.Name("OpenPlanningTab"), object: nil)
            }
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
