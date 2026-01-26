import SwiftUI
import SwiftData
import Charts
import HealthKit
import PhotosUI

struct ContentView: View {
    @AppStorage("selectedAppearance") private var selectedAppearance: Int = 0
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    
    // On a besoin des sessions pour savoir si l'utilisateur est nouveau
    @Query private var sessions: [WorkSession]
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Accueil", systemImage: "chart.bar.xaxis") }
                .tag(0)
            
            PlanningView()
                .tabItem { Label("Planning", systemImage: "calendar") }
                .tag(1)
            
            AnalysisView()
                .tabItem { Label("Analyse", systemImage: "heart.text.square") }
                .tag(2)
            
            SalaryView()
                .tabItem { Label("Salaire", systemImage: "eurosign.circle.fill") }
                .tag(3)
        }
        .tint(.orange)
        .preferredColorScheme(selectedAppearance == 1 ? .light : (selectedAppearance == 2 ? .dark : nil))
        .environment(\.locale, Locale(identifier: selectedLanguage))
        .id(selectedLanguage)
        
        // --- GESTION DES CLICS NOTIFS ---
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenAnalyseTab"))) { _ in selectedTab = 2 }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenSalaryTab"))) { _ in selectedTab = 3 }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenPlanningTab"))) { _ in selectedTab = 1 }
        
        // --- MISE À JOUR INTELLIGENTE AU LANCEMENT ---
        .onAppear {
            // 1. On demande la permission (si pas déjà fait)
            NotificationManager.shared.requestAuthorization()
            
            // 2. On met à jour les textes des notifs selon l'expérience de l'utilisateur
            updateNotificationsContext()
        }
        // Si l'utilisateur ajoute sa première session pendant qu'il utilise l'app, on met à jour les notifs
        .onChange(of: sessions.count) { _, _ in
            updateNotificationsContext()
        }
    }
    
    // Fonction qui détermine le profil de l'utilisateur
    func updateNotificationsContext() {
        // Est-ce un nouvel utilisateur ? (0 session enregistrée)
        let isNewUser = sessions.isEmpty
        
        // On envoie l'info au Manager pour qu'il change les textes
        NotificationManager.shared.updateContextualNotifications(isNewUser: isNewUser)
    }
}


struct DashboardView: View {
    @State private var healthManager = HealthManager()
    @Query(sort: \WorkSession.startTime, order: .reverse) private var sessions: [WorkSession]
    @State private var weeklyData: [DailyActivity] = []
    
    // --- ÉTATS DE NAVIGATION ---
    @State private var showSettings = false       // Corrigé (était showingSettings)
    @State private var showEditDashboard = false  // Corrigé (était showingEditDashboard)
    @State private var showTrophies = false       // ✅ AJOUTÉ : Manquait pour le bouton Trophées
    
    @AppStorage("username") private var username: String = "Utilisateur"
    @AppStorage("dashboardWidgetsJSON") private var widgetsJSON: String = ""
    @AppStorage("userProfileImage") private var userProfileImageBase64: String = ""
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    
    @State private var widgets: [DashboardWidget] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // En-tête
                    HStack(spacing: 15) {
                        // Photo Profil
                        if let avatar = userAvatar {
                            Image(uiImage: avatar)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.orange, lineWidth: 2))
                                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                        } else {
                            ZStack {
                                Circle().fill(Color(UIColor.systemGray5)).frame(width: 50, height: 50)
                                Image(systemName: "person.fill").foregroundStyle(.gray).font(.title3)
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Bonjour,").font(.subheadline).foregroundStyle(.secondary)
                            Text(username.isEmpty ? "Bienvenue" : username)
                                .font(.largeTitle).bold()
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        Spacer()
                        
                        // Bouton Éditer Dashboard ( Widgets )
                        Button(action: { showEditDashboard = true }) {
                            Image(systemName: "list.bullet.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.orange.opacity(0.8))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Résumé Rapide
                    HStack(spacing: 15) {
                        statCard(icon: "figure.walk", color: .orange, title: "Pas Auj.", value: "\(Int(healthManager.stepsToday))")
                        statCard(icon: "briefcase.fill", color: .orange, title: "Travail Auj.", value: calculateTodayWorkHours())
                    }.padding(.horizontal)
                    
                    // Widgets Dynamiques
                    ForEach(widgets) { widget in
                        if widget.isVisible {
                            DynamicChartCard(type: widget.type, data: weeklyData)
                        }
                    }
                    
                    // Bouton Mise à jour manuelle
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        calculateWeeklyStats()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.triangle.2.circlepath").font(.title3).fontWeight(.bold)
                            Text("Mettre à jour les données").font(.headline).fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(LinearGradient(colors: [.orange, .orange.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .foregroundStyle(.white).cornerRadius(16).shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal).padding(.top, 10).padding(.bottom, 20)
                    
                }.padding(.top).padding(.bottom, 50)
            }
            .navigationTitle("Tableau de Bord")
            
            // --- BARRE D'OUTILS (TOOLBAR) ---
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        
                        // 1. Bouton TROPHÉES
                        Button {
                            showTrophies = true
                        } label: {
                            Image(systemName: "trophy.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.yellow, .orange)
                                .font(.system(size: 24))
                        }
                        
                        // 2. Bouton PARAMÈTRES
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(.gray)
                                .font(.system(size: 20))
                        }
                    }
                }
            }
            
            // --- GESTION DES FEUILLES (SHEETS) ---
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showEditDashboard) { DashboardConfigView(widgets: $widgets) }
            .sheet(isPresented: $showTrophies) { TrophiesView() } // ✅ AJOUTÉ ICI
            
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
    
    // --- LOGIQUE METIER ---
    
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
    
    func saveWidgets() {
        if let encoded = try? JSONEncoder().encode(widgets), let jsonString = String(data: encoded, encoding: .utf8) { widgetsJSON = jsonString }
    }
    
    func statCard(icon: String, color: Color, title: String, value: String) -> some View {
        VStack(alignment: .leading) {
            HStack { Image(systemName: icon).foregroundStyle(color); Text(LocalizedStringKey(title)).font(.caption).foregroundStyle(.secondary) }
            Text(value).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(.primary)
        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color(UIColor.systemGray6)).cornerRadius(16)
    }
    
    struct DynamicChartCard: View {
        let type: MetricType; let data: [DailyActivity]
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack { Image(systemName: iconFor(type)).foregroundStyle(type.color).font(.title3); Text(LocalizedStringKey(type.title)).font(.headline).foregroundStyle(.primary); Spacer() }
                    .padding(.top, 10).padding(.horizontal)
                Chart {
                    ForEach(data) { day in
                        BarMark(x: .value("Jour", day.dayName), y: .value("Val", valueFor(day, type: type, isWork: true))).foregroundStyle(type.color)
                        if type == .heart { PointMark(x: .value("Jour", day.dayName), y: .value("Val", valueFor(day, type: type, isWork: false))).foregroundStyle(.gray.opacity(0.7)) }
                        else { BarMark(x: .value("Jour", day.dayName), y: .value("Val", valueFor(day, type: type, isWork: false))).foregroundStyle(Color.gray.opacity(0.3)) }
                    }
                }.frame(height: 180).padding(.horizontal)
                HStack(spacing: 20) {
                    Spacer(); HStack(spacing: 5) { Circle().fill(type.color).frame(width: 8, height: 8); Text("Travail").font(.caption).foregroundStyle(.secondary) }
                    HStack(spacing: 5) { Circle().fill(type == .heart ? Color.gray.opacity(0.7) : Color.gray.opacity(0.3)).frame(width: 8, height: 8); Text("Perso").font(.caption).foregroundStyle(.secondary) }; Spacer()
                }.padding(.bottom, 15)
            }.background(Color(UIColor.systemGray6)).cornerRadius(16).padding(.horizontal)
        }
        func valueFor(_ day: DailyActivity, type: MetricType, isWork: Bool) -> Double {
            switch type { case .steps: return isWork ? day.workSteps : day.personalSteps; case .calories: return isWork ? day.workCal : day.personalCal; case .distance: return isWork ? day.workDist : day.personalDist; case .heart: return isWork ? day.workHeart : day.personalHeart }
        }
        func iconFor(_ type: MetricType) -> String { switch type { case .steps: return "figure.walk"; case .calories: return "flame.fill"; case .distance: return "map.fill"; case .heart: return "heart.fill" } }
    }
    
    func calculateTodayWorkHours() -> String {
        let today = Calendar.current.startOfDay(for: Date())
        if let session = sessions.first(where: { Calendar.current.isDate($0.startTime, inSameDayAs: today) }) {
            let end = session.endTime ?? Date(); let diff = end.timeIntervalSince(session.startTime)
            let h = Int(diff) / 3600; let m = (Int(diff) % 3600) / 60
            return "\(h)h \(m)m"
        }
        return "0h 0m"
    }
    
    func calculateWeeklyStats() {
        var newDailyData: [DailyActivity] = []
        let f = DateFormatter(); f.locale = Locale(identifier: selectedLanguage); f.dateFormat = "EE"
        let calendar = Calendar.current; let today = Date(); let group = DispatchGroup()
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayName = i == 0 ? (selectedLanguage == "en" ? "Today" : "Auj.") : f.string(from: date)
            let startOfDay = calendar.startOfDay(for: date); let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            group.enter()
            var dWSteps:Double=0; var dLSteps:Double=0; var dWCal:Double=0; var dLCal:Double=0; var dWDist:Double=0; var dLDist:Double=0; var dWHeart:Double=0; var dLHeart:Double=0
            
            if let session = sessions.first(where: { calendar.isDate($0.startTime, inSameDayAs: date) }) {
                let sStart = session.startTime; let sEnd = session.endTime ?? Date(); let iG = DispatchGroup()
                iG.enter(); healthManager.fetchQuantity(type: .stepCount, start: sStart, end: sEnd) { v in dWSteps=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .activeEnergyBurned, start: sStart, end: sEnd) { v in dWCal=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .distanceWalkingRunning, start: sStart, end: sEnd) { v in dWDist=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .heartRate, start: sStart, end: sEnd) { v in dWHeart=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .stepCount, start: startOfDay, end: endOfDay) { v in dLSteps=max(0,v-dWSteps); iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .activeEnergyBurned, start: startOfDay, end: endOfDay) { v in dLCal=max(0,v-dWCal); iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .distanceWalkingRunning, start: startOfDay, end: endOfDay) { v in dLDist=max(0,v-dWDist); iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .heartRate, start: startOfDay, end: endOfDay) { v in dLHeart=v; iG.leave() }
                iG.notify(queue: .main) { newDailyData.append(DailyActivity(id: UUID(), dayName: dayName, date: date, workSteps: dWSteps, personalSteps: dLSteps, workCal: dWCal, personalCal: dLCal, workDist: dWDist, personalDist: dLDist, workHeart: dWHeart, personalHeart: dLHeart)); group.leave() }
            } else {
                let iG = DispatchGroup()
                iG.enter(); healthManager.fetchQuantity(type: .stepCount, start: startOfDay, end: endOfDay) { v in dLSteps=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .activeEnergyBurned, start: startOfDay, end: endOfDay) { v in dLCal=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .distanceWalkingRunning, start: startOfDay, end: endOfDay) { v in dLDist=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .heartRate, start: startOfDay, end: endOfDay) { v in dLHeart=v; iG.leave() }
                iG.notify(queue: .main) { newDailyData.append(DailyActivity(id: UUID(), dayName: dayName, date: date, workSteps: 0, personalSteps: dLSteps, workCal: 0, personalCal: dLCal, workDist: 0, personalDist: dLDist, workHeart: 0, personalHeart: dLHeart)); group.leave() }
            }
        }
        group.notify(queue: .main) { self.weeklyData = newDailyData.sorted(by: { $0.date < $1.date }) }
    }
}

