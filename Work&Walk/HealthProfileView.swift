import SwiftUI

struct HealthProfileView: View {
    @Environment(\.dismiss) var dismiss
    
    // --- DONNÉES UTILISATEUR (Sauvegarde Auto) ---
    @AppStorage("userWeight") private var weight: Double = 70.0
    @AppStorage("userHeight") private var height: Double = 175.0
    @AppStorage("userAge") private var age: Int = 25
    @AppStorage("userGender") private var gender: String = "male" // "male" ou "female"
    
    // Calcul de l'IMC en temps réel
    var bmi: Double {
        let heightInMeters = height / 100
        guard heightInMeters > 0 else { return 0 }
        return weight / (heightInMeters * heightInMeters)
    }
    
    var bmiColor: Color {
        switch bmi {
        case ..<18.5: return .blue
        case 18.5..<25: return .green
        case 25..<30: return .orange
        default: return .red
        }
    }
    
    var bmiText: String {
        switch bmi {
        case ..<18.5: return "Maigreur"
        case 18.5..<25: return "Poids normal"
        case 25..<30: return "Surpoids"
        default: return "Obésité"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Fond sombre
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // 1. JAUGE IMC (Le truc stylé en haut)
                        VStack(spacing: 10) {
                            Text("VOTRE IMC ACTUEL")
                                .font(.caption).bold().foregroundStyle(.gray)
                                .tracking(2)
                            
                            HStack(alignment: .lastTextBaseline) {
                                Text(String(format: "%.1f", bmi))
                                    .font(.system(size: 60, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                
                                Text(bmiText)
                                    .font(.headline)
                                    .foregroundStyle(bmiColor)
                                    .padding(.bottom, 12)
                            }
                            
                            // Barre de progression visuelle
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.gray.opacity(0.3)).frame(height: 8)
                                    
                                    // Dégradé de couleur
                                    LinearGradient(colors: [.blue, .green, .orange, .red], startPoint: .leading, endPoint: .trailing)
                                        .mask(Capsule())
                                        .frame(height: 8)
                                    
                                    // Curseur blanc
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 20, height: 20)
                                        .shadow(color: .black.opacity(0.5), radius: 2)
                                        // 👇 C'est ici qu'on appelle la fonction simplifiée
                                        .offset(x: calculateOffset(maxWidth: geo.size.width))
                                }
                            }
                            .frame(height: 20)
                            .padding(.horizontal, 40)
                        }
                        .padding(.vertical, 30)
                        
                        // 2. SÉLECTEUR DE GENRE (Gros boutons)
                        HStack(spacing: 15) {
                            // Bouton Homme (Icône corrigée si nécessaire, mais 'figure.stand' est OK)
                            GenderButton(icon: "figure.stand", title: "Homme", isSelected: gender == "male") {
                                withAnimation { gender = "male" }
                            }
                            
                            // 👇 BOUTON FEMME CORRIGÉ : Icône 'figure.dress' utilisée ici 👇
                            GenderButton(icon: "figure.stand.dress", title: "Femme", isSelected: gender == "female") {
                                withAnimation { gender = "female" }
                            }
                        }
                        .padding(.horizontal)
                        
                        // 3. SLIDERS POIDS & TAILLE & AGE
                        VStack(spacing: 15) {
                            MetricCard(title: "Poids", value: String(format: "%.0f", weight), unit: "kg", icon: "scalemass.fill", color: .orange) {
                                Stepper("", value: $weight, in: 30...200, step: 1).labelsHidden()
                            }
                            
                            MetricCard(title: "Taille", value: String(format: "%.0f", height), unit: "cm", icon: "ruler.fill", color: .blue) {
                                Stepper("", value: $height, in: 100...250, step: 1).labelsHidden()
                            }
                            
                            MetricCard(title: "Âge", value: "\(age)", unit: "ans", icon: "calendar", color: .purple) {
                                Stepper("", value: $age, in: 10...100, step: 1).labelsHidden()
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Mon Physique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") { dismiss() }.tint(.orange)
                }
            }
        }
    }
    
    // 👇 FONCTION D'AIDE POUR CALCULER L'OFFSET (Sépare la logique complexe de la Vue)
    func calculateOffset(maxWidth: CGFloat) -> CGFloat {
        // On convertit tout en CGFloat pour le calcul
        let currentBMI = CGFloat(bmi)
        let minBMI: CGFloat = 10.0
        let rangeBMI: CGFloat = 30.0 // De 10 à 40
        
        // Calcul de la position théorique
        let ratio = (currentBMI - minBMI) / rangeBMI
        let position = ratio * maxWidth
        
        // On limite pour ne pas sortir de la barre (Clamping)
        // Le "- 20" correspond à la largeur du cercle blanc pour qu'il ne dépasse pas
        return min(max(0, position), maxWidth - 20)
    }
}

// MARK: - COMPOSANTS DESIGN (Inchangés)

struct GenderButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(isSelected ? Color.orange : Color(UIColor.systemGray6).opacity(0.1))
            .foregroundStyle(isSelected ? .black : .gray)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.orange : Color.gray.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
            .cornerRadius(20)
            .shadow(color: isSelected ? .orange.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
        }
    }
}

struct MetricCard<Content: View>: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    @ViewBuilder let stepper: () -> Content
    
    var body: some View {
        HStack {
            // Icône
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 44, height: 44)
                Image(systemName: icon).foregroundStyle(color).font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.gray).textCase(.uppercase)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value).font(.title2).bold().foregroundStyle(.white)
                    Text(unit).font(.subheadline).foregroundStyle(.gray)
                }
            }
            
            Spacer()
            
            // Le stepper natif d'Apple
            stepper()
                .scaleEffect(1.1)
        }
        .padding()
        .background(Color(UIColor.systemGray6).opacity(0.1))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

#Preview {
    HealthProfileView()
}
