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
                print("Permission accordée")
                DispatchQueue.main.async {
                    // On lance tout par défaut
                    self.scheduleAllNotifications()
                }
            }
        }
    }
    
    // 👇 C'EST CETTE FONCTION QUI MANQUAIT !
    // Elle sert de "pont" pour que SettingsView et ContentView ne plantent pas.
    func scheduleAllNotifications() {
        // 1. On lance les notifs fixes (Dimanche + Mensuel)
        scheduleStaticNotifications()
        
        // 2. On lance les notifs intelligentes (Lundi + Semaine)
        // Par défaut, on considère que c'est un "Ancien" utilisateur (standard)
        // Le ContentView affinera ça au prochain lancement de l'app si besoin.
        updateContextualNotifications(isNewUser: false)
    }
    
    // 2. Les notifications FIXES (Bilan Hebdo & Mensuel)
    func scheduleStaticNotifications() {
        // Bilan Hebdo (Dimanche 20h)
        let contentHebdo = UNMutableNotificationContent()
        contentHebdo.title = String(localized: "Bilan de la semaine 📊")
        contentHebdo.body = String(localized: "Votre récapitulatif est prêt ! Découvrez vos stats.")
        contentHebdo.sound = .default
        var dateHebdo = DateComponents(); dateHebdo.weekday = 1; dateHebdo.hour = 20; dateHebdo.minute = 0
        let trigHebdo = UNCalendarNotificationTrigger(dateMatching: dateHebdo, repeats: true)
        let reqHebdo = UNNotificationRequest(identifier: "weekly_recap", content: contentHebdo, trigger: trigHebdo)
        
        // Bilan Mensuel (1er du mois 09h)
        let contentMensuel = UNMutableNotificationContent()
        contentMensuel.title = String(localized: "Salaire du mois disponible 💰")
        contentMensuel.body = String(localized: "Le mois est terminé. Venez consulter votre estimation de salaire net !")
        contentMensuel.sound = .default
        var dateMensuel = DateComponents(); dateMensuel.day = 1; dateMensuel.hour = 9; dateMensuel.minute = 0
        let trigMensuel = UNCalendarNotificationTrigger(dateMatching: dateMensuel, repeats: true)
        let reqMensuel = UNNotificationRequest(identifier: "monthly_report", content: contentMensuel, trigger: trigMensuel)
        
        UNUserNotificationCenter.current().add(reqHebdo)
        UNUserNotificationCenter.current().add(reqMensuel)
    }
    
    // 3. Les notifications INTELLIGENTES (Lundi matin + Rappel Saisie)
    func updateContextualNotifications(isNewUser: Bool) {
        let center = UNUserNotificationCenter.current()
        
        // A. MOTIVATION LUNDI (08h00)
        let contentMonday = UNMutableNotificationContent()
        if isNewUser {
            contentMonday.title = String(localized: "Bienvenue ! 👋")
            contentMonday.body = String(localized: "C'est lundi ! Ajoutez votre première session pour commencer.")
        } else {
            contentMonday.title = String(localized: "Nouvelle semaine ! 🚀")
            contentMonday.body = String(localized: "Allez ! Fais en sorte de te surpasser cette semaine !")
        }
        contentMonday.sound = .default
        var dateMonday = DateComponents(); dateMonday.weekday = 2; dateMonday.hour = 8; dateMonday.minute = 0
        let trigMonday = UNCalendarNotificationTrigger(dateMatching: dateMonday, repeats: true)
        let reqMonday = UNNotificationRequest(identifier: "monday_motivation", content: contentMonday, trigger: trigMonday)
        center.add(reqMonday)
        
        // B. RAPPEL SAISIE (Semaine 19h00)
        let contentDaily = UNMutableNotificationContent()
        contentDaily.sound = .default
        if isNewUser {
            contentDaily.title = String(localized: "Première étape ✍️")
            contentDaily.body = String(localized: "N'oubliez pas de noter vos horaires pour calculer votre salaire.")
        } else {
            contentDaily.title = String(localized: "Oubli ? ✍️")
            contentDaily.body = String(localized: "Avez-vous travaillé aujourd'hui ? Ajoutez vos heures.")
        }
        
        for weekday in 2...6 { // Lundi à Vendredi
            var dateDaily = DateComponents(); dateDaily.weekday = weekday; dateDaily.hour = 19; dateDaily.minute = 0
            let trigDaily = UNCalendarNotificationTrigger(dateMatching: dateDaily, repeats: true)
            let reqDaily = UNNotificationRequest(identifier: "daily_reminder_\(weekday)", content: contentDaily, trigger: trigDaily)
            center.add(reqDaily)
        }
    }
    
    // 4. GESTION DU CLIC
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let id = response.notification.request.identifier
        
        DispatchQueue.main.async {
            if id == "weekly_recap" {
                NotificationCenter.default.post(name: NSNotification.Name("OpenAnalyseTab"), object: nil)
            } else if id == "monthly_report" {
                NotificationCenter.default.post(name: NSNotification.Name("OpenSalaryTab"), object: nil)
            } else if id.contains("daily_reminder") || id == "monday_motivation" {
                NotificationCenter.default.post(name: NSNotification.Name("OpenPlanningTab"), object: nil)
            }
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