// MARK: - 2. VUE PLANNING (Multilingue)

struct PlanningView: View {
    @Query(sort: \WorkSession.startTime, order: .reverse) private var sessions: [WorkSession]
    @Environment(\.modelContext) var modelContext
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var viewMode: ViewMode = .calendar
    @State private var showingAddSheet = false
    @State private var sessionToEdit: WorkSession? = nil
    @State private var filterScope: FilterScope = .month
    
    enum ViewMode: String, CaseIterable { case calendar, list }
    enum FilterScope: String, CaseIterable { case month = "Mois", year = "Année" }
    
    // Calendrier Dynamique (pour que les jours de la semaine s'adaptent)
    var calendar: Calendar {
        var c = Calendar.current
        c.locale = Locale(identifier: selectedLanguage)
        return c
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Vue", selection: $filterScope) {
                    ForEach(FilterScope.allCases, id: \.self) { scope in Text(LocalizedStringKey(scope.rawValue)).tag(scope) }
                }.pickerStyle(.segmented).padding()
                
                HStack(spacing: 10) {
                    if filterScope == .month {
                        Menu {
                            ForEach(availableMonths, id: \.self) { month in
                                Button { selectedMonth = month } label: { HStack { Text(monthName(month)); if month == selectedMonth { Image(systemName: "checkmark") } } }
                            }
                        } label: {
                            HStack(spacing: 4) { Text(monthName(selectedMonth).capitalized).font(.headline).fixedSize(); Image(systemName: "chevron.down").font(.caption).bold() }
                                .padding(.vertical, 8).padding(.horizontal, 10).background(Color.orange.opacity(0.1)).cornerRadius(8).foregroundStyle(.orange)
                        }
                    }
                    Menu {
                        ForEach(availableYears, id: \.self) { year in
                            Button { selectedYear = year; validateMonthSelection(for: year) } label: { HStack { Text(String(year)); if year == selectedYear { Image(systemName: "checkmark") } } }
                        }
                    } label: {
                        HStack(spacing: 4) { Text(String(selectedYear)).font(.headline); Image(systemName: "chevron.down").font(.caption).bold() }
                            .padding(.vertical, 8).padding(.horizontal, 10).background(Color.orange.opacity(0.1)).cornerRadius(8).foregroundStyle(.orange)
                    }
                    Spacer()
                    if filterScope == .month {
                        Picker("Vue", selection: $viewMode) { Image(systemName: "calendar").tag(ViewMode.calendar); Image(systemName: "list.bullet").tag(ViewMode.list) }
                            .pickerStyle(.segmented).frame(width: 80)
                    }
                }.padding(.horizontal).padding(.bottom)
                
