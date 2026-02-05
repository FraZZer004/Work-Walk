import UserNotifications
import SwiftUI
import SwiftData // 👈 AJOUT IMPORTANT si WorkSession est un modèle SwiftData

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
                    self.scheduleAllNotifications()
                }
            }
        }
    }
    
    func scheduleAllNotifications() {
        scheduleStaticNotifications()
        updateContextualNotifications(isNewUser: false)
    }
    
    // 2. Les notifications FIXES
    func scheduleStaticNotifications() {
        // ... (Garde ton code existant ici pour hebdo/mensuel) ...
        // Je ne le remets pas pour raccourcir, mais ne l'efface pas !
        let contentHebdo = UNMutableNotificationContent()
        contentHebdo.title = String(localized: "Bilan de la semaine 📊")
        contentHebdo.body = String(localized: "Votre récapitulatif est prêt ! Découvrez vos stats.")
        contentHebdo.sound = .default
        var dateHebdo = DateComponents(); dateHebdo.weekday = 1; dateHebdo.hour = 20; dateHebdo.minute = 0
        let trigHebdo = UNCalendarNotificationTrigger(dateMatching: dateHebdo, repeats: true)
        let reqHebdo = UNNotificationRequest(identifier: "weekly_recap", content: contentHebdo, trigger: trigHebdo)

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
    
    // 3. Les notifications INTELLIGENTES
    func updateContextualNotifications(isNewUser: Bool) {
        // ... (Garde ton code existant ici pour lundi/daily) ...
        // Je ne le remets pas pour raccourcir, mais ne l'efface pas !
        let center = UNUserNotificationCenter.current()
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
        
        let contentDaily = UNMutableNotificationContent()
        contentDaily.sound = .default
        if isNewUser {
            contentDaily.title = String(localized: "Première étape ✍️")
            contentDaily.body = String(localized: "N'oubliez pas de noter vos horaires pour calculer votre salaire.")
        } else {
            contentDaily.title = String(localized: "Oubli ? ✍️")
            contentDaily.body = String(localized: "Avez-vous travaillé aujourd'hui ? Ajoutez vos heures.")
        }
        for weekday in 2...6 {
            var dateDaily = DateComponents(); dateDaily.weekday = weekday; dateDaily.hour = 19; dateDaily.minute = 0
            let trigDaily = UNCalendarNotificationTrigger(dateMatching: dateDaily, repeats: true)
            let reqDaily = UNNotificationRequest(identifier: "daily_reminder_\(weekday)", content: contentDaily, trigger: trigDaily)
            center.add(reqDaily)
        }
    }

    // 👇 4. NOUVELLE FONCTION : RAPPEL PLANNING DEMAIN
    // On doit passer les sessions (pour savoir quand tu travailles)
    // et l'heure du rappel (choisie dans les réglages)
    func scheduleTomorrowReminders(sessions: [WorkSession], reminderTime: Date) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        
        // A. On récupère l'heure/minute choisie par l'utilisateur
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)
        
        // B. On filtre les sessions futures uniquement
        let futureSessions = sessions.filter { $0.startTime > Date() }
        
        // C. On groupe par jour (pour éviter 2 notifs si tu fais matin + après-midi le même jour)
        let groupedSessions = Dictionary(grouping: futureSessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
        
        // D. Pour chaque jour travaillé, on programme une notif la VEILLE
        for (workDate, sessionsInDay) in groupedSessions {
            // Calcul de la date de la veille (WorkDate - 1 jour)
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: workDate) else { continue }
            
            // On fixe l'heure du rappel
            var triggerComponents = calendar.dateComponents([.year, .month, .day], from: previousDay)
            triggerComponents.hour = hour
            triggerComponents.minute = minute
            
            // Sécurité : Si le rappel est déjà passé (ex: on est le soir, rappel prévu le matin), on ignore
            if let triggerDate = calendar.date(from: triggerComponents), triggerDate < Date() {
                continue
            }
            
            // Construction du message (ex: "08:00 - 17:00")
            let sortedSessions = sessionsInDay.sorted { $0.startTime < $1.startTime }
            var timeString = ""
            if let start = sortedSessions.first, let end = sortedSessions.last {
                let s = start.startTime.formatted(date: .omitted, time: .shortened)
                let e = end.endTime?.formatted(date: .omitted, time: .shortened) ?? "..."
                timeString = "\(s) - \(e)"
            }
            
            let content = UNMutableNotificationContent()
            content.title = String(localized: "📅 Demain au boulot !")
            content.body = String(localized: "Horaires prévus : \(timeString)")
            content.sound = .default
            
            // Identifiant unique basé sur la date du travail (ex: "work_reminder_2024-10-25")
            // Cela permet d'écraser l'ancienne notif si tu changes tes horaires pour ce jour-là
            let id = "work_reminder_\(workDate.timeIntervalSince1970)"
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            
            center.add(request)
        }
        
        print("✅ Rappels planning programmés pour \(groupedSessions.count) jours futurs.")
    }
    
    // GESTION DU CLIC
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let id = response.notification.request.identifier
        
        DispatchQueue.main.async {
            if id == "weekly_recap" {
                NotificationCenter.default.post(name: NSNotification.Name("OpenAnalyseTab"), object: nil)
            } else if id == "monthly_report" {
                NotificationCenter.default.post(name: NSNotification.Name("OpenSalaryTab"), object: nil)
            } else if id.contains("daily_reminder") || id == "monday_motivation" || id.contains("work_reminder") {
                NotificationCenter.default.post(name: NSNotification.Name("OpenPlanningTab"), object: nil)
            }
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    // À ajouter tout en bas de NotificationManager.swift
        
        // Fonction pour annuler toutes les notifications (utilisée par les Réglages)
        func cancelAll() {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            print("🛑 Toutes les notifications futures ont été annulées.")
        }
} // Fin de la classe

