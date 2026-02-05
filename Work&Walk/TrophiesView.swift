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

// ✨ STYLE JAUGE TUBULAIRE AVEC EURO ✨
struct ActiveObjectiveCard: View {
    let category: TrophyCategory
    let trophy: Trophy
    
    var body: some View {
        let themeColor = category.themeColor
        let progressPercent = trophy.threshold > 0 ? min(max(trophy.progress / trophy.threshold, 0.0), 1.0) : 0.0
        
        VStack(spacing: 12) {
            // En-tête texte
            HStack {
                Image(systemName: trophy.icon)
                    .foregroundStyle(themeColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(category.rawValue)
                        .font(.caption).foregroundStyle(.secondary)
                    Text(trophy.title)
                        .font(.headline).bold()
                }
                Spacer()
                
                // Pourcentage texte
                Text("\(Int(progressPercent * 100))%")
                    .font(.title3).fontWeight(.black)
                    .foregroundStyle(themeColor)
            }
            .padding(.horizontal, 5)
            
            // La Grosse Jauge
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Fond
                    Capsule()
                        .fill(Color(UIColor.secondarySystemBackground))
                    
                    // Remplissage
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [themeColor.opacity(0.7), themeColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * progressPercent, 20)) // Minimum 20px pour voir la couleur
                    
                    // Texte à l'intérieur de la barre (valeurs)
                    HStack {
                        // 👇 AFFICHAGE INTELLIGENT (€ ou standard)
                        if category == .money {
                            Text("\(Int(trophy.progress))€ / \(Int(trophy.threshold))€")
                                .font(.caption).bold()
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                                .padding(.leading, 10)
                        } else {
                            Text("\(Int(trophy.progress)) / \(Int(trophy.threshold))")
                                .font(.caption).bold()
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                                .padding(.leading, 10)
                        }
                        Spacer()
                    }
                }
            }
            .frame(height: 30) // Grosse barre épaisse
            .clipShape(Capsule())
            .shadow(color: themeColor.opacity(0.2), radius: 5, x: 0, y: 3)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}