                if filterScope == .year {
                    YearlySummaryView(year: selectedYear, sessions: sessions, language: selectedLanguage)
                } else {
                    if filteredSessions.isEmpty {
                        if viewMode == .calendar { ScrollView { VStack(spacing: 20) { totalHoursBadge(sessions: []); MonthGridView(year: selectedYear, month: selectedMonth, sessions: [], language: selectedLanguage) }.padding(.top) } }
                        else { ContentUnavailableView("Aucune session", systemImage: "calendar.badge.exclamationmark", description: Text("Aucune heure pour \(monthName(selectedMonth)) \(String(selectedYear)).")) }
                    } else {
                        if viewMode == .list {
                            List {
                                ForEach(groupedSessionsByDay, id: \.key) { day, sessionsInDay in
                                    Section(header: Text(day.capitalized)) {
                                        ForEach(sessionsInDay) { session in
                                            SessionRow(session: session, language: selectedLanguage).swipeActions(edge: .leading) { Button { sessionToEdit = session } label: { Label("Modifier", systemImage: "pencil") }.tint(.orange) }
                                        }.onDelete(perform: { indexSet in deleteItems(offsets: indexSet, in: sessionsInDay) })
                                    }
                                }
                            }.listStyle(.insetGrouped)
                        } else {
                            ScrollView { VStack(spacing: 20) { totalHoursBadge(sessions: filteredSessions); MonthGridView(year: selectedYear, month: selectedMonth, sessions: filteredSessions, language: selectedLanguage) }.padding(.top) }
                        }
                    }
                }
            }
            .navigationTitle("Planning")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button(action: { showingAddSheet = true }) { Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(.orange) } }
            }
            .sheet(isPresented: $showingAddSheet) { AddSessionView(sessionToEdit: nil) }
            .sheet(item: $sessionToEdit) { session in AddSessionView(sessionToEdit: session) }
            .onAppear {
                let minYear = availableYears.first ?? selectedYear
                if selectedYear < minYear { selectedYear = minYear }
                validateMonthSelection(for: selectedYear)
            }
        }
    }
    // Logic Helpers
    var firstSessionDate: Date { sessions.last?.startTime ?? Date() }
    var availableYears: [Int] {
        let startYear = calendar.component(.year, from: firstSessionDate); let currentYear = calendar.component(.year, from: Date())
        return Array(startYear...(currentYear + 1))
    }
    var availableMonths: [Int] {
        let startYear = calendar.component(.year, from: firstSessionDate)
        if selectedYear == startYear { let startMonth = calendar.component(.month, from: firstSessionDate); return Array(startMonth...12) }
        else { return Array(1...12) }
    }
    func validateMonthSelection(for year: Int) {
        let startYear = calendar.component(.year, from: firstSessionDate)
        if year == startYear { let startMonth = calendar.component(.month, from: firstSessionDate); if selectedMonth < startMonth { selectedMonth = startMonth } }
    }
    var filteredSessions: [WorkSession] { sessions.filter { let c = calendar.dateComponents([.year, .month], from: $0.startTime); return c.year == selectedYear && c.month == selectedMonth } }
    func totalHoursBadge(sessions: [WorkSession]) -> some View { HStack { Text("Total Mois :").foregroundStyle(.secondary); Text(calculateTotalHours(for: sessions)).bold().foregroundStyle(.primary) }.padding(.horizontal, 12).padding(.vertical, 6).background(Color(UIColor.systemGray5)).cornerRadius(20) }
    
    func monthName(_ month: Int) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: selectedLanguage)
        return f.monthSymbols[month - 1]
    }
    func calculateTotalHours(for sessions: [WorkSession]) -> String {
        let totalSeconds = sessions.reduce(0) { total, session in
            guard let end = session.endTime else { return total }
            return total + end.timeIntervalSince(session.startTime)
        }
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        
        // SI il y a des minutes, on les colle au "h" (avec un 0 si < 10)
        if minutes > 0 {
            return "\(hours)h\(minutes < 10 ? "0" : "")\(minutes)"
        } else {
            // SINON on affiche juste les heures
            return "\(hours)h"
        }
    }
    var groupedSessionsByDay: [(key: String, value: [WorkSession])] {
        let f = DateFormatter(); f.locale = Locale(identifier: selectedLanguage); f.dateFormat = "EEEE d MMMM"
        let grouped = Dictionary(grouping: filteredSessions) { f.string(from: $0.startTime) }
        return grouped.sorted { guard let date1 = $0.value.first?.startTime, let date2 = $1.value.first?.startTime else { return false }; return date1 > date2 }
    }
    func deleteItems(offsets: IndexSet, in list: [WorkSession]) { withAnimation { for index in offsets { modelContext.delete(list[index]) } } }
}

struct YearlySummaryView: View {
    let year: Int; let sessions: [WorkSession]; let language: String
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var sessionsInYear: [WorkSession] { sessions.filter { Calendar.current.component(.year, from: $0.startTime) == year } }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack { Text("Total \(String(year)) :").foregroundStyle(.secondary); Text(calculateTotalHours(for: sessionsInYear)).font(.title3).bold().foregroundStyle(.orange) }.padding().frame(maxWidth: .infinity).background(Color(UIColor.systemGray6)).cornerRadius(16).padding(.horizontal)
                LazyVGrid(columns: columns, spacing: 15) { ForEach(1...12, id: \.self) { month in monthCell(month: month) } }.padding(.horizontal)
            }.padding(.top)
        }
    }
    func monthCell(month: Int) -> some View {
        let sessionsInMonth = sessionsInYear.filter { Calendar.current.component(.month, from: $0.startTime) == month }
        let totalHours = calculateTotalHours(for: sessionsInMonth); let hasHours = !sessionsInMonth.isEmpty
        let f = DateFormatter(); f.locale = Locale(identifier: language)
        let name = f.monthSymbols[month - 1]
        return VStack(spacing: 5) {
            Text(name.prefix(3).capitalized).font(.caption).bold().foregroundStyle(.secondary)
            Text(totalHours).font(.headline).foregroundStyle(hasHours ? Color.primary : Color.gray.opacity(0.3))
        }.frame(height: 80).frame(maxWidth: .infinity).background(hasHours ? Color.orange.opacity(0.1) : Color(UIColor.systemGray6)).overlay(RoundedRectangle(cornerRadius: 12).stroke(hasHours ? Color.orange : Color.clear, lineWidth: 1)).cornerRadius(12)
    }
    func calculateTotalHours(for sessions: [WorkSession]) -> String {
        let totalSeconds = sessions.reduce(0) { total, session in
            guard let end = session.endTime else { return total }
            return total + end.timeIntervalSince(session.startTime)
        }
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        
        // SI il y a des minutes, on les colle au "h" (avec un 0 si < 10)
        if minutes > 0 {
            return "\(hours)h\(minutes < 10 ? "0" : "")\(minutes)"
        } else {
            // SINON on affiche juste les heures
            return "\(hours)h"
        }
    }
}

struct SessionRow: View {
    let session: WorkSession; let language: String
    private var timeFormatter: DateFormatter { let f = DateFormatter(); f.locale = Locale(identifier: language); f.dateFormat = "HH:mm"; return f }
    private func formatDurationSimple(start: Date, end: Date) -> String {
        let diff = end.timeIntervalSince(start); let h = Int(diff) / 3600; let m = (Int(diff) % 3600) / 60; return "\(h)h \(m < 10 ? "0" : "")\(m)"
    }
    var body: some View {
        HStack {
            VStack(alignment: .leading) { Text("\(timeFormatter.string(from: session.startTime)) - \(session.endTime != nil ? timeFormatter.string(from: session.endTime!) : "En cours")").font(.headline) }
            Spacer()
            if let end = session.endTime { Text(formatDurationSimple(start: session.startTime, end: end)).font(.subheadline).bold().foregroundStyle(.orange) }
            else { Text("En cours").font(.caption).foregroundStyle(.green) }
        }.padding(.vertical, 4)
    }
}

struct MonthGridView: View {
    let year: Int
    let month: Int
    let sessions: [WorkSession]
    let language: String
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    // 1. On crée un calendrier COHÉRENT pour tout le calcul
    var calendar: Calendar {
        var c = Calendar.current
        c.locale = Locale(identifier: language)
        // Optionnel : on peut forcer le lundi pour la France si besoin,
        // mais avec la locale "fr", ça devrait être automatique (2 = Lundi).
        return c
    }
    
    // 2. On génère les jours de la semaine dans le BON ORDRE (Lundi premier ou Dimanche premier selon la langue)
    var daysOfWeek: [String] {
        let f = DateFormatter()
        f.locale = Locale(identifier: language)
        // Les symboles par défaut commencent toujours à Dimanche dans l'API Apple
        let symbols = f.shortStandaloneWeekdaySymbols ?? []
        guard !symbols.isEmpty else { return [] }
        
        let firstDayIndex = calendar.firstWeekday - 1 // Convertir 1-7 en 0-6
        
        // On fait une rotation du tableau pour qu'il commence au bon jour
        // Ex: Si le calendrier commence Lundi (Index 1), on prend de Lundi à Samedi + Dimanche à la fin
        let range = firstDayIndex..<symbols.count
        return Array(symbols[range] + symbols[0..<firstDayIndex])
    }
    
