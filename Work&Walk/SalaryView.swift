//
//  SalaryView.swift
//  Work&Walk
//
//  Created by Alan Krieger on 27/01/2026.
//

import SwiftUI
import SwiftData
import Charts

struct SalaryView: View {
    // --- CONNEXION AU PREMIUM MANAGER ---
    @ObservedObject var premiumManager = PremiumManager.shared
    @State private var showPremiumAlert = false
    
    @Query(sort: \WorkSession.startTime, order: .reverse) private var sessions: [WorkSession]
    @AppStorage("hourlyRate") private var hourlyRate: Double = 11.91
    @AppStorage("taxRate") private var taxRate: Double = 23.05
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    @AppStorage("username") private var username: String = "Utilisateur"
    
    @State private var selectedDate = Date()
    
    // Cette variable contrôle si le clavier est ouvert ou non
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // 👇 J'ai ajouté le onTapGesture sur ce VStack principal
                VStack(spacing: 25) {
                    
                    // --- SÉLECTEUR DE MOIS ---
                    HStack {
                        Button(action: { changeMonth(by: -1) }) {
                            Image(systemName: "chevron.left.circle.fill").font(.title2).foregroundStyle(.orange)
                        }
                        Text(monthFormatter.string(from: selectedDate).capitalized)
                            .font(.title3).bold()
                            .frame(width: 160)
                            .multilineTextAlignment(.center)
                        Button(action: { changeMonth(by: 1) }) {
                            Image(systemName: "chevron.right.circle.fill").font(.title2).foregroundStyle(.orange)
                        }
                    }
                    .padding(.top)
                    
                    // --- CARTE PRINCIPALE (SALAIRE NET) ---
                    VStack(spacing: 10) {
                        Text(LocalizedStringKey("Salaire Net Estimé"))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text(formatCurrency(calculateNet()))
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                            .contentTransition(.numericText())
                        
                        HStack(spacing: 5) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Basé sur \(formatHours(calculateHours())) travaillées")
                        }
                        .font(.caption)
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // --- BOUTON EXPORT PDF (INTELLIGENT 🔒) ---
                    if premiumManager.canExportSalaryPDF() {
                        // ✅ VERSION PREMIUM : Bouton Fonctionnel
                        ShareLink(item: renderPDF(), preview: SharePreview("\(pdfPrefix) \(monthFormatter.string(from: selectedDate))", image: Image("AppLogo"))) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text(LocalizedStringKey("Exporter la fiche (PDF)"))
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
                    } else {
                        // ❌ VERSION GRATUITE : Bouton "Teaser" Premium
                        Button(action: {
                            showPremiumAlert = true
                        }) {
                            HStack(spacing: 12) {
                                // Icône Cadenas Stylisée
                                ZStack {
                                    Circle()
                                        .fill(Color.orange.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "lock.fill")
                                        .font(.caption.bold())
                                        .foregroundStyle(.orange)
                                }
                                
                                Text("Exporter la fiche")
                                    .font(.headline)
                                    .foregroundStyle(.primary) // S'adapte au mode sombre/clair
                                
                                Spacer()
                                
                                // Badge PRO
                                Text("PRO")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .foregroundStyle(.white)
                                    .cornerRadius(8)
                                    .shadow(color: .orange.opacity(0.4), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground)) // Fond carte standard
                            // Bordure subtile pour montrer que c'est précieux
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(LinearGradient(colors: [.orange.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing), lineWidth: 1.5)
                            )
                            .cornerRadius(16)
                            // Ombre légère pour le détacher
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                    }
                    
                    // --- DÉTAILS DU CALCUL ---
                    VStack(alignment: .leading, spacing: 15) {
                        Text(LocalizedStringKey("Détails du calcul"))
                            .font(.headline)
                            .padding(.leading)
                        
                        VStack(spacing: 0) {
                            DetailRow(title: "Heures saisies", value: formatHours(calculateHours()), isBold: false)
                            DetailRow(title: "Taux horaire", value: "x \(hourlyRate) \(currencySymbol)", isBold: false)
                            
                            Divider().padding(.vertical, 8)
                            
                            DetailRow(title: "Salaire Brut", value: formatCurrency(calculateGross()), isBold: true)
                            
                            HStack {
                                Text(LocalizedStringKey("Charges estimées"))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("(-\(Int(taxRate))%)")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                Spacer()
                                Text("- " + formatCurrency(calculateGross() * (taxRate/100)))
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                            .padding(.vertical, 8)
                            
                            Divider().padding(.vertical, 8)
                            
                            HStack {
                                Text(LocalizedStringKey("Net à payer")).font(.headline)
                                Spacer()
                                Text(formatCurrency(calculateNet()))
                                    .font(.headline)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // --- PARAMÈTRES DE PAIE (MODIFIABLE) ---
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey("Paramètres de paie"))
                            .font(.headline)
                            .padding(.top)
                        
                        VStack {
                            // Taux Horaire
                            HStack {
                                Text(LocalizedStringKey("Taux horaire (Brut)"))
                                Spacer()
                                TextField("11.91", value: $hourlyRate, format: .number)
                                    .keyboardType(.decimalPad)
                                    .focused($isInputFocused) // Focus ici
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .padding(5)
                                    .background(Color(UIColor.systemGray5))
                                    .cornerRadius(8)
                                Text(currencySymbol)
                            }
                            
                            Divider()
                            
                            // Charges
                            HStack {
                                Text(LocalizedStringKey("Charges (%)"))
                                Spacer()
                                TextField("23", value: $taxRate, format: .number)
                                    .keyboardType(.decimalPad)
                                    .focused($isInputFocused) // Focus ici aussi
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .padding(5)
                                    .background(Color(UIColor.systemGray5))
                                    .cornerRadius(8)
                                Text("%")
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(16)
                        
                        // J'ai remis la toolbar ICI, au plus près des champs
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("OK") {
                                    isInputFocused = false
                                }
                                .tint(.orange)
                                .fontWeight(.bold)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 50)
                // 👇 C'EST ÇA QUI VA TE SAUVER LA VIE 👇
                // Si on tape n'importe où dans le vide, le clavier se ferme
                .onTapGesture {
                    isInputFocused = false
                }
                // À la fin de ton ScrollView ou VStack
                .onAppear {
                    updateWidgetData()
                }
                .onChange(of: sessions) { _, _ in
                    updateWidgetData()
                }
            }
            .navigationTitle("Mon Salaire")
            .scrollDismissesKeyboard(.interactively) // Glisser pour fermer
            
            // --- PAGE DE VENTE PREMIUM (SHEET) ---
            .sheet(isPresented: $showPremiumAlert) {
                SubscriptionView()
                    .presentationDetents([.fraction(0.9)]) // Prend 90% de l'écran
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // --- LOGIQUE METIER & FORMATAGE ---
    
    @MainActor func renderPDF() -> URL {
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
        ).environment(\.locale, Locale(identifier: selectedLanguage))
        
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
    
    var pdfPrefix: String { selectedLanguage == "en" ? "Payslip" : "Fiche" }
    var currencySymbol: String { selectedLanguage == "en" ? "$" : "€" }
    
    func changeMonth(by value: Int) {
        if let new = Calendar.current.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = new
        }
    }
    
    func calculateHours() -> Double {
        let cal = Calendar.current
        let monthSessions = sessions.filter {
            cal.isDate($0.startTime, equalTo: selectedDate, toGranularity: .month) &&
            cal.isDate($0.startTime, equalTo: selectedDate, toGranularity: .year)
        }
        let sec = monthSessions.reduce(0) { tot, s in
            guard let e = s.endTime else { return tot }
            return tot + e.timeIntervalSince(s.startTime)
        }
        return sec / 3600
    }
    
    func calculateGross() -> Double { return calculateHours() * hourlyRate }
    
    func calculateNet() -> Double {
        let g = calculateGross()
        return g - (g * (taxRate/100))
    }
    
    func formatCurrency(_ val: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        let localeID = selectedLanguage == "en" ? "en_US" : "fr_FR"
        f.locale = Locale(identifier: localeID)
        return f.string(from: NSNumber(value: val)) ?? "\(val)"
    }
    
    func formatHours(_ val: Double) -> String {
        return String(format: "%.2fh", val)
    }
    
    private var monthFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: selectedLanguage)
        f.dateFormat = "MMMM yyyy"
        return f
    }
    
    // 1. La fonction qui calcule le total d'aujourd'hui
    func updateWidgetData() {
        // On filtre les sessions d'aujourd'hui seulement
        let today = Date()
        let calendar = Calendar.current
        let todaysSessions = sessions.filter { calendar.isDate($0.startTime, inSameDayAs: today) }
        
        // On calcule le total
        let totalSeconds = todaysSessions.reduce(0) { $0 + ($1.endTime?.timeIntervalSince($1.startTime) ?? 0) }
        let totalHours = totalSeconds / 3600.0
        let totalSalary = totalHours * hourlyRate
        
        // On sauvegarde pour le HealthManager
        UserDefaults.standard.set(totalSalary, forKey: "manual_today_salary")
        UserDefaults.standard.set(formatHours(totalHours), forKey: "manual_today_hours")
        
        // On force le rafraîchissement immédiat
        HealthManager.shared.fetchTodayStepsAndRefreshWidget()
    }
}

// --- SOUS-VUES ---

struct DetailRow: View {
    let title: String
    let value: String
    let isBold: Bool
    
    var body: some View {
        HStack {
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
