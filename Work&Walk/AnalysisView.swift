import SwiftUI
import SwiftData
import Charts
import HealthKit

// MARK: - VUE PRINCIPALE ANALYSE

struct AnalysisView: View {
    // 🔒 PREMIUM MANAGER
    @ObservedObject var premiumManager = PremiumManager.shared
    @State private var showPremiumAlert = false
    
    @State private var healthManager = HealthManager()
    @Query(sort: \WorkSession.startTime, order: .reverse) private var sessions: [WorkSession]
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    
    // 🗓️ ÉTAT POUR LA NAVIGATION
    @State private var selectedDate: Date = Date()
    
    // États de données
    @State private var totalWorkSteps: Double = 0; @State private var totalLifeSteps: Double = 0
    @State private var totalWorkCal: Double = 0;   @State private var totalLifeCal: Double = 0
    @State private var totalWorkDist: Double = 0;  @State private var totalLifeDist: Double = 0
    @State private var totalWorkFlights: Double = 0; @State private var totalLifeFlights: Double = 0
    @State private var avgWorkHeart: Double = 0;   @State private var avgLifeHeart: Double = 0
    
    // Graphiques
    @State private var historySteps: [DailyData] = []
    @State private var historyCal: [DailyData] = []
    @State private var historyDist: [DailyData] = []
    @State private var historyHeart: [DailyData] = []
    @State private var historyFlights: [DailyData] = []
    
