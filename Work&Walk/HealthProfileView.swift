import SwiftUI

struct HealthProfileView: View {
    // --- DONNÉES UTILISATEUR ---
    @AppStorage("userWeight") private var weight: Double = 70.0
    @AppStorage("userHeight") private var height: Double = 175.0
    @AppStorage("userAge") private var age: Int = 25
    @AppStorage("userGender") private var gender: String = "male"
    
    // Calcul de l'IMC
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
            // 👇 LE ZSTACK MAGIQUE
            ZStack {
                GlowBackground()
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // 1. JAUGE IMC
                        VStack(spacing: 10) {
                            Text("VOTRE IMC ACTUEL")
                                .font(.caption).bold().foregroundStyle(.secondary)
                                .tracking(2)
                            
                            HStack(alignment: .lastTextBaseline) {
                                Text(String(format: "%.1f", bmi))
                                    .font(.system(size: 60, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.primary)
                                
                                Text(bmiText)
                                    .font(.headline)
                                    .foregroundStyle(bmiColor)
                                    .padding(.bottom, 12)
                            }
                            
                            // Barre de progression
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 8)
                                    
                                    LinearGradient(colors: [.blue, .green, .orange, .red], startPoint: .leading, endPoint: .trailing)
                                        .mask(Capsule())
                                        .frame(height: 8)
                                    
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 20, height: 20)
                                        .shadow(color: .black.opacity(0.5), radius: 2)
                                        .offset(x: calculateOffset(maxWidth: geo.size.width))
                                }
                            }
                            .frame(height: 20)
                            .padding(.horizontal, 40)
                        }
                        .padding(.vertical, 30)
                        
                        // 2. SÉLECTEUR DE GENRE
                        HStack(spacing: 15) {
                            GenderButton(icon: "figure.stand", title: "Homme", isSelected: gender == "male") {
                                withAnimation { gender = "male" }
                            }
                            GenderButton(icon: "figure.stand.dress", title: "Femme", isSelected: gender == "female") {
                                withAnimation { gender = "female" }
                            }
                        }
                        .padding(.horizontal)
                        
                        // 3. SLIDERS
                        VStack(spacing: 15) {
                            MetricCard(title: "Poids", value: String(format: "%.0f", weight), unit: "kg", icon: "scalemass.fill", color: .orange) {
                                Stepper("", value: $weight, in: 30...200, step: 1).labelsHidden()
                            }
                            
                            MetricCard(title: "Taille", value: String(format: "%.0f", height), unit: "cm", icon: "ruler.fill", color: .orange) {
                                Stepper("", value: $height, in: 100...250, step: 1).labelsHidden()
                            }
                            
                            MetricCard(title: "Âge", value: "\(age)", unit: "ans", icon: "calendar", color: .orange) {
                                Stepper("", value: $age, in: 10...100, step: 1).labelsHidden()
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.bottom, 40)
                }
                // 👇 REND LE SCROLLVIEW TRANSPARENT
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Mon Physique")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func calculateOffset(maxWidth: CGFloat) -> CGFloat {
        let currentBMI = CGFloat(bmi)
        let minBMI: CGFloat = 10.0
        let rangeBMI: CGFloat = 30.0
        let ratio = (currentBMI - minBMI) / rangeBMI
        let position = ratio * maxWidth
        return min(max(0, position), maxWidth - 20)
    }
}

// MARK: - COMPOSANTS DESIGN

struct GenderButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 30))
                Text(title).font(.headline)
            }
            .frame(maxWidth: .infinity).frame(height: 100)
            .background(isSelected ? Color.orange : Color.clear)
            .background(.ultraThinMaterial)
            .foregroundStyle(isSelected ? .black : .primary)
            .cornerRadius(20)
            // 👇 ON REMPLACE L'ANCIEN OVERLAY PAR LE GLOW
            .glowBorder(cornerRadius: 20)
            .shadow(color: isSelected ? .orange.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
        }
    }
}

struct MetricCard<Content: View>: View {
    let title: String, value: String, unit: String, icon: String
    let color: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        HStack {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 44, height: 44)
                Image(systemName: icon).foregroundStyle(color).font(.headline)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary).textCase(.uppercase)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value).font(.title2).bold().foregroundStyle(.primary)
                    Text(unit).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
            content().scaleEffect(1.1)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        // 👇 ON REMPLACE L'ANCIEN OVERLAY PAR LE GLOW
        .glowBorder(cornerRadius: 20)
    }
}

