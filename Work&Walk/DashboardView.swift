import SwiftUI
import SwiftData
import Charts
import HealthKit

struct DashboardView: View {
    @State private var healthManager = HealthManager()
    @Query(sort: \WorkSession.startTime, order: .reverse) private var sessions: [WorkSession]
    @State private var weeklyData: [DailyActivity] = []
    
    // États
    @State private var showSettings = false
    @State private var showEditDashboard = false
    @State private var showTrophies = false
    @State private var showShareSheet = false
    
    @AppStorage("username") private var username: String = "Utilisateur"
    @AppStorage("dashboardWidgetsJSON") private var widgetsJSON: String = ""
    @AppStorage("userProfileImage") private var userProfileImageBase64: String = ""
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    
    @State private var widgets: [DashboardWidget] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    
                    headerView          // 1. Profil
                    statsSummaryView    // 2. Résumé Pas/Heures
                    
                    // 3. Graphiques Dynamiques
                    ForEach(widgets) { widget in
                        if widget.isVisible {
                            DynamicChartCard(type: widget.type, data: weeklyData)
                        }
                    }
                    
                    updateButtonView    // 4. Bouton mise à jour
                }
                .padding(.top)
                .padding(.bottom, 50)
            }
            .navigationTitle("Tableau de Bord")
            .toolbar { toolbarContent }
            // --- MODALES ---
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showEditDashboard) { DashboardConfigView(widgets: $widgets) }
            .sheet(isPresented: $showTrophies) { TrophiesView() }
            .sheet(isPresented: $showShareSheet) {
                ShareReceiptSheet(
                    steps: Int(healthManager.stepsToday),
                    hours: calculateTodayWorkHours(),
                    salary: 0.0,
                    calories: Int(healthManager.caloriesToday)
                )
            }
            // --- CHARGEMENT ---
            .onAppear {
                loadWidgets()
                healthManager.requestAuthorization()
                calculateWeeklyStats()
                NotificationManager.shared.requestAuthorization()
            }
            .onChange(of: widgets) { _, _ in saveWidgets() }
        }
    }
    
    // --- SOUS-VUES ---
    
    var headerView: some View {
        HStack(spacing: 15) {
            if let avatar = userAvatar {
                Image(uiImage: avatar).resizable().scaledToFill().frame(width: 50, height: 50).clipShape(Circle()).overlay(Circle().stroke(Color.orange, lineWidth: 2))
            } else {
                ZStack { Circle().fill(Color(UIColor.systemGray5)).frame(width: 50, height: 50); Image(systemName: "person.fill").foregroundStyle(.gray).font(.title3) }
            }
            VStack(alignment: .leading) {
                Text("Bonjour,").font(.subheadline).foregroundStyle(.secondary)
                Text(username.isEmpty ? "Bienvenue" : username).font(.largeTitle).bold().foregroundStyle(.primary).lineLimit(1).minimumScaleFactor(0.8)
            }
            Spacer()
            Button(action: { showEditDashboard = true }) { Image(systemName: "list.bullet.circle.fill").font(.system(size: 32)).foregroundStyle(.orange.opacity(0.8)) }
        }.padding(.horizontal).padding(.top, 10)
    }
    
    var statsSummaryView: some View {
        HStack(spacing: 15) {
            statCard(icon: "figure.walk", color: .orange, title: "Pas Auj.", value: "\(Int(healthManager.stepsToday))")
            statCard(icon: "briefcase.fill", color: .orange, title: "Travail Auj.", value: calculateTodayWorkHours())
        }.padding(.horizontal)
    }
    
    var updateButtonView: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium); generator.impactOccurred()
            calculateWeeklyStats()
            syncStepsForAllSessions()
            WidgetDataManager.save(
                    steps: healthManager.stepsToday,
                    hours: calculateTodayWorkHours(),
                    calories: healthManager.caloriesToday
                )
        }) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath").font(.title3).fontWeight(.bold)
                Text("Actualiser les données").font(.headline).fontWeight(.bold)
            }
            .frame(maxWidth: .infinity).padding()
            .background(LinearGradient(colors: [.orange, .orange.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .foregroundStyle(.white).cornerRadius(16).shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
        }.padding(.horizontal).padding(.top, 10).padding(.bottom, 20)
    }
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 16) {
                Button { showShareSheet = true } label: { Image(systemName: "square.and.arrow.up.circle.fill").symbolRenderingMode(.palette).foregroundStyle(.white, .blue).font(.system(size: 28)) }
                Button { showTrophies = true } label: { Image(systemName: "trophy.circle.fill").symbolRenderingMode(.palette).foregroundStyle(.white, .orange).font(.system(size: 28)) }
                Button { showSettings = true } label: { Image(systemName: "gearshape.fill").foregroundStyle(.gray).font(.system(size: 22)) }
            }
        }
    }
    
    // --- LOGIQUE & HELPERS ---
    
    var userAvatar: UIImage? {
        if !userProfileImageBase64.isEmpty, let data = Data(base64Encoded: userProfileImageBase64) { return UIImage(data: data) }
        return nil
    }
    
    func loadWidgets() {
        if widgetsJSON.isEmpty {
            widgets = [ DashboardWidget(type: .steps, isVisible: true), DashboardWidget(type: .distance, isVisible: false), DashboardWidget(type: .calories, isVisible: true), DashboardWidget(type: .heart, isVisible: false) ]
        } else {
            if let data = widgetsJSON.data(using: .utf8), let decoded = try? JSONDecoder().decode([DashboardWidget].self, from: data) { widgets = decoded }
        }
    }
    func saveWidgets() { if let encoded = try? JSONEncoder().encode(widgets), let jsonString = String(data: encoded, encoding: .utf8) { widgetsJSON = jsonString } }
    
    func statCard(icon: String, color: Color, title: String, value: String) -> some View {
        VStack(alignment: .leading) {
            HStack { Image(systemName: icon).foregroundStyle(color); Text(LocalizedStringKey(title)).font(.caption).foregroundStyle(.secondary) }
            Text(value).font(.system(size: 24, weight: .bold)).foregroundStyle(.primary)
        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color(UIColor.systemGray6)).cornerRadius(16)
    }
    
    func syncStepsForAllSessions() {
        if sessions.isEmpty { return }
        let group = DispatchGroup()
        for session in sessions {
            if let endTime = session.endTime {
                group.enter()
                healthManager.fetchQuantity(type: .stepCount, start: session.startTime, end: endTime) { count in
                    DispatchQueue.main.async { session.steps = count; group.leave() }
                }
            }
        }
    }
    
    func calculateTodayWorkHours() -> String {
        let today = Calendar.current.startOfDay(for: Date())
        if let session = sessions.first(where: { Calendar.current.isDate($0.startTime, inSameDayAs: today) }) {
            let end = session.endTime ?? Date(); let diff = end.timeIntervalSince(session.startTime); let h = Int(diff) / 3600; let m = (Int(diff) % 3600) / 60; return "\(h)h \(m)m"
        }
        return "0h 0m"
    }
    
    // 👇 FONCTION DE CALCUL (Avec prise en charge des ÉTAGES)
    func calculateWeeklyStats() {
        var newDailyData: [DailyActivity] = []
        let f = DateFormatter(); f.locale = Locale(identifier: selectedLanguage); f.dateFormat = "EE"
        let calendar = Calendar.current; let group = DispatchGroup()
        let today = Date()
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let isToday = calendar.isDateInToday(date); let dayName = isToday ? (selectedLanguage == "en" ? "Today" : "Auj.") : f.string(from: date)
            let startOfDay = calendar.startOfDay(for: date); guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }
            group.enter()
            
            var dWSteps: Double=0; var dLSteps: Double=0; var dWCal: Double=0; var dLCal: Double=0; var dWDist: Double=0; var dLDist: Double=0; var dWHeart: Double=0; var dLHeart: Double=0
            var dWFlights: Double=0; var dLFlights: Double=0 // 👈 Variables Étages
            
            if let session = sessions.first(where: { calendar.isDate($0.startTime, inSameDayAs: date) }) {
                let sStart = session.startTime; let sEnd = session.endTime ?? Date(); let iG = DispatchGroup()
                
                iG.enter(); healthManager.fetchQuantity(type: .stepCount, start: sStart, end: sEnd) { v in dWSteps=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .activeEnergyBurned, start: sStart, end: sEnd) { v in dWCal=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .distanceWalkingRunning, start: sStart, end: sEnd) { v in dWDist=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .heartRate, start: sStart, end: sEnd) { v in dWHeart=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .flightsClimbed, start: sStart, end: sEnd) { v in dWFlights=v; iG.leave() } // 👈 Fetch
                
                iG.enter(); healthManager.fetchQuantity(type: .stepCount, start: startOfDay, end: endOfDay) { v in dLSteps=max(0,v-dWSteps); iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .activeEnergyBurned, start: startOfDay, end: endOfDay) { v in dLCal=max(0,v-dWCal); iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .distanceWalkingRunning, start: startOfDay, end: endOfDay) { v in dLDist=max(0,v-dWDist); iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .heartRate, start: startOfDay, end: endOfDay) { v in dLHeart=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .flightsClimbed, start: startOfDay, end: endOfDay) { v in dLFlights=max(0,v-dWFlights); iG.leave() } // 👈 Fetch
                
                iG.notify(queue: .main) {
                    newDailyData.append(DailyActivity(id: UUID(), dayName: dayName, date: date, workSteps: dWSteps, personalSteps: dLSteps, workCal: dWCal, personalCal: dLCal, workDist: dWDist, personalDist: dLDist, workHeart: dWHeart, personalHeart: dLHeart, workFlights: dWFlights, personalFlights: dLFlights))
                    group.leave()
                }
            } else {
                let iG = DispatchGroup()
                iG.enter(); healthManager.fetchQuantity(type: .stepCount, start: startOfDay, end: endOfDay) { v in dLSteps=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .activeEnergyBurned, start: startOfDay, end: endOfDay) { v in dLCal=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .distanceWalkingRunning, start: startOfDay, end: endOfDay) { v in dLDist=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .heartRate, start: startOfDay, end: endOfDay) { v in dLHeart=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .flightsClimbed, start: startOfDay, end: endOfDay) { v in dLFlights=v; iG.leave() } // 👈 Fetch
                
                iG.notify(queue: .main) {
                    newDailyData.append(DailyActivity(id: UUID(), dayName: dayName, date: date, workSteps: 0, personalSteps: dLSteps, workCal: 0, personalCal: dLCal, workDist: 0, personalDist: dLDist, workHeart: 0, personalHeart: dLHeart, workFlights: 0, personalFlights: dLFlights))
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) { self.weeklyData = newDailyData.sorted(by: { $0.date < $1.date }) }
    }
}

