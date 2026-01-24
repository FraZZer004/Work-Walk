import SwiftUI
import SwiftData

struct AddSessionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    // Si cette variable contient quelque chose, on est en mode "Modification"
    var sessionToEdit: WorkSession?
    
    // On utilise @State, mais on va les initialiser intelligemment dans le init()
    @State private var startTime: Date
    @State private var endTime: Date
    
    // --- C'EST ICI QUE LA MAGIE OPÈRE ---
    init(sessionToEdit: WorkSession?) {
        self.sessionToEdit = sessionToEdit
        
        if let session = sessionToEdit {
            // MODE MODIFICATION : On reprend les valeurs existantes
            _startTime = State(initialValue: session.startTime)
            // Si pas de fin (en cours), on met l'heure actuelle pour l'affichage
            _endTime = State(initialValue: session.endTime ?? Date())
        } else {
            // MODE CRÉATION : On règle les minutes à 00
            let now = Date()
            let calendar = Calendar.current
            
            // 1. On prend l'heure actuelle, mais on force les minutes à 0
            // Ex: s'il est 16h43, ça devient 16h00
            let start = calendar.date(bySetting: .minute, value: 0, of: now) ?? now
            
            // 2. Pour l'heure de fin, on met intelligemment 1h de plus par défaut
            // Ex: 17h00 (plutôt que d'avoir 16h00 - 16h00)
            let end = calendar.date(byAdding: .hour, value: 1, to: start) ?? start
            
            _startTime = State(initialValue: start)
            _endTime = State(initialValue: end)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Horaires")) {
                    // On garde ton design simple et efficace
                    DatePicker("Début", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Fin", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section {
                    HStack {
                        Text("Durée totale")
                        Spacer()
                        // On vérifie que la fin n'est pas avant le début pour l'affichage
                        if endTime > startTime {
                            Text(formatDuration(start: startTime, end: endTime))
                                .foregroundStyle(.orange) // Petit style orange
                                .bold()
                        } else {
                            Text("Heures invalides")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle(sessionToEdit != nil ? "Modifier" : "Ajouter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveSession()
                    }
                    // Petite sécurité : on désactive si l'heure de fin est avant le début
                    .disabled(endTime < startTime)
                }
            }
        }
    }
    
    func saveSession() {
        if let session = sessionToEdit {
            // --- MODE MODIFICATION ---
            session.startTime = startTime
            session.endTime = endTime
        } else {
            // --- MODE CRÉATION ---
            let newSession = WorkSession(startTime: startTime, endTime: endTime)
            modelContext.insert(newSession)
        }
        dismiss()
    }
    
    func formatDuration(start: Date, end: Date) -> String {
        let diff = end.timeIntervalSince(start)
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        return "\(hours)h \(minutes < 10 ? "0" : "")\(minutes)"
    }
}
