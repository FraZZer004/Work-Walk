import SwiftUI
import HealthKit

struct ContentView: View {
    // Le gestionnaire de santé (Assure-toi qu'il est coché pour la cible Watch !)
    @State private var healthManager = HealthManager()
    
    // Pour l'instant, on met une valeur par défaut car la synchro iPhone -> Watch
    // demande une étape technique supplémentaire (WCSession) qu'on verra après.
    @State private var workHoursDisplay = "Voir sur iPhone"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    
                    // --- 1. JAUGE DES PAS (Donnée Live de la Montre) ---
                    ZStack {
                        // Fond du cercle
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        
                        // Cercle de progression (Orange)
                        Circle()
                            .trim(from: 0, to: min(healthManager.stepsToday / 10000, 1.0))
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut, value: healthManager.stepsToday)
                        
                        // Texte au centre
                        VStack(spacing: 0) {
                            Text("\(Int(healthManager.stepsToday))")
                                .font(.system(.title2, design: .rounded).bold())
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                            Text("PAS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.orange)
                        }
                    }
                    .frame(height: 110)
                    .padding(.top, 5)
                    
                    Divider().background(Color.gray)
                    
                    // --- 2. RÉCAP TRAVAIL (Consultation uniquement) ---
                    VStack(spacing: 5) {
                        HStack {
                            Image(systemName: "briefcase.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text("TEMPS SAISI")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                        }
                        
                        // C'est ici qu'on affichera l'heure reçue de l'iPhone
                        Text(workHoursDisplay)
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                .padding()
            }
            .navigationTitle("Work&Walk")
            .onAppear {
                // On lance la récupération des pas dès l'ouverture
                healthManager.requestAuthorization()
            }
        }
    }
}

#Preview {
    ContentView()
}
