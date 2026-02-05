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
            
            HealthProfileView()
                            .tabItem { Label("Profil", systemImage: "person.crop.circle") }.tag(4)
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
            
            let todaysSessions = sessions.filter { calendar.isDate($0.startTime, inSameDayAs: today) }
            
            let totalSeconds = todaysSessions.reduce(0) { $0 + ($1.endTime?.timeIntervalSince($1.startTime) ?? 0) }
            let totalHours = totalSeconds / 3600.0
            
            let hourlyRate = UserDefaults.standard.double(forKey: "hourlyRate")
            let rateToUse = hourlyRate > 0 ? hourlyRate : 11.91
            let calculatedSalary = totalHours * rateToUse
            
            let hoursString = totalSeconds > 0 ? String(format: "%.1fh", totalHours) : "0h"
            
            // On récupère les pas actuels
            let currentSteps = HealthManager.shared.stepsToday
            
            // 👇 CALCUL CALORIES PERSONNALISÉ ICI AUSSI 👇
            let userWeight = UserDefaults.standard.double(forKey: "userWeight")
            let weight = userWeight > 0 ? userWeight : 70.0
            
            // Formule : Si tu fais 100kg, tu brûles 1.4x plus qu'une personne de 70kg
            let caloriesFactor = (weight / 70.0) * 0.04
            let calories = Double(currentSteps) * caloriesFactor
            
            print("🔄 APP -> WIDGET : \(calories) kcal (Poids: \(weight)kg)")
            
            WidgetDataManager.save(
                steps: Double(currentSteps),
                hours: hoursString,
                calories: calories,
                salary: calculatedSalary
            )
            
            UserDefaults.standard.set(calculatedSalary, forKey: "manual_today_salary")
            UserDefaults.standard.set(hoursString, forKey: "manual_today_hours")
            UserDefaults.standard.set(Date(), forKey: "manual_today_date")
        }
}
