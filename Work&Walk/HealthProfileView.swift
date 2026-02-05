import SwiftUI

struct HealthProfileView: View {
    // Stockage des données physiques
    @AppStorage("userWeight") private var weight: Double = 70.0
    @AppStorage("userHeight") private var height: Double = 175.0
    @AppStorage("userAge") private var age: Int = 30
    @AppStorage("userGender") private var gender: String = "Homme"
    @AppStorage("username") private var username: String = ""
    
    @AppStorage("userProfileImage") private var userProfileImageBase64: String = ""
    @State private var currentAvatar: UIImage? = nil
    
    // 👇 NOUVELLE MÉTHODE MODERNE POUR GÉRER LE CLAVIER
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    
                    // 1. HEADER
                    VStack(spacing: 15) {
                        if let avatar = currentAvatar {
                            Image(uiImage: avatar)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3))
                                .shadow(radius: 5)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 100))
                                .foregroundStyle(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(radius: 5)
                        }
                        
                        Text(username.isEmpty ? "Mon Profil" : username)
                            .font(.title).bold()
                    }
                    .padding(.top)
                    
                    // 2. FORMULAIRE
                    VStack(spacing: 0) {
                        // Sexe
                        HStack {
                            Image(systemName: "figure.stand").foregroundStyle(.purple).frame(width: 30)
                            Text("Sexe")
                            Spacer()
                            Picker("Sexe", selection: $gender) {
                                Text("Homme").tag("Homme"); Text("Femme").tag("Femme")
                            }
                            .pickerStyle(.segmented).frame(width: 150)
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        // Âge
                        HStack {
                            Image(systemName: "calendar").foregroundStyle(.blue).frame(width: 30)
                            Text("Âge")
                            Spacer()
                            Stepper("\(age) ans", value: $age, in: 16...99).bold()
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        // POIDS (Sécurisé)
                        HStack {
                            Image(systemName: "scalemass.fill").foregroundStyle(.orange).frame(width: 30)
                            Text("Poids (kg)")
                            Spacer()
                            TextField("70", value: $weight, format: .number)
                                .keyboardType(.decimalPad)
                                .focused($isInputFocused) // 👈 Connecté au focus
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                                .padding(5)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                                // 👇 SÉCURITÉ ANTI-ABERRATION
                                .onChange(of: weight) { _, newValue in
                                    if newValue > 300 { weight = 300 } // Max 300 kg
                                    if newValue < 0 { weight = 0 }     // Pas de poids négatif
                                }
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        // TAILLE (Sécurisée)
                        HStack {
                            Image(systemName: "ruler.fill").foregroundStyle(.green).frame(width: 30)
                            Text("Taille (cm)")
                            Spacer()
                            TextField("175", value: $height, format: .number)
                                .keyboardType(.numberPad)
                                .focused($isInputFocused) // 👈 Connecté au focus
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                                .padding(5)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                                // 👇 SÉCURITÉ ANTI-ABERRATION
                                .onChange(of: height) { _, newValue in
                                    if newValue > 250 { height = 250 } // Max 2m50
                                    if newValue < 0 { height = 0 }
                                }
                        }
                        .padding()
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // 3. CARTES SANTÉ
                    HStack(spacing: 15) {
                        HealthCard(
                            title: "IMC",
                            value: String(format: "%.1f", calculateIMC()),
                            subtitle: getIMCCategory(),
                            color: getIMCColor(),
                            icon: "heart.text.square.fill"
                        )
                        HealthCard(
                            title: "Métabolisme",
                            value: "\(Int(calculateBMR()))",
                            subtitle: "Kcal / jour (Repos)",
                            color: .blue,
                            icon: "flame.fill"
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Mon Profil Santé")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { loadAvatar() }
            
            // 👇 TAPPER N'IMPORTE OÙ FERME LE CLAVIER
            .onTapGesture {
                isInputFocused = false
            }
        }
    }
    
    // --- FONCTIONS ---
    
    func loadAvatar() {
        if !userProfileImageBase64.isEmpty, let data = Data(base64Encoded: userProfileImageBase64) {
            currentAvatar = UIImage(data: data)
        } else { currentAvatar = nil }
    }
    
    func calculateIMC() -> Double {
        let hM = height / 100
        if hM == 0 { return 0 }
        return weight / (hM * hM)
    }
    
    func getIMCCategory() -> String {
        let imc = calculateIMC()
        if imc < 18.5 { return "Maigreur" }
        else if imc < 25 { return "Normal" }
        else if imc < 30 { return "Surpoids" }
        else { return "Obésité" }
    }
    
    func getIMCColor() -> Color {
        let imc = calculateIMC()
        if imc < 18.5 { return .blue }
        else if imc < 25 { return .green }
        else if imc < 30 { return .orange }
        else { return .red }
    }
    
    func calculateBMR() -> Double {
        let base = (10 * weight) + (6.25 * height) - (5 * Double(age))
        return gender == "Homme" ? base + 5 : base - 161
    }
}
// À coller tout en bas du fichier, en dehors de la struct HealthProfileView

struct HealthCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