    // 3. Calcul précis du 1er du mois basé sur CE calendrier
    var startOfMonth: Date {
        let components = DateComponents(year: year, month: month, day: 1)
        return calendar.date(from: components) ?? Date()
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // En-têtes (L, M, M... ou S, M, T...)
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day.prefix(1).uppercased())
                        .font(.caption2).bold()
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Grille des jours
            LazyVGrid(columns: columns, spacing: 10) {
                // 4. Le Décalage (Offset) corrigé
                // On ajoute des cases vides avant le 1er jour
                ForEach(0..<startingOffset, id: \.self) { _ in
                    Rectangle().fill(Color.clear).frame(height: 35)
                }
                
                let daysInMonth = getDaysInMonth(date: startOfMonth)
                
                ForEach(daysInMonth, id: \.self) { dayDate in
                    let workedSession = sessions.first { calendar.isDate($0.startTime, inSameDayAs: dayDate) }
                    let isToday = calendar.isDateInToday(dayDate)
                    
                    VStack(spacing: 4) {
                        ZStack {
                            // LE FOND
                            if isToday {
                                if workedSession != nil {
                                    // Auj + Travail
                                    Circle()
                                        .stroke(Color.primary, lineWidth: 3)
                                        .background(Circle().fill(Color.orange))
                                } else {
                                    // Auj + Repos
                                    Circle().fill(Color.primary)
                                }
                            } else {
                                // Jour Normal
                                Circle()
                                    .fill(workedSession != nil ? Color.orange : Color.gray.opacity(0.15))
                            }
                            
                            // LE TEXTE
                            Text(dateFormatterDayNum.string(from: dayDate))
                                .font(.caption).bold()
                                .foregroundStyle(
                                    isToday && workedSession == nil ? Color(UIColor.systemBackground) :
                                    (workedSession != nil ? Color.black : Color.primary)
                                )
                        }
                        .frame(width: 35, height: 35)
                        
                        // DURÉE
                        if let session = workedSession, let end = session.endTime {
                            let diff = end.timeIntervalSince(session.startTime) / 3600
                            Text(String(format: "%.1fh", diff))
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        } else {
                            Text(" ").font(.system(size: 8))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // --- HELPERS CORRIGÉS ---
    
    var startingOffset: Int {
        // On demande quel jour de la semaine est le 1er du mois (ex: Jeudi = 5)
        let weekday = calendar.component(.weekday, from: startOfMonth)
        // On soustrait le premier jour de la semaine du calendrier (ex: Lundi = 2)
        // Formule magique pour avoir toujours un résultat positif entre 0 et 6
        return (weekday - calendar.firstWeekday + 7) % 7
    }
    
    func getDaysInMonth(date: Date) -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: date) else { return [] }
        return range.compactMap { d in
            calendar.date(byAdding: .day, value: d - 1, to: startOfMonth)
        }
    }
    
    private var dateFormatterDayNum: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: language)
        f.dateFormat = "d"
        return f
    }
}
// MARK: - 3. VUE ANALYSE (Moderne & Bento)

import SwiftUI
import SwiftData
import Charts

struct AnalysisView: View {
    @State private var healthManager = HealthManager()
    @Query(sort: \WorkSession.startTime, order: .reverse) private var sessions: [WorkSession]
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    
    // États de données
    @State private var totalWorkSteps: Double = 0; @State private var totalLifeSteps: Double = 0
    @State private var totalWorkCal: Double = 0;   @State private var totalLifeCal: Double = 0
    @State private var totalWorkDist: Double = 0;  @State private var totalLifeDist: Double = 0
    @State private var avgWorkHeart: Double = 0;   @State private var avgLifeHeart: Double = 0
    
    // Données détaillées (pour le clic)
    @State private var historySteps: [DailyData] = []; @State private var historyCal: [DailyData] = []
    @State private var historyDist: [DailyData] = []; @State private var historyHeart: [DailyData] = []
    
    @State private var selectedMetric: MetricType? = nil
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    
                    // 1. LE RÉCAP HEBDO (Ton bloc orange en haut)
                    WeeklyRecapView()
                        .padding(.top)
                    