    @State private var selectedMetric: MetricType? = nil
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    
                    // 🔒 VÉRIFICATION DE L'HISTORIQUE
                    if premiumManager.canViewHistory(for: selectedDate) {
                        
                        // --- CAS 1 : ACCÈS AUTORISÉ ✅ ---
                        
                        // 1. LE RÉCAP HEBDO
                        WeeklyRecapView(
                            referenceDate: selectedDate,
                            isLocked: isSelectedDateCurrentWeek()
                        )
                        .padding(.top)
                        
                        // 2. DÉTAILS PAR ACTIVITÉ
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Détails par activité")
                                .font(.title3).bold()
                                .padding(.horizontal)
                            
                            // BARRE DE NAVIGATION (Date)
                            DateNavigationBar(selectedDate: $selectedDate, onDateChange: analyzeWeek, isLocked: false)
                            
                            // 3. LES CARTES DE SCORE
                            if isLoading {
                                HStack { Spacer(); ProgressView(); Spacer() }.padding(30)
                            } else {
                                VStack(spacing: 12) {
                                    // ✅ GRATUIT : PAS & CALORIES
                                    SimpleScoreCard(type: .steps, workVal: totalWorkSteps, lifeVal: totalLifeSteps)
                                        .onTapGesture { selectedMetric = .steps }
                                    
                                    SimpleScoreCard(type: .calories, workVal: totalWorkCal, lifeVal: totalLifeCal)
                                        .onTapGesture { selectedMetric = .calories }
                                    
                                    // 🔒 PREMIUM : DISTANCE
                                    if premiumManager.canViewDetailedMetrics() {
                                        SimpleScoreCard(type: .distance, workVal: totalWorkDist, lifeVal: totalLifeDist)
                                            .onTapGesture { selectedMetric = .distance }
                                    } else {
                                        LockedMetricCard(title: "Distance", icon: "map.fill", color: .green) { showPremiumAlert = true }
                                    }
                                    
                                    // 🔒 PREMIUM : ÉTAGES
                                    if premiumManager.canViewDetailedMetrics() {
                                        SimpleScoreCard(type: .flights, workVal: totalWorkFlights, lifeVal: totalLifeFlights)
                                            .onTapGesture { selectedMetric = .flights }
                                    } else {
                                        LockedMetricCard(title: "Étages", icon: "figure.stairs", color: .cyan) { showPremiumAlert = true }
                                    }
                                    
                                    // 🔒 PREMIUM : CARDIO
                                    if premiumManager.canViewDetailedMetrics() {
                                        SimpleCardioCard(workBPM: avgWorkHeart, lifeBPM: avgLifeHeart)
                                            .onTapGesture { selectedMetric = .heart }
                                    } else {
                                        LockedMetricCard(title: "Cardio Moyen", icon: "heart.fill", color: .pink) { showPremiumAlert = true }
                                    }
                                }.padding(.horizontal)
                            }
                        }
                        
                    } else {
                        
                        // --- CAS 2 : ACCÈS REFUSÉ (HISTORIQUE ANCIEN) ❌ ---
                        
                        VStack(spacing: 20) {
                            // On garde la navigation pour pouvoir revenir en avant !
                            DateNavigationBar(selectedDate: $selectedDate, onDateChange: analyzeWeek, isLocked: true)
                                .padding(.top)
                            
                            // VISUEL DE VERROUILLAGE
                            VStack(spacing: 20) {
                                Image(systemName: "lock.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.orange)
                                    .padding(.top, 40)
                                
                                VStack(spacing: 8) {
                                    Text("Historique Verrouillé")
                                        .font(.title2.bold())
                                    Text("Les données datant de plus de 2 semaines sont réservées aux membres PRO.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                
                                Button(action: { showPremiumAlert = true }) {
                                    Text("Débloquer mon historique")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                                        .cornerRadius(12)
                                        .shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
                                }
                                .padding(.horizontal, 40)
                                .padding(.bottom, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(20)
                            .padding(.horizontal)
                            .shadow(color: .black.opacity(0.05), radius: 10)
                            
                            Spacer()
                        }
                    }
                    
                    Text("Données calculées sur les sessions saisies dans le Planning.").font(.caption2).foregroundStyle(.tertiary).padding(.bottom, 30)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Analyse")
            .onAppear { healthManager.requestAuthorization(); analyzeWeek() }
            .sheet(item: $selectedMetric) { metric in DetailMetricView(type: metric, data: getDataFor(metric), language: selectedLanguage) }
            
            // ALERTE PRO
            .alert("Accès Premium", isPresented: $showPremiumAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Voir les offres") { }
            } message: {
                Text("Accédez à tout votre historique et aux analyses avancées avec Work&Walk PRO.")
            }
        }
    }
    
    // --- HELPERS ---
    func analyzeWeek() {
        if !premiumManager.canViewHistory(for: selectedDate) {
            isLoading = false
            return
        }
        
        isLoading = true; var calendar = Calendar.current; calendar.locale = Locale(identifier: selectedLanguage)
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { isLoading = false; return }
        let startOfWeek = weekInterval.start
        
        let group = DispatchGroup()
        let f = DateFormatter(); f.locale = Locale(identifier: selectedLanguage); f.dateFormat = "EE"
        
        var tWSteps: Double=0; var tLSteps: Double=0; var tWCal: Double=0; var tLCal: Double=0
        var tWDist: Double=0; var tLDist: Double=0; var tWFlights: Double=0; var tLFlights: Double=0
        var tWBPM: [Double]=[]; var tLBPM: [Double]=[]
        
        var tempHistS: [DailyData]=[]; var tempHistC: [DailyData]=[]; var tempHistD: [DailyData]=[]; var tempHistH: [DailyData]=[]; var tempHistF: [DailyData]=[]
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) else { continue }
            let dayName = f.string(from: date); let startOfDay = calendar.startOfDay(for: date); let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            group.enter()
            
            var dWSteps:Double=0; var dLSteps:Double=0; var dWCal:Double=0; var dLCal:Double=0; var dWDist:Double=0; var dLDist:Double=0; var dWHeart:Double=0; var dLHeart:Double=0; var dWFlights:Double=0; var dLFlights:Double=0
            
            if let session = sessions.first(where: { calendar.isDate($0.startTime, inSameDayAs: date) }) {
                let sStart = session.startTime; let sEnd = session.endTime ?? Date(); let safeEnd = min(sEnd, endOfDay)
                let iG = DispatchGroup()
                
                iG.enter(); healthManager.fetchQuantity(type: .stepCount, start: sStart, end: safeEnd) { v in dWSteps=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .activeEnergyBurned, start: sStart, end: safeEnd) { v in dWCal=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .distanceWalkingRunning, start: sStart, end: safeEnd) { v in dWDist=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .heartRate, start: sStart, end: safeEnd) { v in dWHeart=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .flightsClimbed, start: sStart, end: safeEnd) { v in dWFlights=v; iG.leave() }
                
                iG.enter(); healthManager.fetchQuantity(type: .stepCount, start: startOfDay, end: endOfDay) { v in dLSteps=max(0,v-dWSteps); iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .activeEnergyBurned, start: startOfDay, end: endOfDay) { v in dLCal=max(0,v-dWCal); iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .distanceWalkingRunning, start: startOfDay, end: endOfDay) { v in dLDist=max(0,v-dWDist); iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .heartRate, start: startOfDay, end: endOfDay) { v in dLHeart=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .flightsClimbed, start: startOfDay, end: endOfDay) { v in dLFlights=max(0,v-dWFlights); iG.leave() }
                
                iG.notify(queue: .main) {
                    let id = UUID()
                    tempHistS.append(DailyData(id: id, date: date, dayName: dayName, workVal: dWSteps, lifeVal: dLSteps))
                    tempHistC.append(DailyData(id: id, date: date, dayName: dayName, workVal: dWCal, lifeVal: dLCal))
                    tempHistD.append(DailyData(id: id, date: date, dayName: dayName, workVal: dWDist, lifeVal: dLDist))
                    tempHistH.append(DailyData(id: id, date: date, dayName: dayName, workVal: dWHeart, lifeVal: dLHeart))
                    tempHistF.append(DailyData(id: id, date: date, dayName: dayName, workVal: dWFlights, lifeVal: dLFlights))
                    
                    tWSteps+=dWSteps; tLSteps+=dLSteps; tWCal+=dWCal; tLCal+=dLCal; tWDist+=dWDist; tLDist+=dLDist; tWFlights+=dWFlights; tLFlights+=dLFlights
                    if dWHeart>0 { tWBPM.append(dWHeart) }; if dLHeart>0 { tLBPM.append(dLHeart) }
                    group.leave()
                }
            } else {
                let iG = DispatchGroup()
                iG.enter(); healthManager.fetchQuantity(type: .stepCount, start: startOfDay, end: endOfDay) { v in dLSteps=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .activeEnergyBurned, start: startOfDay, end: endOfDay) { v in dLCal=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .distanceWalkingRunning, start: startOfDay, end: endOfDay) { v in dLDist=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .heartRate, start: startOfDay, end: endOfDay) { v in dLHeart=v; iG.leave() }
                iG.enter(); healthManager.fetchQuantity(type: .flightsClimbed, start: startOfDay, end: endOfDay) { v in dLFlights=v; iG.leave() }
                
                iG.notify(queue: .main) {
                    let id = UUID()
                    tempHistS.append(DailyData(id: id, date: date, dayName: dayName, workVal: 0, lifeVal: dLSteps))
                    tempHistC.append(DailyData(id: id, date: date, dayName: dayName, workVal: 0, lifeVal: dLCal))
                    tempHistD.append(DailyData(id: id, date: date, dayName: dayName, workVal: 0, lifeVal: dLDist))
                    tempHistH.append(DailyData(id: id, date: date, dayName: dayName, workVal: 0, lifeVal: dLHeart))
                    tempHistF.append(DailyData(id: id, date: date, dayName: dayName, workVal: 0, lifeVal: dLFlights))
                    tLSteps+=dLSteps; tLCal+=dLCal; tLDist+=dLDist; tLFlights+=dLFlights
                    if dLHeart>0 { tLBPM.append(dLHeart) }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            withAnimation {
                self.totalWorkSteps = tWSteps/7; self.totalLifeSteps = tLSteps/7
                self.totalWorkCal = tWCal/7; self.totalLifeCal = tLCal/7
                self.totalWorkDist = tWDist/7; self.totalLifeDist = tLDist/7
                self.totalWorkFlights = tWFlights/7; self.totalLifeFlights = tLFlights/7
                
                let sW = tWBPM.reduce(0, +); self.avgWorkHeart = tWBPM.isEmpty ? 0 : sW/Double(tWBPM.count)
                let sL = tLBPM.reduce(0, +); self.avgLifeHeart = tLBPM.isEmpty ? 0 : sL/Double(tLBPM.count)
                
                self.historySteps = tempHistS.sorted(by: { $0.date < $1.date })
                self.historyCal = tempHistC.sorted(by: { $0.date < $1.date })
                self.historyDist = tempHistD.sorted(by: { $0.date < $1.date })
                self.historyHeart = tempHistH.sorted(by: { $0.date < $1.date })
                self.historyFlights = tempHistF.sorted(by: { $0.date < $1.date })
                self.isLoading = false
            }
        }
    }
    
    // --- PETITS HELPERS ---
    func changeWeek(by weeks: Int) { if let new = Calendar.current.date(byAdding: .day, value: weeks * 7, to: selectedDate) { selectedDate = (new > Date()) ? Date() : new; analyzeWeek() } }
    func isSelectedDateCurrentWeek() -> Bool { Calendar.current.isDate(selectedDate, equalTo: Date(), toGranularity: .weekOfYear) }
    func getDataFor(_ type: MetricType) -> [DailyData] {
        switch type {
        case .steps: return historySteps
        case .calories: return historyCal
        case .distance: return historyDist
        case .heart: return historyHeart
        case .flights: return historyFlights
        }
    }
}

// MARK: - TOUS LES COMPOSANTS (POUR ÉVITER LES ERREURS)

// 1. Barre de navigation (Date)
struct DateNavigationBar: View {
    @Binding var selectedDate: Date
    let onDateChange: () -> Void
    let isLocked: Bool
    
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: { changeWeek(by: -1) }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("Période analysée").font(.caption).foregroundStyle(.secondary).textCase(.uppercase)
                    if isLocked {
                        HStack {
                            Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.orange)
                            Text(dateRangeString()).font(.headline).bold().foregroundStyle(.secondary)
                        }
                    } else {
                        Text(dateRangeString()).font(.headline).bold().foregroundStyle(.primary).contentTransition(.numericText())
                    }
                }
                Spacer()
                Button(action: { changeWeek(by: 1) }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(isSelectedDateCurrentWeek() ? Color.gray.opacity(0.3) : .secondary)
                }
                .disabled(isSelectedDateCurrentWeek())
            }
            .padding(.horizontal).padding(.vertical, 8).background(Color(UIColor.secondarySystemBackground)).cornerRadius(12)
            
            if !isSelectedDateCurrentWeek() {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium); generator.impactOccurred()
                    withAnimation { selectedDate = Date(); onDateChange() }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Revenir à la semaine en cours")
                    }
                    .font(.caption).bold().foregroundStyle(.orange)
                    .padding(.vertical, 6).padding(.horizontal, 12)
                    .background(Color.orange.opacity(0.1)).clipShape(Capsule())
                }
                .transition(.scale.combined(with: .opacity))
            }
        }.padding(.horizontal)
    }
    
    func changeWeek(by weeks: Int) {
        if let new = Calendar.current.date(byAdding: .day, value: weeks * 7, to: selectedDate) {
            selectedDate = (new > Date()) ? Date() : new
            onDateChange()
        }
    }
    func isSelectedDateCurrentWeek() -> Bool { Calendar.current.isDate(selectedDate, equalTo: Date(), toGranularity: .weekOfYear) }
    func dateRangeString() -> String {
        var calendar = Calendar.current; calendar.locale = Locale(identifier: selectedLanguage)
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return "" }
        let f = DateFormatter(); f.locale = Locale(identifier: selectedLanguage); f.dateFormat = "d MMM"
        let endOfWeekDisplay = calendar.date(byAdding: .day, value: -1, to: weekInterval.end) ?? weekInterval.end
        return "\(f.string(from: weekInterval.start)) - \(f.string(from: endOfWeekDisplay))"
    }
}

