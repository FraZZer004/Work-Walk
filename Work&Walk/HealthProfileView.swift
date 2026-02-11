import SwiftUI

struct HealthProfileView: View {
    // --- STOCKAGE (On garde tes clés exactes) ---
    @AppStorage("userWeight") private var weight: Double = 70.0
    @AppStorage("userHeight") private var height: Double = 175.0
    @AppStorage("userAge") private var age: Int = 30
    @AppStorage("userGender") private var gender: String = "Homme"
    @AppStorage("username") private var username: String = ""
    @AppStorage("userProfileImage") private var userProfileImageBase64: String = ""
    
    @State private var currentAvatar: UIImage? = nil
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: SECTION 1 - HEADER & IDENTITÉ
                Section {
                    HStack(spacing: 20) {
                        // Avatar (Sobre)
                        ZStack {
                            if let avatar = currentAvatar {
                                Image(uiImage: avatar)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .foregroundStyle(.gray.opacity(0.5))
                                    .frame(width: 70, height: 70)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            TextField("Votre Nom", text: $username)
                                .font(.headline)
                            
                            Text("Profil Personnel")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                    
                    // Sélecteur de Genre (Style Segmented propre)
                    Picker("Sexe", selection: $gender) {
                        Text("Homme").tag("Homme")
                        Text("Femme").tag("Femme")
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear) // Pour le fondre dans la section
                    .padding(.vertical, 2)
                } header: {
                    Text("Identité")
                }
                
                // MARK: SECTION 2 - MENSURATIONS
                Section {
                    // ÂGE
                    HStack {
                        Label("Âge", systemImage: "calendar")
                        Spacer()
                        Stepper("\(age) ans", value: $age, in: 10...99)
                            .fixedSize()
                    }
                    
                    // TAILLE
                    HStack {
                        Label("Taille", systemImage: "ruler")
                        Spacer()
                        TextField("175", value: $height, format: .number)
                            .keyboardType(.numberPad)
                            .focused($isInputFocused)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("cm").foregroundStyle(.secondary)
                    }
                    
                    // POIDS
                    HStack {
                        Label("Poids", systemImage: "scalemass")
                        Spacer()
                        TextField("70", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($isInputFocused)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kg").foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Données Physiques")
                } footer: {
                    Text("Ces données servent à calculer vos calories brûlées avec précision.")
                }
                
                // MARK: SECTION 3 - ANALYSE (La Jauge IMC)
                Section {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("IMC Actuel")
                                .font(.headline)
                            Spacer()
                            // Valeur colorée mais texte sobre
                            Text(String(format: "%.1f", calculateIMC()))
                                .font(.title3.bold())
                                .foregroundStyle(getIMCColor())
                            
                            Text("(\(getIMCCategory()))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        // La fameuse Jauge
                        IMCGaugeView(value: calculateIMC())
                            .frame(height: 12)
                        
                        Divider()
                        
                        // Métabolisme (BMR) simple ligne
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Métabolisme de base")
                                    .font(.body)
                                Text("Calories brûlées au repos complet")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(Int(calculateBMR())) kcal")
                                .font(.headline)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.vertical, 5)
                } header: {
                    Text("Santé")
                }
            }
            .navigationTitle("Mon Profil")
            .listStyle(.insetGrouped) // Le secret du look "Apple Réglages"
            .onAppear { loadAvatar() }
            // Toolbar Clavier
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fermer") { isInputFocused = false }
                }
            }
        }
    }
    
    // --- LOGIQUE MÉTIER ---
    
    func loadAvatar() {
        if !userProfileImageBase64.isEmpty, let data = Data(base64Encoded: userProfileImageBase64) {
            currentAvatar = UIImage(data: data)
        }
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

// MARK: - JAUGE IMC (Clean)
struct IMCGaugeView: View {
    var value: Double
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Fond dégradé subtil avec coins très arrondis
                HStack(spacing: 0) {
                    Color.blue.opacity(0.8).frame(width: geo.size.width * 0.18)
                    Color.green.opacity(0.8).frame(width: geo.size.width * 0.27)
                    Color.orange.opacity(0.8).frame(width: geo.size.width * 0.25)
                    Color.red.opacity(0.8)
                }
                .cornerRadius(6)
                
                // Curseur propre (Pastille blanche avec ombre)
                Circle()
                    .fill(.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    .offset(x: calculateOffset(width: geo.size.width) - 12)
            }
        }
    }
    
    func calculateOffset(width: Double) -> Double {
        let minIMC: Double = 15
        let maxIMC: Double = 40
        let percentage = (value - minIMC) / (maxIMC - minIMC)
        let safePercentage = min(max(percentage, 0), 1)
        return width * safePercentage
    }
}