                    // 2. LES CARTES "SCORE" SIMPLIFIÉES
                    VStack(alignment: .leading, spacing: 15) {
                        
                        Text("Détails par activité")
                            .font(.title3).bold()
                            .padding(.horizontal)
                        
                        if isLoading {
                            HStack { Spacer(); ProgressView(); Spacer() }.padding(30)
                        } else {
                            VStack(spacing: 12) {
                                
                                // PAS
                                SimpleScoreCard(
                                    type: .steps,
                                    workVal: totalWorkSteps,
                                    lifeVal: totalLifeSteps
                                ).onTapGesture { selectedMetric = .steps }
                                
                                // CALORIES
                                SimpleScoreCard(
                                    type: .calories,
                                    workVal: totalWorkCal,
                                    lifeVal: totalLifeCal
                                ).onTapGesture { selectedMetric = .calories }
                                
                                // DISTANCE
                                SimpleScoreCard(
                                    type: .distance,
                                    workVal: totalWorkDist,
                                    lifeVal: totalLifeDist
                                ).onTapGesture { selectedMetric = .distance }
                                
                                // CARDIO (Cardio n'a pas de barre de progression, juste les chiffres)
                                SimpleCardioCard(
                                    workBPM: avgWorkHeart,
                                    lifeBPM: avgLifeHeart
                                ).onTapGesture { selectedMetric = .heart }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Text("Données calculées sur les sessions saisies dans le Planning.")
                        .font(.caption2).foregroundStyle(.tertiary)
                        .padding(.bottom, 30)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Analyse")
            .onAppear { healthManager.requestAuthorization(); analyzeWeek() }
            .sheet(item: $selectedMetric) { metric in DetailMetricView(type: metric, data: getDataFor(metric), language: selectedLanguage) }
        }
    }
    
    // --- HELPERS (Inchangés) ---
    func getDataFor(_ type: MetricType) -> [DailyData] {
        switch type { case .steps: return historySteps; case .calories: return historyCal; case .distance: return historyDist; case .heart: return historyHeart }
    }
    
    func analyzeWeek() {
        // (Copie ici ton bloc de calcul 'analyzeWeek' habituel, inchangé)
        isLoading = true
        let calendar = Calendar.current; let today = Date(); let group = DispatchGroup()
        let f = DateFormatter(); f.locale = Locale(identifier: selectedLanguage); f.dateFormat = "EE"
        
        var tWSteps: Double=0; var tLSteps: Double=0; var tWCal: Double=0; var tLCal: Double=0
        var tWDist: Double=0; var tLDist: Double=0; var tWBPM: [Double]=[]; var tLBPM: [Double]=[]
        var tempHistS: [DailyData]=[]; var tempHistC: [DailyData]=[]; var tempHistD: [DailyData]=[]; var tempHistH: [DailyData]=[]
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayName = i == 0 ? (selectedLanguage == "en" ? "Today" : "Auj.") : f.string(from: date)
            let startOfDay = calendar.startOfDay(for: date); let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            group.enter()
            var dWSteps:Double=0; var dLSteps:Double=0; var dWCal:Double=0; var dLCal:Double=0; var dWDist:Double=0; var dLDist:Double=0; var dWHeart:Double=0; var dLHeart:Double=0
            
            if let session = sessions.first(where: { calendar.isDate($0.startTime, inSameDayAs: date) }) {
                let sStart = session.startTime; let sEnd = session.endTime ?? Date(); let iG = DispatchGroup()
                iG.enter(); healthManager.fetchQuantity(type: .stepCount, start: sStart, end: sEnd) { v in dWSteps=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .activeEnergyBurned, start: sStart, end: sEnd) { v in dWCal=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .distanceWalkingRunning, start: sStart, end: sEnd) { v in dWDist=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .heartRate, start: sStart, end: sEnd) { v in dWHeart=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .stepCount, start: startOfDay, end: endOfDay) { v in dLSteps=max(0,v-dWSteps); iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .activeEnergyBurned, start: startOfDay, end: endOfDay) { v in dLCal=max(0,v-dWCal); iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .distanceWalkingRunning, start: startOfDay, end: endOfDay) { v in dLDist=max(0,v-dWDist); iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .heartRate, start: startOfDay, end: endOfDay) { v in dLHeart=v; iG.leave() }
                iG.notify(queue: .main) {
                    let id = UUID()
                    tempHistS.append(DailyData(id: id, date: date, dayName: dayName, workVal: dWSteps, lifeVal: dLSteps))
                    tempHistC.append(DailyData(id: id, date: date, dayName: dayName, workVal: dWCal, lifeVal: dLCal))
                    tempHistD.append(DailyData(id: id, date: date, dayName: dayName, workVal: dWDist, lifeVal: dLDist))
                    tempHistH.append(DailyData(id: id, date: date, dayName: dayName, workVal: dWHeart, lifeVal: dLHeart))
                    tWSteps+=dWSteps; tLSteps+=dLSteps; tWCal+=dWCal; tLCal+=dLCal; tWDist+=dWDist; tLDist+=dLDist
                    if dWHeart>0 { tWBPM.append(dWHeart) }; if dLHeart>0 { tLBPM.append(dLHeart) }
                    group.leave()
                }
            } else {
                let iG = DispatchGroup()
                iG.enter(); healthManager.fetchQuantity(type: .stepCount, start: startOfDay, end: endOfDay) { v in dLSteps=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .activeEnergyBurned, start: startOfDay, end: endOfDay) { v in dLCal=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .distanceWalkingRunning, start: startOfDay, end: endOfDay) { v in dLDist=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .heartRate, start: startOfDay, end: endOfDay) { v in dLHeart=v; iG.leave() }
                iG.notify(queue: .main) {
                    let id = UUID()
                    tempHistS.append(DailyData(id: id, date: date, dayName: dayName, workVal: 0, lifeVal: dLSteps))
                    tempHistC.append(DailyData(id: id, date: date, dayName: dayName, workVal: 0, lifeVal: dLCal))
                    tempHistD.append(DailyData(id: id, date: date, dayName: dayName, workVal: 0, lifeVal: dLDist))
                    tempHistH.append(DailyData(id: id, date: date, dayName: dayName, workVal: 0, lifeVal: dLHeart))
                    tLSteps+=dLSteps; tLCal+=dLCal; tLDist+=dLDist; if dLHeart>0 { tLBPM.append(dLHeart) }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            self.totalWorkSteps = tWSteps/7; self.totalLifeSteps = tLSteps/7
            self.totalWorkCal = tWCal/7; self.totalLifeCal = tLCal/7
            self.totalWorkDist = tWDist/7; self.totalLifeDist = tLDist/7
            let sW = tWBPM.reduce(0, +); self.avgWorkHeart = tWBPM.isEmpty ? 0 : sW/Double(tWBPM.count)
            let sL = tLBPM.reduce(0, +); self.avgLifeHeart = tLBPM.isEmpty ? 0 : sL/Double(tLBPM.count)
            self.historySteps = tempHistS.sorted(by: { $0.date < $1.date })
            self.historyCal = tempHistC.sorted(by: { $0.date < $1.date })
            self.historyDist = tempHistD.sorted(by: { $0.date < $1.date })
            self.historyHeart = tempHistH.sorted(by: { $0.date < $1.date })
            self.isLoading = false
        }
    }
}

// MARK: - 3. NOUVELLE CARTE "SCORE" (Simple & Explicite)

struct SimpleScoreCard: View {
    let type: MetricType
    let workVal: Double
    let lifeVal: Double
    
    var body: some View {
        let total = workVal + lifeVal
        let workPercent = total > 0 ? workVal / total : 0
        
        VStack(spacing: 15) {
            // Titre + Total
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: iconFor(type)).foregroundStyle(type.color)
                    Text(LocalizedStringKey(type.title)).font(.headline)
                }
                Spacer()
                // Total (ex: 12 000 pas)
                Text("Total : " + format(total))
                    .font(.subheadline).bold().foregroundStyle(.secondary)
            }
            
            // Les deux gros chiffres (Le duel)
            HStack(alignment: .lastTextBaseline) {
                // Coté Travail
                VStack(alignment: .leading, spacing: 2) {
                    Text(format(workVal))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("Travail")
                        .font(.caption2).bold().foregroundStyle(.orange.opacity(0.8))
                }
                
                Spacer()
                
                // Petite barre de proportion visuelle
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.2)).frame(height: 6)
                        Capsule().fill(Color.orange).frame(width: geo.size.width * workPercent, height: 6)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Coté Perso
                VStack(alignment: .trailing, spacing: 2) {
                    Text(format(lifeVal))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.gray)
                    Text("Perso")
                        .font(.caption2).bold().foregroundStyle(.gray)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        // Pas d'ombre portée, juste une bordure très fine pour faire propre
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1))
    }
    
    func format(_ val: Double) -> String {
        if type == .distance { return String(format: "%.1f km", val) }
        return "\(Int(val))"
    }
    func iconFor(_ type: MetricType) -> String {
        switch type { case .steps: return "figure.walk"; case .calories: return "flame.fill"; case .distance: return "map.fill"; case .heart: return "heart.fill" }
    }
}

// MARK: - 4. NOUVELLE CARTE "CARDIO" (Juste les chiffres)

struct SimpleCardioCard: View {
    let workBPM: Double
    let lifeBPM: Double
    
    var body: some View {
        VStack(spacing: 15) {
            // Titre
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill").foregroundStyle(.pink)
                    Text("Cardio Moyen").font(.headline)
                }
                Spacer()
            }
            
