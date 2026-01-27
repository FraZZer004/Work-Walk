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
    @Query(sort: \WorkSession.startTime, order: .reverse) private var sessions: [WorkSession]
    @AppStorage("hourlyRate") private var hourlyRate: Double = 11.91
    @AppStorage("taxRate") private var taxRate: Double = 23.05
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    @AppStorage("username") private var username: String = "Utilisateur"
    @State private var selectedDate = Date()
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    HStack {
                        Button(action: { changeMonth(by: -1) }) { Image(systemName: "chevron.left.circle.fill").font(.title2).foregroundStyle(.orange) }
                        Text(monthFormatter.string(from: selectedDate).capitalized).font(.title3).bold().frame(width: 160).multilineTextAlignment(.center)
                        Button(action: { changeMonth(by: 1) }) { Image(systemName: "chevron.right.circle.fill").font(.title2).foregroundStyle(.orange) }
                    }.padding(.top)
                    VStack(spacing: 10) {
                        Text(LocalizedStringKey("Salaire Net Estimé")).font(.headline).foregroundStyle(.secondary)
                        Text(formatCurrency(calculateNet())).font(.system(size: 46, weight: .bold, design: .rounded)).foregroundStyle(.orange).contentTransition(.numericText())
                        HStack(spacing: 5) { Image(systemName: "clock.arrow.circlepath"); Text("Basé sur \(formatHours(calculateHours())) travaillées") }.font(.caption).padding(8).background(Color.orange.opacity(0.1)).cornerRadius(20)
                    }.padding().frame(maxWidth: .infinity).background(Color(UIColor.systemGray6)).cornerRadius(20).padding(.horizontal)
                    ShareLink(item: renderPDF(), preview: SharePreview("\(pdfPrefix) \(monthFormatter.string(from: selectedDate))", image: Image("AppLogo"))) { HStack { Image(systemName: "square.and.arrow.up"); Text(LocalizedStringKey("Exporter la fiche (PDF)")) }.font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding().background(Color.blue).cornerRadius(15).shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3) }.padding(.horizontal)
                    VStack(alignment: .leading, spacing: 15) {
                        Text(LocalizedStringKey("Détails du calcul")).font(.headline).padding(.leading)
                        VStack(spacing: 0) {
                            DetailRow(title: "Heures saisies", value: formatHours(calculateHours()), isBold: false)
                            DetailRow(title: "Taux horaire", value: "x \(hourlyRate) \(currencySymbol)", isBold: false)
                            Divider().padding(.vertical, 8)
                            DetailRow(title: "Salaire Brut", value: formatCurrency(calculateGross()), isBold: true)
                            HStack { Text(LocalizedStringKey("Charges estimées")).font(.subheadline).foregroundStyle(.secondary); Text("(-\(Int(taxRate))%)").font(.caption).foregroundStyle(.red); Spacer(); Text("- " + formatCurrency(calculateGross() * (taxRate/100))).font(.subheadline).foregroundStyle(.red) }.padding(.vertical, 8)
                            Divider().padding(.vertical, 8)
                            HStack { Text(LocalizedStringKey("Net à payer")).font(.headline); Spacer(); Text(formatCurrency(calculateNet())).font(.headline).foregroundStyle(.orange) }
                        }.padding().background(Color(UIColor.systemGray6)).cornerRadius(16).padding(.horizontal)
                    }
                    VStack(alignment: .leading) { Text(LocalizedStringKey("Paramètres de paie")).font(.headline).padding(.top); VStack { HStack { Text(LocalizedStringKey("Taux horaire (Brut)")); Spacer(); TextField("11.91", value: $hourlyRate, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80).padding(5).background(Color(UIColor.systemGray5)).cornerRadius(8); Text(currencySymbol) }; Divider(); HStack { Text(LocalizedStringKey("Charges (%)")); Spacer(); TextField("23", value: $taxRate, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80).padding(5).background(Color(UIColor.systemGray5)).cornerRadius(8); Text("%") } }.padding().background(Color(UIColor.systemGray6)).cornerRadius(16) }.padding(.horizontal)
                }.padding(.bottom)
            }.navigationTitle("Mon Salaire")
        }
    }
    @MainActor func renderPDF() -> URL {
        let template = SalaryPDFTemplate(month: monthFormatter.string(from: selectedDate), hours: formatHours(calculateHours()), rate: hourlyRate, gross: formatCurrency(calculateGross()), taxRate: taxRate, taxAmount: formatCurrency(calculateGross() * (taxRate/100)), net: formatCurrency(calculateNet()), symbol: currencySymbol, userName: username.isEmpty ? "Utilisateur" : username).environment(\.locale, Locale(identifier: selectedLanguage))
        let renderer = ImageRenderer(content: template); let url = URL.documentsDirectory.appending(path: "Fiche_WorkWalk_\(monthFormatter.string(from: selectedDate)).pdf")
        renderer.render { size, context in var box = CGRect(x: 0, y: 0, width: size.width, height: size.height); guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }; pdf.beginPDFPage(nil); context(pdf); pdf.endPDFPage(); pdf.closePDF() }
        return url
    }
    var pdfPrefix: String { selectedLanguage == "en" ? "Payslip" : "Fiche" }; var currencySymbol: String { selectedLanguage == "en" ? "$" : "€" }
    func changeMonth(by value: Int) { if let new = Calendar.current.date(byAdding: .month, value: value, to: selectedDate) { selectedDate = new } }
    func calculateHours() -> Double { let cal = Calendar.current; let monthSessions = sessions.filter { cal.isDate($0.startTime, equalTo: selectedDate, toGranularity: .month) && cal.isDate($0.startTime, equalTo: selectedDate, toGranularity: .year) }; let sec = monthSessions.reduce(0) { tot, s in guard let e = s.endTime else { return tot }; return tot + e.timeIntervalSince(s.startTime) }; return sec / 3600 }
    func calculateGross() -> Double { return calculateHours() * hourlyRate }; func calculateNet() -> Double { let g = calculateGross(); return g - (g * (taxRate/100)) }
    func formatCurrency(_ val: Double) -> String { let f = NumberFormatter(); f.numberStyle = .currency; let localeID = selectedLanguage == "en" ? "en_US" : "fr_FR"; f.locale = Locale(identifier: localeID); return f.string(from: NSNumber(value: val)) ?? "\(val)" }
    func formatHours(_ val: Double) -> String { return String(format: "%.2fh", val) }
    private var monthFormatter: DateFormatter { let f = DateFormatter(); f.locale = Locale(identifier: selectedLanguage); f.dateFormat = "MMMM yyyy"; return f }
}

struct DetailRow: View {
    let title: String; let value: String; let isBold: Bool
    var body: some View { HStack { Text(LocalizedStringKey(title)).font(.subheadline).foregroundStyle(.secondary); Spacer(); Text(value).font(.subheadline).fontWeight(isBold ? .bold : .regular).foregroundStyle(.primary) }.padding(.vertical, 2) }
}
