import SwiftUI
import SwiftData
import PhotosUI

struct ContentView: View {
    @AppStorage("selectedAppearance") private var selectedAppearance: Int = 0
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    @Query private var sessions: [WorkSession]
    @State private var selectedTab: Int = 0
    
    // 👇 INDISPENSABLE : Rend les barres systèmes transparentes
    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().standardAppearance = tabBarAppearance
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().standardAppearance = navBarAppearance
    }
    
    var body: some View {
        ZStack {
            // 1. LE FOND (Derrière tout)
            GlowBackground()
                .ignoresSafeArea()
            
            // 2. L'APPLICATION (Devant)
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
            .onAppear {
                NotificationManager.shared.requestAuthorization()
                updateNotificationsContext()
                syncWidgetWithApp()
            }
            .onChange(of: sessions) { _, _ in
                updateNotificationsContext()
                syncWidgetWithApp()
            }
        }
    }
    
    func updateNotificationsContext() { NotificationManager.shared.updateContextualNotifications(isNewUser: sessions.isEmpty) }
    
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
        let currentSteps = HealthManager.shared.stepsToday
        let userWeight = UserDefaults.standard.double(forKey: "userWeight")
        let weight = userWeight > 0 ? userWeight : 70.0
        let caloriesFactor = (weight / 70.0) * 0.04
        let calories = Double(currentSteps) * caloriesFactor
        
        WidgetDataManager.save(steps: Double(currentSteps), hours: hoursString, calories: calories, salary: calculatedSalary)
        UserDefaults.standard.set(calculatedSalary, forKey: "manual_today_salary")
        UserDefaults.standard.set(hoursString, forKey: "manual_today_hours")
        UserDefaults.standard.set(Date(), forKey: "manual_today_date")
    }
}