            // Les Chiffres
            HStack(alignment: .center) {
                // Travail
                VStack {
                    Text(workBPM > 0 ? "\(Int(workBPM))" : "--")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.pink)
                    Text("Travail (BPM)")
                        .font(.caption2).bold().foregroundStyle(.pink.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                
                // Séparateur vertical
                Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 1, height: 30)
                
                // Perso
                VStack {
                    Text(lifeBPM > 0 ? "\(Int(lifeBPM))" : "--")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.gray)
                    Text("Perso (BPM)")
                        .font(.caption2).bold().foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - VUE SALAIRE AVEC PDF

struct SalaryView: View {
    @Query(sort: \WorkSession.startTime, order: .reverse) private var sessions: [WorkSession]
    @AppStorage("hourlyRate") private var hourlyRate: Double = 11.91
    @AppStorage("taxRate") private var taxRate: Double = 23.05
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    @AppStorage("username") private var username: String = "Utilisateur" // Pour le PDF
    
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    
                    // SÉLECTEUR DE MOIS
                    HStack {
                        Button(action: { changeMonth(by: -1) }) { Image(systemName: "chevron.left.circle.fill").font(.title2).foregroundStyle(.orange) }
                        Text(monthFormatter.string(from: selectedDate).capitalized).font(.title3).bold().frame(width: 160).multilineTextAlignment(.center)
                        Button(action: { changeMonth(by: 1) }) { Image(systemName: "chevron.right.circle.fill").font(.title2).foregroundStyle(.orange) }
                    }.padding(.top)
                    
                    // CARTE PRINCIPALE
                    VStack(spacing: 10) {
                        Text(LocalizedStringKey("Salaire Net Estimé")).font(.headline).foregroundStyle(.secondary)
                        
                        Text(formatCurrency(calculateNet()))
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                            .contentTransition(.numericText())
                        
                        HStack(spacing: 5) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Basé sur \(formatHours(calculateHours())) travaillées") // "Basé sur..." à traduire dans Localizable
                        }
                        .font(.caption).padding(8).background(Color.orange.opacity(0.1)).cornerRadius(20)
                    }
                    .padding().frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemGray6)).cornerRadius(20).padding(.horizontal)
                    
                    // BOUTON EXPORT PDF (Nouveau !)
                    // On utilise ShareLink qui génère le fichier à la volée
                    ShareLink(item: renderPDF(), preview: SharePreview("\(pdfPrefix) \(monthFormatter.string(from: selectedDate))", image: Image("AppLogo"))) {
                                                    HStack {
                                                        Image(systemName: "square.and.arrow.up")
                                                        Text(LocalizedStringKey("Exporter la fiche (PDF)")) // Pense bien au LocalizedStringKey ici aussi !
                                                    }
                                                    .font(.headline)
                                                    .foregroundStyle(.white)
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(Color.blue)
                                                    .cornerRadius(15)
                                                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                                                }
                                                .padding(.horizontal)
                    
                    // DÉTAILS
                    VStack(alignment: .leading, spacing: 15) {
                        Text(LocalizedStringKey("Détails du calcul")).font(.headline).padding(.leading)
                        VStack(spacing: 0) {
                            DetailRow(title: "Heures saisies", value: formatHours(calculateHours()), isBold: false)
                            DetailRow(title: "Taux horaire", value: "x \(hourlyRate) \(currencySymbol)", isBold: false)
                            Divider().padding(.vertical, 8)
                            DetailRow(title: "Salaire Brut", value: formatCurrency(calculateGross()), isBold: true)
                            
                            HStack {
                                Text(LocalizedStringKey("Charges estimées")).font(.subheadline).foregroundStyle(.secondary)
                                Text("(-\(Int(taxRate))%)").font(.caption).foregroundStyle(.red)
                                Spacer()
                                Text("- " + formatCurrency(calculateGross() * (taxRate/100))).font(.subheadline).foregroundStyle(.red)
                            }.padding(.vertical, 8)
                            
                            Divider().padding(.vertical, 8)
                            HStack {
                                Text(LocalizedStringKey("Net à payer")).font(.headline)
                                Spacer()
                                Text(formatCurrency(calculateNet())).font(.headline).foregroundStyle(.orange)
                            }
                        }
                        .padding().background(Color(UIColor.systemGray6)).cornerRadius(16).padding(.horizontal)
                    }
                    
                    // PARAMÈTRES
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey("Paramètres de paie")).font(.headline).padding(.top)
                        VStack {
                            HStack {
                                Text(LocalizedStringKey("Taux horaire (Brut)")); Spacer()
                                TextField("11.91", value: $hourlyRate, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80).padding(5).background(Color(UIColor.systemGray5)).cornerRadius(8)
                                Text(currencySymbol)
                            }
                            Divider()
                            HStack {
                                Text(LocalizedStringKey("Charges (%)")); Spacer()
                                TextField("23", value: $taxRate, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80).padding(5).background(Color(UIColor.systemGray5)).cornerRadius(8)
                                Text("%")
                            }
                        }.padding().background(Color(UIColor.systemGray6)).cornerRadius(16)
                    }.padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("Mon Salaire")
        }
    }
    
    // --- FONCTION DE GÉNÉRATION PDF 🖨️ ---
    @MainActor
        func renderPDF() -> URL {
            // 1. On prépare la vue
            let template = SalaryPDFTemplate(
                month: monthFormatter.string(from: selectedDate),
                hours: formatHours(calculateHours()),
                rate: hourlyRate,
                gross: formatCurrency(calculateGross()),
                taxRate: taxRate,
                taxAmount: formatCurrency(calculateGross() * (taxRate/100)),
                net: formatCurrency(calculateNet()),
                symbol: currencySymbol,
                userName: username.isEmpty ? "Utilisateur" : username
            )
            // 👇 C'EST ICI LE FIX : ON FORCE LA LANGUE SUR LE PDF
            .environment(\.locale, Locale(identifier: selectedLanguage))

            // 2. Le reste ne change pas...
            let renderer = ImageRenderer(content: template)
            let url = URL.documentsDirectory.appending(path: "Fiche_WorkWalk_\(monthFormatter.string(from: selectedDate)).pdf")
            
            renderer.render { size, context in
                var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
                pdf.beginPDFPage(nil)
                context(pdf)
                pdf.endPDFPage()
                pdf.closePDF()
            }
            return url
        }
    
    // --- CALCULS & HELPERS ---
    
    var pdfPrefix: String {
            return selectedLanguage == "en" ? "Payslip" : "Fiche"
        }
    
    var currencySymbol: String { return selectedLanguage == "en" ? "$" : "€" }
    
    func changeMonth(by value: Int) { if let new = Calendar.current.date(byAdding: .month, value: value, to: selectedDate) { selectedDate = new } }
    
    func calculateHours() -> Double {
        let cal = Calendar.current
        let monthSessions = sessions.filter {
            cal.isDate($0.startTime, equalTo: selectedDate, toGranularity: .month) &&
            cal.isDate($0.startTime, equalTo: selectedDate, toGranularity: .year)
        }
        let sec = monthSessions.reduce(0) { tot, s in guard let e = s.endTime else { return tot }; return tot + e.timeIntervalSince(s.startTime) }
        return sec / 3600
    }
    
    func calculateGross() -> Double { return calculateHours() * hourlyRate }
    func calculateNet() -> Double { let g = calculateGross(); return g - (g * (taxRate/100)) }
    
    func formatCurrency(_ val: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency
        let localeID = selectedLanguage == "en" ? "en_US" : "fr_FR"
        f.locale = Locale(identifier: localeID)
        return f.string(from: NSNumber(value: val)) ?? "\(val)"
    }
    
    func formatHours(_ val: Double) -> String { return String(format: "%.2fh", val) }
    
    private var monthFormatter: DateFormatter {
        let f = DateFormatter(); f.locale = Locale(identifier: selectedLanguage); f.dateFormat = "MMMM yyyy"; return f
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let isBold: Bool
    
    var body: some View {
        HStack {
            // 👇 AJOUT DE LocalizedStringKey() ICI
            // Cela force SwiftUI à chercher la traduction de la variable 'title'
            Text(LocalizedStringKey(title))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(isBold ? .bold : .regular)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 2)
    }
}

struct DetailMetricView: View {
    let type: MetricType; let data: [DailyData]; let language: String; @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Vue d'ensemble")) {
                    Chart {
                        ForEach(data) { day in
                            BarMark(x: .value("Jour", day.dayName), y: .value("Travail", day.workVal)).foregroundStyle(type.color)
                            if type != .heart { BarMark(x: .value("Jour", day.dayName), y: .value("Perso", day.lifeVal)).foregroundStyle(type.color.opacity(0.3)) }
                            else { PointMark(x: .value("Jour", day.dayName), y: .value("Perso", day.lifeVal)).foregroundStyle(Color.gray) }
                        }
                    }.frame(height: 200).padding(.vertical)
                }
                Section(header: Text("Détails par jour")) {
                    ForEach(data.reversed()) { day in
                        HStack {
                            VStack(alignment: .leading) { Text(day.date.formatted(date: .abbreviated, time: .omitted)).bold(); Text(day.dayName.capitalized).font(.caption).foregroundStyle(.secondary) }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack { Text("Travail").font(.caption2).foregroundStyle(.secondary); Text(format(day.workVal)).bold().foregroundStyle(type.color).frame(minWidth: 60, alignment: .trailing) }
                                HStack { Text("Perso").font(.caption2).foregroundStyle(.secondary); Text(format(day.lifeVal)).bold().foregroundStyle(type == .heart ? Color.gray : type.color.opacity(0.6)).frame(minWidth: 60, alignment: .trailing) }
                                if type != .heart { Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 80, height: 1).padding(.vertical, 2); HStack { Text("Total").font(.caption2).bold(); Text(format(day.workVal + day.lifeVal)).bold().foregroundStyle(.primary).frame(minWidth: 60, alignment: .trailing) } }
                            }
                        }.padding(.vertical, 4)
                    }
                }
            }.navigationTitle(type.title).navigationBarTitleDisplayMode(.inline).toolbar { Button("Fermer") { dismiss() } }
        }
    }
    func format(_ val: Double) -> String { if type == .distance { return String(format: "%.2f km", val) }; return "\(Int(val)) \(type.unit)" }
}

