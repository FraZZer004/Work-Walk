import SwiftUI
import SwiftData

struct TrophiesView: View {
    @Environment(\.dismiss) var dismiss
    @Query private var sessions: [WorkSession]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    
                    // En-tête
                    VStack(spacing: 5) {
                        Image(systemName: "flag.checkered.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)
                            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Text("Prochains Objectifs")
                            // 👇 CORRECTION ICI : .design est intégré dans .font(.system(...))
                            .font(.system(.largeTitle, design: .rounded))
                            .bold()
                    }
                    .padding(.top)
                    
                    let groupedTrophies = TrophyManager.shared.checkTrophies(sessions: sessions, healthManager: nil)
                    
                    ForEach(TrophyCategory.allCases, id: \.self) { category in
                        if let trophies = groupedTrophies[category] {
                            // On prend le premier non débloqué OU le dernier si tout est fini
                            if let activeTrophy = trophies.first(where: { !$0.isUnlocked }) ?? trophies.last {
                                
                                NavigationLink(destination: TrophyDetailView(category: category, trophies: trophies)) {
                                    ActiveObjectiveCard(category: category, trophy: activeTrophy)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Succès")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Fermer") { dismiss() } }
        }
    }
}

// ✨ NOUVELLE CARTE DESIGN AVEC BARRE DE PROGRESSION ✨
struct ActiveObjectiveCard: View {
    let category: TrophyCategory
    let trophy: Trophy
    
    var body: some View {
        // Calcul du pourcentage (borné entre 0 et 1)
        // Sécurité : si threshold est 0, on évite la division par zéro
        let progressPercent = trophy.threshold > 0 ? min(max(trophy.progress / trophy.threshold, 0.0), 1.0) : 0.0
        let themeColor = category.themeColor
        
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                
                // 1. Grosse Icône colorée
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeColor.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: trophy.icon)
                        .font(.title)
                        .foregroundStyle(themeColor)
                }
                
                // 2. Textes
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.rawValue.uppercased())
                        .font(.caption2).fontWeight(.black)
                        .foregroundStyle(themeColor.opacity(0.8))
                    
                    Text(trophy.isUnlocked ? "Niveau Max Atteint !" : trophy.title)
                        // 👇 CORRECTION ICI AUSSI
                        .font(.system(.title3, design: .rounded))
                        .bold()
                        .foregroundStyle(.primary)
                    
                    // "35 / 50 heures"
                    if !trophy.isUnlocked {
                        Text("\(Int(trophy.progress)) / \(Int(trophy.threshold))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            
            // 3. LA BARRE DE PROGRESSION
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Fond de la barre
                    Rectangle()
                        .fill(themeColor.opacity(0.1))
                    
                    // Remplissage
                    Rectangle()
                        .fill(themeColor)
                        .frame(width: geo.size.width * progressPercent)
                        .animation(.easeOut(duration: 1.0), value: progressPercent)
                }
            }
            .frame(height: 6) // Hauteur de la barre
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: themeColor.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}