// MARK: - COMPOSANTS INTERNES DU DASHBOARD

// Graphique Dynamique (CORRIGÉ : Switch Exhaustif avec .flights)
struct DynamicChartCard: View {
    let type: MetricType
    let data: [DailyActivity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: iconFor(type)).foregroundStyle(type.color).font(.title3)
                Text(LocalizedStringKey(type.title)).font(.headline).foregroundStyle(.primary)
                Spacer()
            }
            .padding(.top, 10).padding(.horizontal)
            
            Chart {
                ForEach(data) { day in
                    BarMark(x: .value("Jour", day.dayName), y: .value("Val", valueFor(day, type: type, isWork: true)))
                        .foregroundStyle(type.color)
                    
                    if type == .heart {
                        PointMark(x: .value("Jour", day.dayName), y: .value("Val", valueFor(day, type: type, isWork: false)))
                            .foregroundStyle(.gray.opacity(0.7))
                    } else {
                        BarMark(x: .value("Jour", day.dayName), y: .value("Val", valueFor(day, type: type, isWork: false)))
                            .foregroundStyle(Color.gray.opacity(0.3))
                    }
                }
            }
            .frame(height: 180).padding(.horizontal)
            
            HStack(spacing: 20) {
                Spacer()
                HStack(spacing: 5) { Circle().fill(type.color).frame(width: 8, height: 8); Text("Travail").font(.caption).foregroundStyle(.secondary) }
                HStack(spacing: 5) { Circle().fill(type == .heart ? Color.gray.opacity(0.7) : Color.gray.opacity(0.3)).frame(width: 8, height: 8); Text("Perso").font(.caption).foregroundStyle(.secondary) }
                Spacer()
            }
            .padding(.bottom, 15)
        }
        .background(Color(UIColor.systemGray6)).cornerRadius(16).padding(.horizontal)
    }
    
    // 👇 LE SWITCH CORRIGÉ (Avec .flights)
    func valueFor(_ day: DailyActivity, type: MetricType, isWork: Bool) -> Double {
        switch type {
        case .steps: return isWork ? day.workSteps : day.personalSteps
        case .calories: return isWork ? day.workCal : day.personalCal
        case .distance: return isWork ? day.workDist : day.personalDist
        case .heart: return isWork ? day.workHeart : day.personalHeart
        case .flights: return isWork ? day.workFlights : day.personalFlights // ✅ Ajouté
        }
    }
    
    // 👇 L'ICÔNE CORRIGÉE (Avec .flights)
    func iconFor(_ type: MetricType) -> String {
        switch type {
        case .steps: return "figure.walk"
        case .calories: return "flame.fill"
        case .distance: return "map.fill"
        case .heart: return "heart.fill"
        case .flights: return "figure.stairs" // ✅ Ajouté
        }
    }
}

// MARK: - VUES ANNEXES (Configuration & Ticket)

struct DashboardConfigView: View {
    @Binding var widgets: [DashboardWidget]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Graphiques affichés"), footer: Text("Maintenez les trois lignes à droite pour changer l'ordre.")) {
                    ForEach($widgets) { $widget in
                        HStack {
                            Image(systemName: iconFor(widget.type)).foregroundStyle(widget.type.color).frame(width: 30)
                            Text(widget.type.title)
                            Spacer()
                            Toggle("", isOn: $widget.isVisible).labelsHidden()
                        }
                    }.onMove(perform: move)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Modifier l'affichage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("OK") { dismiss() } }
        }
    }
    
    func move(from source: IndexSet, to destination: Int) { widgets.move(fromOffsets: source, toOffset: destination) }
    
    // 👇 Switch exhaustif aussi ici !
    func iconFor(_ type: MetricType) -> String {
        switch type {
        case .steps: return "figure.walk"
        case .calories: return "flame.fill"
        case .distance: return "map.fill"
        case .heart: return "heart.fill"
        case .flights: return "figure.stairs" // ✅ Ajouté
        }
    }
}
