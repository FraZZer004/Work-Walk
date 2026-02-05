import SwiftUI
import SwiftData
import PhotosUI

struct ContentView: View {
    @AppStorage("selectedAppearance") private var selectedAppearance: Int = 0
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    
    // On observe toutes les sessions (Planning complet)
    @Query private var sessions: [WorkSession]
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Accueil", systemImage: "chart.bar.xaxis") }.tag(0)
            
            PlanningView()
                .tabItem { Label("Planning", systemImage: "calendar") }.tag(1)
            
            AnalysisView()
                .tabItem { Label("Analyse", systemImage: "heart.text.square") }.tag(2)
            
            SalaryView()
                .tabItem { Label("Salaire", systemImage: "eurosign.circle.fill") }.tag(3)
        }
        .tint(.orange)
        .preferredColorScheme(selectedAppearance == 1 ? .light : (selectedAppearance == 2 ? .dark : nil))
        .environment(\.locale, Locale(identifier: selectedLanguage))
        .id(selectedLanguage)
        
        // --- C'EST ICI QUE TOUT SE JOUE ---
        .onAppear {
            NotificationManager.shared.requestAuthorization()
            updateNotificationsContext()
            syncWidgetWithApp() // 👈 Mise à jour immédiate du widget au lancement
        }
        .onChange(of: sessions) { _, _ in
            // Dès qu'on ajoute/modifie une session, on lance les mises à jour :
            updateNotificationsContext()
            syncWidgetWithApp() // 👈 Mise à jour du widget en temps réel
        }
    }
    
    // 1. GESTION DES NOTIFICATIONS
    func updateNotificationsContext() {
        NotificationManager.shared.updateContextualNotifications(isNewUser: sessions.isEmpty)
    }
    
    // 2. SYNCHRONISATION DU WIDGET (La fonction magique)
    func syncWidgetWithApp() {
        let calendar = Calendar.current
        let today = Date()
        
        // A. On ne prend QUE les sessions d'aujourd'hui
        let todaysSessions = sessions.filter { calendar.isDate($0.startTime, inSameDayAs: today) }
        
        // B. Calcul des Heures
        let totalSeconds = todaysSessions.reduce(0) { $0 + ($1.endTime?.timeIntervalSince($1.startTime) ?? 0) }
        let totalHours = totalSeconds / 3600.0
        
        // C. Calcul du Salaire (On récupère le taux depuis les réglages)
        let hourlyRate = UserDefaults.standard.double(forKey: "hourlyRate")
        let rateToUse = hourlyRate > 0 ? hourlyRate : 11.91
        let calculatedSalary = totalHours * rateToUse
        
        // Formatage "0h" ou "5.5h"
        let hoursString = totalSeconds > 0 ? String(format: "%.1fh", totalHours) : "0h"
        
        // D. On récupère les pas actuels (via HealthManager) pour ne pas afficher 0 pas
        // Si HealthManager n'est pas accessible ici, on met 0, le background corrigera les pas plus tard.
        let currentSteps = HealthManager.shared.stepsToday
        let calories = Double(currentSteps) * 0.04
        
        print("🔄 APP -> WIDGET : Envoi de \(hoursString) / \(calculatedSalary)€")
        
        // E. On sauvegarde DIRECTEMENT dans le Widget (Mise à jour visuelle immédiate)
        WidgetDataManager.save(
            steps: Double(currentSteps),
            hours: hoursString,
            calories: calories,
            salary: calculatedSalary
        )
        
        // F. On sauvegarde dans la MÉMOIRE TAMPON (Pour le Background HealthKit)
        // Comme ça, quand l'iPhone est verrouillé, HealthManager saura qu'il doit réafficher ces heures-là.
        UserDefaults.standard.set(calculatedSalary, forKey: "manual_today_salary")
        UserDefaults.standard.set(hoursString, forKey: "manual_today_hours")
        UserDefaults.standard.set(Date(), forKey: "manual_today_date") // La date sert à vérifier si c'est périmé demain
    }
}