enum MetricType: String, Identifiable, Codable, CaseIterable {
    case steps, calories, distance, heart; var id: String { self.rawValue }
    var title: String { switch self { case .steps: return "Pas"; case .calories: return "Calories"; case .distance: return "Distance"; case .heart: return "Cardio" } }
    var unit: String { switch self { case .steps: return "pas"; case .calories: return "kcal"; case .distance: return "km"; case .heart: return "bpm" } }
    var color: Color { switch self { case .steps: return .orange; case .calories: return .red; case .distance: return .green; case .heart: return .pink } }
    var gradient: LinearGradient {
        switch self {
        case .steps: return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .calories: return LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .distance: return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .heart: return LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct DashboardWidget: Identifiable, Codable, Equatable { var id: UUID = UUID(); var type: MetricType; var isVisible: Bool }
struct DailyActivity: Identifiable { let id: UUID; let dayName: String; let date: Date; let workSteps: Double; let personalSteps: Double; let workCal: Double; let personalCal: Double; let workDist: Double; let personalDist: Double; let workHeart: Double; let personalHeart: Double }
struct DailyData: Identifiable { let id: UUID; let date: Date; let dayName: String; let workVal: Double; let lifeVal: Double }

struct DashboardConfigView: View {
    @Binding var widgets: [DashboardWidget]; @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Graphiques affichés"), footer: Text("Maintenez les trois lignes à droite pour changer l'ordre.")) {
                    ForEach($widgets) { $widget in
                        HStack { Image(systemName: iconFor(widget.type)).foregroundStyle(widget.type.color).frame(width: 30); Text(widget.type.title); Spacer(); Toggle("", isOn: $widget.isVisible).labelsHidden() }
                    }.onMove(perform: move)
                }
            }.environment(\.editMode, .constant(.active)).navigationTitle("Modifier l'affichage").navigationBarTitleDisplayMode(.inline).toolbar { Button("OK") { dismiss() } }
        }
    }
    func move(from source: IndexSet, to destination: Int) { widgets.move(fromOffsets: source, toOffset: destination) }
    func iconFor(_ type: MetricType) -> String { switch type { case .steps: return "figure.walk"; case .calories: return "flame.fill"; case .distance: return "map.fill"; case .heart: return "heart.fill" } }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("username") private var username: String = ""
    @AppStorage("userProfileImage") private var userProfileImageBase64: String = ""
    @AppStorage("selectedAppearance") private var selectedAppearance: Int = 0
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    @State private var notificationsEnabled = true
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var currentAvatar: UIImage? = nil
    
    var body: some View {
        NavigationStack {
            List {
                // --- SECTION PROFIL ---
                Section {
                    VStack(spacing: 15) {
                        
                        // 👇 ZStack modifié pour inclure le bouton de suppression
                        ZStack(alignment: .topTrailing) {
                            
                            // 1. La Photo (qui sert aussi de bouton pour modifier)
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                ZStack {
                                    if let avatar = currentAvatar {
                                        Image(uiImage: avatar)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.orange, lineWidth: 2))
                                    } else {
                                        Circle()
                                            .fill(Color(UIColor.systemGray5))
                                            .frame(width: 100, height: 100)
                                            .overlay(Image(systemName: "person.fill").font(.system(size: 40)).foregroundStyle(.gray))
                                    }
                                    
                                    // Petit crayon (Décoratif)
                                    Circle()
                                        .fill(.orange)
                                        .frame(width: 30, height: 30)
                                        .overlay(Image(systemName: "pencil").foregroundStyle(.white).font(.caption))
                                        .offset(x: 35, y: 35)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            // 2. Le Bouton Supprimer (s'affiche uniquement si une photo existe)
                            if currentAvatar != nil {
                                Button(action: deleteAvatar) {
                                    Image(systemName: "xmark.circle.fill")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .red) // Croix blanche sur fond rouge
                                        .font(.system(size: 26))
                                        .background(Circle().fill(.white).frame(width: 20, height: 20)) // Petit fond blanc pour l'opacité
                                }
                                .offset(x: 5, y: -5) // Positionné en haut à droite
                                .buttonStyle(.plain)
                            }
                        }
                        
                        VStack(spacing: 5) {
                            Text("Ton Prénom").font(.caption).foregroundStyle(.secondary).textCase(.uppercase)
                            TextField("Entre ton prénom", text: $username).font(.title2).bold().multilineTextAlignment(.center).submitLabel(.done)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .listRowBackground(Color.clear)
                }
                
                // --- APPARENCE ---
                Section(header: Text("Apparence")) {
                    Picker("Thème", selection: $selectedAppearance) { Text("Système").tag(0); Text("Clair").tag(1); Text("Sombre").tag(2) }.pickerStyle(.segmented).listRowSeparator(.hidden)
                    Picker("Langue", selection: $selectedLanguage) { Text("Français").tag("fr"); Text("English").tag("en") }
                }
                
                // --- PRÉFÉRENCES ---
                Section(header: Text("Préférences")) {
                    Toggle(isOn: $notificationsEnabled) {
                        Label { Text("Rappels d'horaires") } icon: { Image(systemName: "bell.badge.fill").foregroundStyle(.red) }
                    }
                    .onChange(of: notificationsEnabled) { _, isEnabled in
                        if isEnabled {
                            NotificationManager.shared.scheduleAllNotifications()
                        } else {
                            NotificationManager.shared.cancelAll()
                        }
                    }
                    
                    Toggle(isOn: .constant(true)) { Label { Text("Données Santé") } icon: { Image(systemName: "heart.fill").foregroundStyle(.pink) } }
                        .disabled(true)
                    Text("Pour gérer l'accès Santé, allez dans Réglages > Santé > Work&Walk.")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                
                // --- INFORMATIONS LÉGALES ---
                Section(header: Text("Informations Légales")) {
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label("Politique de Confidentialité", systemImage: "hand.raised.fill")
                    }
                    
                    NavigationLink {
                        LegalDetailView(title: "Avertissement Financier", content: """
                        L'application Work&Walk propose des estimations de salaire basées sur les données saisies par l'utilisateur.
                        Ces calculs sont fournis à titre purement indicatif et ne sauraient remplacer une fiche de paie officielle. L'éditeur décline toute responsabilité en cas d'écart avec le salaire réel.
                        """)
                    } label: {
                        Label("Avertissement Financier", systemImage: "banknote.fill")
                    }
                    
                    NavigationLink {
                        LegalDetailView(title: "Avertissement Santé", content: """
                        Les données de santé proviennent d'Apple HealthKit.
                        Work&Walk n'est pas un dispositif médical. Consultez toujours un médecin avant de commencer un programme sportif intensif.
                        """)
                    } label: {
                        Label("Avertissement Santé", systemImage: "staroflife.fill")
                    }
                }
                
                // --- ZONE DE DANGER ---
                Section(footer: Text("Cette action est irréversible.").font(.caption)) {
                    Button(role: .destructive) { } label: { Label("Réinitialiser les données", systemImage: "trash.fill").foregroundStyle(.red) }
                }
                
                // --- CRÉDITS ---
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 5) {
                            Image("AppLogo").resizable().scaledToFit().frame(width: 60, height: 60).opacity(0.9)
                            Text("Work&Walk").font(.headline)
                            Text("Version 1.0.2").font(.caption).foregroundStyle(.secondary)
                            Text("© 2026 Tous droits réservés").font(.caption2).foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }.listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("OK") { dismiss() }.fontWeight(.bold).foregroundStyle(.orange) }
            .preferredColorScheme(selectedAppearance == 1 ? .light : (selectedAppearance == 2 ? .dark : nil))
            .id(selectedAppearance)
            .onAppear { loadAvatar() }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                        if let compressedData = uiImage.jpegData(compressionQuality: 0.5) {
                            userProfileImageBase64 = compressedData.base64EncodedString()
                            currentAvatar = uiImage
                        }
                    }
                }
            }
        }
    }
    
    func loadAvatar() {
        if !userProfileImageBase64.isEmpty, let data = Data(base64Encoded: userProfileImageBase64) {
            currentAvatar = UIImage(data: data)
        }
    }
    
    // 👇 FONCTION AJOUTÉE : Suppression de l'avatar
    func deleteAvatar() {
        withAnimation {
            currentAvatar = nil
            userProfileImageBase64 = ""
            selectedPhotoItem = nil
        }
    }
}

