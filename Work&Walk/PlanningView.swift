//
//  PlanningView.swift
//  Work&Walk
//
//  Created by Alan Krieger on 27/01/2026.
//


import SwiftUI
import SwiftData

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
    
    // Calendrier Dynamique
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
                        if viewMode == .calendar { ScrollView {
                            VStack(spacing: 20) {
                                totalHoursBadge(sessions: filteredSessions)
                                
                                MonthGridView(
                                    year: selectedYear,
                                    month: selectedMonth,
                                    sessions: filteredSessions,
                                    language: selectedLanguage,
                                    onSelectDay: { date, session in
                                        if let session = session {
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.impactOccurred()
                                            sessionToEdit = session
                                        }
                                    }
                                )
                            }
                            .padding(.top)
                        } }
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
                            ScrollView { VStack(spacing: 20) { totalHoursBadge(sessions: filteredSessions); MonthGridView(year: selectedYear, month: selectedMonth, sessions: filteredSessions, language: selectedLanguage, onSelectDay: { _, _ in }) }.padding(.top) }
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
        if minutes > 0 { return "\(hours)h\(minutes < 10 ? "0" : "")\(minutes)" } else { return "\(hours)h" }
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
        ScrollView { VStack(spacing: 20) { HStack { Text("Total \(String(year)) :").foregroundStyle(.secondary); Text(calculateTotalHours(for: sessionsInYear)).font(.title3).bold().foregroundStyle(.orange) }.padding().frame(maxWidth: .infinity).background(Color(UIColor.systemGray6)).cornerRadius(16).padding(.horizontal); LazyVGrid(columns: columns, spacing: 15) { ForEach(1...12, id: \.self) { month in monthCell(month: month) } }.padding(.horizontal) }.padding(.top) }
    }
    func monthCell(month: Int) -> some View {
        let sessionsInMonth = sessionsInYear.filter { Calendar.current.component(.month, from: $0.startTime) == month }
        let totalHours = calculateTotalHours(for: sessionsInMonth); let hasHours = !sessionsInMonth.isEmpty
        let f = DateFormatter(); f.locale = Locale(identifier: language); let name = f.monthSymbols[month - 1]
        return VStack(spacing: 5) { Text(name.prefix(3).capitalized).font(.caption).bold().foregroundStyle(.secondary); Text(totalHours).font(.headline).foregroundStyle(hasHours ? Color.primary : Color.gray.opacity(0.3)) }.frame(height: 80).frame(maxWidth: .infinity).background(hasHours ? Color.orange.opacity(0.1) : Color(UIColor.systemGray6)).overlay(RoundedRectangle(cornerRadius: 12).stroke(hasHours ? Color.orange : Color.clear, lineWidth: 1)).cornerRadius(12)
    }
    func calculateTotalHours(for sessions: [WorkSession]) -> String {
        let totalSeconds = sessions.reduce(0) { total, session in guard let end = session.endTime else { return total }; return total + end.timeIntervalSince(session.startTime) }
        let hours = Int(totalSeconds) / 3600; let minutes = (Int(totalSeconds) % 3600) / 60; if minutes > 0 { return "\(hours)h\(minutes < 10 ? "0" : "")\(minutes)" } else { return "\(hours)h" }
    }
}

struct SessionRow: View {
    let session: WorkSession; let language: String
    private var timeFormatter: DateFormatter { let f = DateFormatter(); f.locale = Locale(identifier: language); f.dateFormat = "HH:mm"; return f }
    private func formatDurationSimple(start: Date, end: Date) -> String { let diff = end.timeIntervalSince(start); let h = Int(diff) / 3600; let m = (Int(diff) % 3600) / 60; return "\(h)h \(m < 10 ? "0" : "")\(m)" }
    var body: some View {
        HStack { VStack(alignment: .leading) { Text("\(timeFormatter.string(from: session.startTime)) - \(session.endTime != nil ? timeFormatter.string(from: session.endTime!) : "En cours")").font(.headline) }; Spacer(); if let end = session.endTime { Text(formatDurationSimple(start: session.startTime, end: end)).font(.subheadline).bold().foregroundStyle(.orange) } else { Text("En cours").font(.caption).foregroundStyle(.green) } }.padding(.vertical, 4)
    }
}

struct MonthGridView: View {
    let year: Int; let month: Int; let sessions: [WorkSession]; let language: String
    var onSelectDay: (Date, WorkSession?) -> Void
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    var calendar: Calendar { var c = Calendar.current; c.locale = Locale(identifier: language); return c }
    var daysOfWeek: [String] { let f = DateFormatter(); f.locale = Locale(identifier: language); let symbols = f.shortStandaloneWeekdaySymbols ?? []; guard !symbols.isEmpty else { return [] }; let firstDayIndex = calendar.firstWeekday - 1; let range = firstDayIndex..<symbols.count; return Array(symbols[range] + symbols[0..<firstDayIndex]) }
    var startOfMonth: Date { let components = DateComponents(year: year, month: month, day: 1); return calendar.date(from: components) ?? Date() }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack { ForEach(daysOfWeek, id: \.self) { day in Text(day.prefix(1).uppercased()).font(.caption2).bold().foregroundStyle(.secondary).frame(maxWidth: .infinity) } }
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<startingOffset, id: \.self) { _ in Rectangle().fill(Color.clear).frame(height: 35) }
                ForEach(getDaysInMonth(date: startOfMonth), id: \.self) { dayDate in
                    let workedSession = sessions.first { calendar.isDate($0.startTime, inSameDayAs: dayDate) }; let isToday = calendar.isDateInToday(dayDate)
                    VStack(spacing: 4) {
                        ZStack {
                            if isToday { if workedSession != nil { Circle().stroke(Color.primary, lineWidth: 3).background(Circle().fill(Color.orange)) } else { Circle().fill(Color.primary) } } else { Circle().fill(workedSession != nil ? Color.orange : Color.gray.opacity(0.15)) }
                            Text(dateFormatterDayNum.string(from: dayDate)).font(.caption).bold().foregroundStyle(isToday && workedSession == nil ? Color(UIColor.systemBackground) : (workedSession != nil ? Color.black : Color.primary))
                        }.frame(width: 35, height: 35)
                        if let session = workedSession, let end = session.endTime { let diff = end.timeIntervalSince(session.startTime) / 3600; Text(String(format: "%.1fh", diff)).font(.system(size: 8)).foregroundStyle(.secondary) } else { Text(" ").font(.system(size: 8)) }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onSelectDay(dayDate, workedSession) }
                }
            }
        }.padding().background(Color(UIColor.systemGray6)).cornerRadius(16).padding(.horizontal)
    }
    var startingOffset: Int { let weekday = calendar.component(.weekday, from: startOfMonth); return (weekday - calendar.firstWeekday + 7) % 7 }
    func getDaysInMonth(date: Date) -> [Date] { guard let range = calendar.range(of: .day, in: .month, for: date) else { return [] }; return range.compactMap { d in calendar.date(byAdding: .day, value: d - 1, to: startOfMonth) } }
    private var dateFormatterDayNum: DateFormatter { let f = DateFormatter(); f.locale = Locale(identifier: language); f.dateFormat = "d"; return f }
}