// 2. Carte Verrouillée
struct LockedMetricCard: View {
    let title: String; let icon: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                HStack {
                    HStack(spacing: 8) { Image(systemName: icon).foregroundStyle(color); Text(title).font(.headline).foregroundStyle(.primary) }
                    Spacer()
                    Text("PRO").font(.caption2.bold()).padding(.horizontal, 6).padding(.vertical, 3).background(color).foregroundStyle(.white).cornerRadius(6)
                }
                ZStack {
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) { Text("8.4").font(.system(size: 24, weight: .bold, design: .rounded)); Text("Travail").font(.caption2).bold() }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) { Text("12.2").font(.system(size: 24, weight: .bold, design: .rounded)); Text("Perso").font(.caption2).bold() }
                    }.foregroundStyle(.secondary).blur(radius: 6)
                    Circle().fill(Color(UIColor.systemBackground)).frame(width: 44, height: 44).shadow(radius: 4).overlay(Image(systemName: "lock.fill").foregroundStyle(color))
                }
            }.padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1))
        }.buttonStyle(.plain)
    }
}

// 3. Récap Hebdo
struct WeeklyRecapView: View {
    let referenceDate: Date; let isLocked: Bool
    @ObservedObject var premiumManager = PremiumManager.shared
    
    @Query private var sessions: [WorkSession]
    @State private var healthManager = HealthManager()
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    @State private var showAnimations = false
    @State private var animatedHours: Double = 0; @State private var animatedSteps: Double = 0
    @State private var animatedDist: Double = 0; @State private var animatedCal: Double = 0
    @State private var weeklyWorkData: [Double] = [0,0,0,0,0,0,0]
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Calendar.current.isDate(referenceDate, equalTo: Date(), toGranularity: .weekOfYear) ? "CETTE SEMAINE" : "RÉSUMÉ").font(.caption).fontWeight(.bold).foregroundStyle(.white.opacity(0.7))
                        Text(getDateRange()).font(.caption2).foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer(); if animatedHours > 0 { HStack(spacing: 4) { Image(systemName: "flame.fill"); Text("Actif") }.font(.caption2).bold().padding(.horizontal, 8).padding(.vertical, 4).background(.white.opacity(0.2)).cornerRadius(10).foregroundStyle(.white) }
                }.padding(.bottom, 20)
                HStack(alignment: .firstTextBaseline) {
                    Text(String(format: "%.1f", animatedHours)).font(.system(size: 54, weight: .heavy, design: .rounded)).foregroundStyle(.white).contentTransition(.numericText())
                    Text("heures").font(.title3).fontWeight(.medium).foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    HStack(alignment: .bottom, spacing: 4) { ForEach(0..<7, id: \.self) { index in VStack { Spacer(); RoundedRectangle(cornerRadius: 2).fill(.white.opacity(weeklyWorkData[index] > 0 ? 0.9 : 0.2)).frame(width: 6, height: showAnimations ? CGFloat(min(40, max(4, weeklyWorkData[index] * 3))) : 0) }.frame(height: 40) } }
                }.padding(.bottom, 25)
                
                HStack(spacing: 0) {
                    StatBox(icon: "figure.walk", val: "\(Int(animatedSteps))", label: "Pas", delay: 0.1)
                    Divider().background(.white.opacity(0.2)).frame(height: 30)
                    
                    if premiumManager.canViewDetailedMetrics() {
                        StatBox(icon: "map.fill", val: String(format: "%.1f", animatedDist), label: "Km", delay: 0.2)
                    } else {
                        VStack(spacing: 4) {
                            Image(systemName: "lock.fill").font(.caption).foregroundStyle(.white.opacity(0.6))
                            Text("---").font(.headline).bold().foregroundStyle(.white.opacity(0.5))
                            Text("Km (Pro)").font(.caption2).foregroundStyle(.white.opacity(0.6))
                        }.frame(maxWidth: .infinity)
                    }
                    
                    Divider().background(.white.opacity(0.2)).frame(height: 30)
                    StatBox(icon: "flame.fill", val: "\(Int(animatedCal))", label: "Kcal", delay: 0.3)
                }
                .padding(.top, 15).background(Color.white.opacity(0.1)).cornerRadius(12)
                
            }.padding(24).blur(radius: isLocked ? 10 : 0)
            
            if isLocked {
                Rectangle().fill(.ultraThinMaterial).opacity(0.6).cornerRadius(24)
                VStack(spacing: 15) { Circle().fill(.white.opacity(0.2)).frame(width: 60, height: 60).overlay(Image(systemName: "lock.fill").font(.title).foregroundStyle(.white)); VStack(spacing: 5) { Text("Récap en cours...").font(.headline).foregroundStyle(.white); Text("Disponible dans :").font(.caption).foregroundStyle(.white.opacity(0.7)); CountdownView(targetDate: nextMonday()).font(.system(.title3, design: .monospaced)).fontWeight(.bold).foregroundStyle(.orange).padding(.top, 2) } }
            }
        }.background(ZStack { LinearGradient(colors: [Color.orange, Color.orange.opacity(0.85), Color.red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing); Circle().fill(.white.opacity(0.05)).frame(width: 200).offset(x: 100, y: -100); Circle().fill(.white.opacity(0.05)).frame(width: 150).offset(x: -120, y: 80) }).cornerRadius(24).shadow(color: .orange.opacity(0.4), radius: 15, x: 0, y: 8).padding(.horizontal).onAppear { loadData(); withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { showAnimations = true } }.onChange(of: referenceDate) { _, _ in loadData() }
    }
    func nextMonday() -> Date { var cal = Calendar.current; cal.locale = Locale(identifier: selectedLanguage); let now = Date(); guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: now) else { return Date() }; return weekInterval.end }
    func StatBox(icon: String, val: String, label: String, delay: Double) -> some View { VStack(spacing: 4) { Image(systemName: icon).font(.title3).foregroundStyle(.white.opacity(0.8)).scaleEffect(showAnimations ? 1 : 0.5).animation(.bouncy.delay(delay), value: showAnimations); Text(val).font(.headline).bold().foregroundStyle(.white).contentTransition(.numericText()); Text(label).font(.caption2).foregroundStyle(.white.opacity(0.6)) }.frame(maxWidth: .infinity) }
    func loadData() { var calendar = Calendar.current; calendar.locale = Locale(identifier: selectedLanguage); guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { return }; let startOfWeek = weekInterval.start; let endOfWeek = weekInterval.end; let weeklySessions = sessions.filter { $0.startTime >= startOfWeek && $0.startTime < endOfWeek }; let totalSeconds = weeklySessions.reduce(0) { tot, s in guard let end = s.endTime else { return tot }; return tot + end.timeIntervalSince(s.startTime) }; let totalHours = totalSeconds / 3600; var tempGraph: [Double] = [0,0,0,0,0,0,0]; for session in weeklySessions { let daysFromStart = calendar.dateComponents([.day], from: startOfWeek, to: session.startTime).day ?? 0; if daysFromStart >= 0 && daysFromStart < 7 { if let end = session.endTime { let h = end.timeIntervalSince(session.startTime) / 3600; tempGraph[daysFromStart] += h } } }; let group = DispatchGroup(); var s: Double=0; var d: Double=0; var c: Double=0; group.enter(); healthManager.fetchQuantity(type: .stepCount, start: startOfWeek, end: endOfWeek) { v in s = v; group.leave() }; group.enter(); healthManager.fetchQuantity(type: .distanceWalkingRunning, start: startOfWeek, end: endOfWeek) { v in d = v; group.leave() }; group.enter(); healthManager.fetchQuantity(type: .activeEnergyBurned, start: startOfWeek, end: endOfWeek) { v in c = v; group.leave() }; group.notify(queue: .main) { withAnimation(.easeOut(duration: 1.0)) { self.animatedHours = totalHours; self.weeklyWorkData = tempGraph; self.animatedSteps = s; self.animatedDist = d; self.animatedCal = c } } }
    func getDateRange() -> String { var calendar = Calendar.current; calendar.locale = Locale(identifier: selectedLanguage); guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else { return "" }; let f = DateFormatter(); f.locale = Locale(identifier: selectedLanguage); f.dateFormat = "d MMM"; let endOfWeekDisplay = calendar.date(byAdding: .day, value: -1, to: weekInterval.end) ?? weekInterval.end; return "\(f.string(from: weekInterval.start)) - \(f.string(from: endOfWeekDisplay))" }
}

