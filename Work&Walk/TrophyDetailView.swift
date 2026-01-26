import SwiftUI

struct TrophyDetailView: View {
    let category: TrophyCategory
    let trophies: [Trophy]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Titre de la page
                Text(category.rawValue)
                    .font(.title2).bold()
                    .padding(.top)
                
                // La liste verticale des niveaux
                VStack(spacing: 0) {
                    ForEach(Array(trophies.enumerated()), id: \.element.id) { index, trophy in
                        
                        HStack(spacing: 15) {
                            // 1. La Ligne de temps (Timeline)
                            VStack {
                                // Ligne du haut
                                Rectangle()
                                    // 👇 CORRECTION : On utilise category.themeColor
                                    .fill(index == 0 ? Color.clear : (trophy.isUnlocked ? category.themeColor : Color.gray.opacity(0.3)))
                                    .frame(width: 2)
                                
                                // Le point central (Cercle ou Cadenas)
                                ZStack {
                                    Circle()
                                        // 👇 CORRECTION
                                        .fill(trophy.isUnlocked ? category.themeColor : Color(UIColor.systemGray5))
                                        .frame(width: 30, height: 30)
                                    
                                    Image(systemName: trophy.isUnlocked ? "checkmark" : "lock.fill")
                                        .font(.caption2)
                                        .foregroundStyle(trophy.isUnlocked ? .white : .gray)
                                }
                                
                                // Ligne du bas
                                Rectangle()
                                    // 👇 CORRECTION (Verification du suivant)
                                    .fill(index == trophies.count - 1 ? Color.clear : (trophies[index + 1].isUnlocked ? category.themeColor : Color.gray.opacity(0.3)))
                                    .frame(width: 2)
                            }
                            .frame(width: 30) // Largeur fixe pour la colonne timeline
                            
                            // 2. La carte du niveau
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(trophy.title)
                                        .font(.headline)
                                        .foregroundStyle(trophy.isUnlocked ? .primary : .secondary)
                                    
                                    Text(trophy.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                
                                // Badge de niveau
                                if trophy.isUnlocked {
                                    Image(systemName: "trophy.fill")
                                        // 👇 CORRECTION
                                        .foregroundStyle(category.themeColor)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
                            .opacity(trophy.isUnlocked ? 1.0 : 0.6) // Grisé si pas débloqué
                        }
                        .frame(height: 80) // Hauteur fixe par ligne
                    }
                }
                .padding()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}
