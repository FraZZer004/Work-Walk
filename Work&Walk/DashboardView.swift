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
                    statsSummaryView    // 2. Résumé Pas/Heures (Auj.)
                    
                    // 3. Graphiques
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
                    calories: 0
                )
            }
            // --- CHARGEMENT ---
            .onAppear {
                loadWidgets()
                healthManager.requestAuthorization()
                calculateWeeklyStats() // Calcul auto sur "Aujourd'hui"
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
    
    func calculateWeeklyStats() {
        var newDailyData: [DailyActivity] = []
        let f = DateFormatter(); f.locale = Locale(identifier: selectedLanguage); f.dateFormat = "EE"
        let calendar = Calendar.current; let group = DispatchGroup()
        let today = Date() // Toujours basé sur aujourd'hui pour le Dashboard
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let isToday = calendar.isDateInToday(date); let dayName = isToday ? (selectedLanguage == "en" ? "Today" : "Auj.") : f.string(from: date)
            let startOfDay = calendar.startOfDay(for: date); guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }
            group.enter()
            
            var dWSteps: Double=0; var dLSteps: Double=0; var dWCal: Double=0; var dLCal: Double=0; var dWDist: Double=0; var dLDist: Double=0; var dWHeart: Double=0; var dLHeart: Double=0
            
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
    
    struct DynamicChartCard: View {
        let type: MetricType; let data: [DailyActivity]
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack { Image(systemName: iconFor(type)).foregroundStyle(type.color).font(.title3); Text(LocalizedStringKey(type.title)).font(.headline).foregroundStyle(.primary); Spacer() }.padding(.top, 10).padding(.horizontal)
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
        func valueFor(_ day: DailyActivity, type: MetricType, isWork: Bool) -> Double { switch type { case .steps: return isWork ? day.workSteps : day.personalSteps; case .calories: return isWork ? day.workCal : day.personalCal; case .distance: return isWork ? day.workDist : day.personalDist; case .heart: return isWork ? day.workHeart : day.personalHeart } }
        func iconFor(_ type: MetricType) -> String { switch type { case .steps: return "figure.walk"; case .calories: return "flame.fill"; case .distance: return "map.fill"; case .heart: return "heart.fill" } }
    }
}

// MARK: - VUES MANQUANTES (DashboardConfig & ShareReceipt)
// (Je remets les vues "outils" ici pour qu'elles soient dispo pour le Dashboard)

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

struct ShareReceiptSheet: View {
    @Environment(\.dismiss) var dismiss; let steps: Int; let hours: String; let salary: Double; let calories: Int
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer(); Text("Aperçu de votre Story").font(.caption).textCase(.uppercase).foregroundStyle(.secondary)
                let receipt = DailyReceiptView(steps: steps, hours: hours, salary: salary, calories: calories)
                receipt; Spacer()
                ShareLink(item: renderImage(view: receipt), preview: SharePreview("Mon Ticket Work&Walk", image: renderImage(view: receipt))) { HStack { Image(systemName: "square.and.arrow.up"); Text("Partager sur Instagram / Snap") }.font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding().background(Color.blue).cornerRadius(30) }.padding(.horizontal)
            }.padding().background(Color(UIColor.systemGroupedBackground)).navigationTitle("Partager").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .topBarTrailing) { Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.gray) } } }
        }
    }
    @MainActor func renderImage(view: DailyReceiptView) -> Image { let renderer = ImageRenderer(content: view); renderer.scale = 3.0; if let uiImage = renderer.uiImage { return Image(uiImage: uiImage) }; return Image(systemName: "photo") }
}

struct DailyReceiptView: View {
    let date: Date = Date(); let steps: Int; let hours: String; let salary: Double; let calories: Int
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 5) { Image(systemName: "figure.walk.circle.fill").font(.system(size: 40)).foregroundStyle(.black); Text("WORK & WALK").font(.system(.headline, design: .monospaced)).fontWeight(.bold).tracking(2); Text("REÇU OFFICIEL").font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary); Text(date.formatted(date: .numeric, time: .omitted)).font(.system(.caption2, design: .monospaced)).foregroundStyle(.secondary) }.padding(.top, 20)
            Divider().background(Color.black)
            VStack(spacing: 12) { ReceiptRow(label: "TEMPS TRAVAIL", value: hours); ReceiptRow(label: "SALAIRE EST.", value: String(format: "%.2f €", salary)); ReceiptRow(label: "PAS EFFECTUÉS", value: "\(steps)"); ReceiptRow(label: "CALORIES", value: "\(calories) kcal") }
            Divider().background(Color.black)
            HStack { Text("TOTAL GAIN").font(.system(.headline, design: .monospaced)).fontWeight(.black); Spacer(); Text("DOUBLE !").font(.system(.title3, design: .monospaced)).fontWeight(.black) }
            Text("(Argent + Santé)").font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .trailing)
            VStack(spacing: 5) { Text("Merci de votre visite").font(.system(.caption, design: .monospaced)).italic(); HStack(spacing: 2) { ForEach(0..<40, id: \.self) { _ in Rectangle().fill(Color.black).frame(width: CGFloat.random(in: 1...3), height: 30) } }.padding(.top, 10); Text("www.workandwalk.app").font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary) }.padding(.bottom, 40)
        }.padding(.horizontal, 25).background(Color(red: 0.98, green: 0.97, blue: 0.95)).clipShape(TicketShape()).shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5).frame(width: 320)
    }
}
struct ReceiptRow: View { let label: String; let value: String; var body: some View { HStack { Text(label); Spacer(); Text(String(repeating: ".", count: 20)).lineLimit(1).foregroundStyle(.secondary.opacity(0.5)); Spacer(); Text(value).fontWeight(.bold) }.font(.system(.caption, design: .monospaced)).foregroundStyle(.black) } }
struct TicketShape: Shape { func path(in rect: CGRect) -> Path { var path = Path(); path.move(to: CGPoint(x: 0, y: 0)); path.addLine(to: CGPoint(x: rect.width, y: 0)); path.addLine(to: CGPoint(x: rect.width, y: rect.height)); let teethCount = 20; let toothWidth = rect.width / CGFloat(teethCount); let toothHeight: CGFloat = 10; for i in 0..<teethCount { let x = rect.width - (CGFloat(i) * toothWidth); path.addLine(to: CGPoint(x: x - (toothWidth / 2), y: rect.height - toothHeight)); path.addLine(to: CGPoint(x: x - toothWidth, y: rect.height)) }; path.addLine(to: CGPoint(x: 0, y: 0)); path.closeSubpath(); return path } }