// 4. Compte à rebours
struct CountdownView: View {
    let targetDate: Date
    var body: some View { TimelineView(.periodic(from: .now, by: 1.0)) { context in Text(timeRemaining(until: targetDate, context: context)) } }
    func timeRemaining(until target: Date, context: TimelineViewDefaultContext) -> String { let diff = target.timeIntervalSince(context.date); if diff <= 0 { return "00j 00h 00m" }; let days = Int(diff) / 86400; let hours = (Int(diff) % 86400) / 3600; let minutes = (Int(diff) % 3600) / 60; return days > 0 ? "\(days)j \(hours)h \(minutes)m" : "\(hours)h \(minutes)m \(Int(diff) % 60)s" }
}

// 5. Carte Score Simple
struct SimpleScoreCard: View {
    let type: MetricType; let workVal: Double; let lifeVal: Double
    var body: some View {
        let total = workVal + lifeVal; let workPercent = total > 0 ? workVal / total : 0
        VStack(spacing: 15) {
            HStack { HStack(spacing: 8) { Image(systemName: iconFor(type)).foregroundStyle(type.color); Text(LocalizedStringKey(type.title)).font(.headline) }; Spacer(); Text("Total : " + format(total)).font(.subheadline).bold().foregroundStyle(.secondary) }
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2) { Text(format(workVal)).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(.orange); Text("Travail").font(.caption2).bold().foregroundStyle(.orange.opacity(0.8)) }; Spacer()
                GeometryReader { geo in ZStack(alignment: .leading) { Capsule().fill(Color.gray.opacity(0.2)).frame(height: 6); Capsule().fill(Color.orange).frame(width: geo.size.width * workPercent, height: 6) } }.frame(height: 6).padding(.horizontal, 20); Spacer()
                VStack(alignment: .trailing, spacing: 2) { Text(format(lifeVal)).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(.gray); Text("Perso").font(.caption2).bold().foregroundStyle(.gray) }
            }
        }.padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1))
    }
    func format(_ val: Double) -> String { if type == .distance { return String(format: "%.1f km", val) }; return "\(Int(val))" }
    func iconFor(_ type: MetricType) -> String { switch type { case .steps: return "figure.walk"; case .calories: return "flame.fill"; case .distance: return "map.fill"; case .heart: return "heart.fill"; case .flights: return "figure.stairs" } }
}