// Petite vue pour afficher le texte légal proprement
struct LegalDetailView: View {
    let title: String
    let content: String
    var body: some View {
        ScrollView {
            Text(content).padding().font(.body)
        }.navigationTitle(title)
    }
}
// MARK: - 4. NOUVELLE VUE : RÉCAP HEBDO (Corrigé & Strict)

struct WeeklyRecapView: View {
    @Query private var sessions: [WorkSession]
    @State private var healthManager = HealthManager()
    
    // 👇 On récupère la langue pour savoir si la semaine commence Lundi ou Dimanche
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    
    // États d'animation
    @State private var showAnimations = false
    @State private var animatedHours: Double = 0
    @State private var animatedSteps: Double = 0
    @State private var animatedDist: Double = 0
    @State private var animatedCal: Double = 0
    
    // Données calculées
    @State private var weeklyWorkData: [Double] = [0,0,0,0,0,0,0]
    
    var body: some View {
        VStack(spacing: 0) {
            // --- EN-TÊTE ---
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CETTE SEMAINE")
                        .font(.caption).fontWeight(.bold).foregroundStyle(.white.opacity(0.7))
                    Text(getDateRange())
                        .font(.caption2).foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                // Badge de réussite
                if animatedHours > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                        Text("Actif")
                    }
                    .font(.caption2).bold()
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.white.opacity(0.2)).cornerRadius(10)
                    .foregroundStyle(.white)
                }
            }
            .padding(.bottom, 20)
            
            // --- GROS CHIFFRE (HEURES) ---
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.1f", animatedHours))
                    .font(.system(size: 54, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                
                Text("heures")
                    .font(.title3).fontWeight(.medium).foregroundStyle(.white.opacity(0.8))
                
                Spacer()
                
                // MINI GRAPHIQUE BARRES
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<7, id: \.self) { index in
                        // Barre
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.white.opacity(weeklyWorkData[index] > 0 ? 0.9 : 0.2))
                                .frame(width: 6, height: showAnimations ? CGFloat(min(40, max(4, weeklyWorkData[index] * 3))) : 0)
                        }
                        .frame(height: 40)
                    }
                }
            }
            .padding(.bottom, 25)
            
            // --- STATS SANTÉ ---
            HStack(spacing: 0) {
                StatBox(icon: "figure.walk", val: "\(Int(animatedSteps))", label: "Pas", delay: 0.1)
                Divider().background(.white.opacity(0.2)).frame(height: 30)
                StatBox(icon: "map.fill", val: String(format: "%.1f", animatedDist), label: "Km", delay: 0.2)
                Divider().background(.white.opacity(0.2)).frame(height: 30)
                StatBox(icon: "flame.fill", val: "\(Int(animatedCal))", label: "Kcal", delay: 0.3)
            }
            .padding(.top, 15)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(24)
        .background(
            ZStack {
                LinearGradient(colors: [Color.orange, Color.orange.opacity(0.85), Color.red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle().fill(.white.opacity(0.05)).frame(width: 200).offset(x: 100, y: -100)
                Circle().fill(.white.opacity(0.05)).frame(width: 150).offset(x: -120, y: 80)
            }
        )
        .cornerRadius(24)
        .shadow(color: .orange.opacity(0.4), radius: 15, x: 0, y: 8)
        .padding(.horizontal)
        
        .onAppear {
            loadData()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                showAnimations = true
            }
        }
        // On recharge si la vue réapparait ou si les données changent
        .onChange(of: sessions) { _, _ in loadData() }
    }
    
    func StatBox(icon: String, val: String, label: String, delay: Double) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3).foregroundStyle(.white.opacity(0.8))
                .scaleEffect(showAnimations ? 1 : 0.5)
                .animation(.bouncy.delay(delay), value: showAnimations)
            Text(val).font(.headline).bold().foregroundStyle(.white).contentTransition(.numericText())
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.6))
        }.frame(maxWidth: .infinity)
    }
    
    // --- LOGIQUE CORRIGÉE ---
    
    func loadData() {
        // 1. Configurer le calendrier selon la langue choisie
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: selectedLanguage)
        
        // 2. Trouver l'intervalle STRICT de la semaine actuelle
        // dateInterval(of: .weekOfYear) retourne le Lundi 00h00 à Lundi suivant 00h00 (ou Dimanche selon langue)
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return }
        let startOfWeek = weekInterval.start
        let endOfWeek = weekInterval.end
        
        // 3. Filtrer les sessions UNIQUEMENT dans cet intervalle
        let weeklySessions = sessions.filter {
            $0.startTime >= startOfWeek && $0.startTime < endOfWeek
        }
        
        // 4. Calcul du total heures
        let totalSeconds = weeklySessions.reduce(0) { tot, s in
            guard let end = s.endTime else { return tot }
            return tot + end.timeIntervalSince(s.startTime)
        }
        let totalHours = totalSeconds / 3600
        
        // 5. Remplir le graphique (Position relative)
        var tempGraph: [Double] = [0,0,0,0,0,0,0]
        
        for session in weeklySessions {
            // On calcule l'écart en jours par rapport au début de la semaine
            // Jour 0 = 1er jour de la semaine (Lundi ou Dimanche)
            // Jour 1 = 2ème jour, etc.
            let daysFromStart = calendar.dateComponents([.day], from: startOfWeek, to: session.startTime).day ?? 0
            
            if daysFromStart >= 0 && daysFromStart < 7 {
                if let end = session.endTime {
                    let h = end.timeIntervalSince(session.startTime) / 3600
                    tempGraph[daysFromStart] += h
                }
            }
        }
        
        // 6. Données Santé (Sur la même période stricte)
        let group = DispatchGroup()
        var s: Double=0; var d: Double=0; var c: Double=0
        
        group.enter(); healthManager.fetchQuantity(type: .stepCount, start: startOfWeek, end: endOfWeek) { v in s = v; group.leave() }
        group.enter(); healthManager.fetchQuantity(type: .distanceWalkingRunning, start: startOfWeek, end: endOfWeek) { v in d = v; group.leave() }
        group.enter(); healthManager.fetchQuantity(type: .activeEnergyBurned, start: startOfWeek, end: endOfWeek) { v in c = v; group.leave() }
        
        group.notify(queue: .main) {
            withAnimation(.easeOut(duration: 1.0)) {
                self.animatedHours = totalHours
                self.weeklyWorkData = tempGraph
                self.animatedSteps = s
                self.animatedDist = d
                self.animatedCal = c
            }
        }
    }
    
    func getDateRange() -> String {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: selectedLanguage)
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return "" }
        
        let f = DateFormatter()
        f.locale = Locale(identifier: selectedLanguage)
        f.dateFormat = "d MMM"
        
        // Ex: "19 janv. - 25 janv."
        let endOfWeekDisplay = calendar.date(byAdding: .day, value: -1, to: weekInterval.end) ?? weekInterval.end
        return "\(f.string(from: weekInterval.start)) - \(f.string(from: endOfWeekDisplay))"
    }
}
