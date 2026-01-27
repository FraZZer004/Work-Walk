import SwiftUI
import SwiftData
import PhotosUI

struct ContentView: View {
    @AppStorage("selectedAppearance") private var selectedAppearance: Int = 0
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
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
        .onAppear { NotificationManager.shared.requestAuthorization(); updateNotificationsContext() }
        .onChange(of: sessions.count) { _, _ in updateNotificationsContext() }
    }
    
    func updateNotificationsContext() { NotificationManager.shared.updateContextualNotifications(isNewUser: sessions.isEmpty) }
}