// 6. Carte Cardio Simple
struct SimpleCardioCard: View {
    let workBPM: Double; let lifeBPM: Double
    var body: some View {
        VStack(spacing: 15) {
            HStack { HStack(spacing: 8) { Image(systemName: "heart.fill").foregroundStyle(.pink); Text("Cardio Moyen").font(.headline) }; Spacer() }
            HStack(alignment: .center) {
                VStack { Text(workBPM > 0 ? "\(Int(workBPM))" : "--").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(.pink); Text("Travail (BPM)").font(.caption2).bold().foregroundStyle(.pink.opacity(0.8)) }.frame(maxWidth: .infinity)
                Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 1, height: 30)
                VStack { Text(lifeBPM > 0 ? "\(Int(lifeBPM))" : "--").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(.gray); Text("Perso (BPM)").font(.caption2).bold().foregroundStyle(.gray) }.frame(maxWidth: .infinity)
            }
        }.padding().background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1))
    }
}

// 7. Vue Détail (Sheet)
struct DetailMetricView: View {
    let type: MetricType; let data: [DailyData]; let language: String; @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Vue d'ensemble")) { Chart { ForEach(data) { day in BarMark(x: .value("Jour", day.dayName), y: .value("Travail", day.workVal)).foregroundStyle(type.color); if type != .heart { BarMark(x: .value("Jour", day.dayName), y: .value("Perso", day.lifeVal)).foregroundStyle(type.color.opacity(0.3)) } else { PointMark(x: .value("Jour", day.dayName), y: .value("Perso", day.lifeVal)).foregroundStyle(Color.gray) } } }.frame(height: 200).padding(.vertical) }
                Section(header: Text("Détails par jour")) { ForEach(data.reversed()) { day in HStack { VStack(alignment: .leading) { Text(day.date.formatted(date: .abbreviated, time: .omitted)).bold(); Text(day.dayName.capitalized).font(.caption).foregroundStyle(.secondary) }; Spacer(); VStack(alignment: .trailing, spacing: 4) { HStack { Text("Travail").font(.caption2).foregroundStyle(.secondary); Text(format(day.workVal)).bold().foregroundStyle(type.color).frame(minWidth: 60, alignment: .trailing) }; HStack { Text("Perso").font(.caption2).foregroundStyle(.secondary); Text(format(day.lifeVal)).bold().foregroundStyle(type == .heart ? Color.gray : type.color.opacity(0.6)).frame(minWidth: 60, alignment: .trailing) }; if type != .heart { Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 80, height: 1).padding(.vertical, 2); HStack { Text("Total").font(.caption2).bold(); Text(format(day.workVal + day.lifeVal)).bold().foregroundStyle(.primary).frame(minWidth: 60, alignment: .trailing) } } } }.padding(.vertical, 4) } }
            }.navigationTitle(type.title).navigationBarTitleDisplayMode(.inline).toolbar { Button("Fermer") { dismiss() } }
        }
    }
    func format(_ val: Double) -> String { if type == .distance { return String(format: "%.2f km", val) }; return "\(Int(val)) \(type.unit)" }
}
