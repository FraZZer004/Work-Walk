import SwiftUI
import UserNotifications

struct OnboardingView: View {
    // État de fin
    @AppStorage("hasFinishedOnboarding") var hasFinishedOnboarding: Bool = false
    
    // Données à collecter
    @AppStorage("username") private var username: String = ""
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    
    // Physique
    @AppStorage("userWeight") private var userWeight: Double = 70.0
    @AppStorage("userHeight") private var userHeight: Double = 175.0
    @AppStorage("userGender") private var userGender: String = "Homme"
    @AppStorage("userAge") private var userAge: Int = 30
    
    // Finance
    @AppStorage("hourlyRate") private var hourlyRate: Double = 11.91
    
    // Gestion des étapes
    @State private var currentStep = 0
    @State private var isAnimating = false
    
    // Focus clavier
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            // 👇 1. FOND "DEEP DARK" PREMIUM
            Color.black.ignoresSafeArea()
            
            // 👇 2. LUEURS D'AMBIANCE (Glow Effects)
            // Une lueur orange en haut à gauche
            Circle()
                .fill(Color.orange.opacity(0.4))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -350)
            
            // Une lueur orange en bas à droite
            Circle()
                .fill(Color.orange.opacity(0.3))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 100, y: 350)
            
            // (Permet de fermer le clavier en tapant dans le vide)
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { isInputFocused = false }
            
            VStack {
                // BARRE DE PROGRESSION
                HStack(spacing: 8) {
                    ForEach(0..<5) { step in
                        Capsule()
                            .fill(step <= currentStep ? Color.orange : Color.white.opacity(0.2)) // Orange pour l'actif
                            .frame(height: 6)
                            .frame(maxWidth: .infinity)
                            .animation(.spring, value: currentStep)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 60)
                
                Spacer()
                
                // CONTENU PRINCIPAL
                Group {
                    if currentStep == 0 { stepWelcome }
                    else if currentStep == 1 { stepPermissions }
                    else if currentStep == 2 { stepPhysical }
                    else if currentStep == 3 { stepFinance }
                    else { stepFinal }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                
                Spacer()
                
                // BOUTON SUIVANT
                Button(action: nextStep) {
                    Text(currentStep == 4 ? "Commencer l'aventure" : "Continuer")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange) // Bouton Orange vif sur fond noir
                        .cornerRadius(20)
                        .shadow(color: .orange.opacity(0.5), radius: 15, x: 0, y: 5) // Ombre orange (Glow)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .onAppear { isAnimating = true }
    }
    
    // --- ÉTAPES ---
    
    // 1. BIENVENUE
    var stepWelcome: some View {
        VStack(spacing: 30) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .cornerRadius(35)
                .shadow(color: .orange.opacity(0.3), radius: 30, x: 0, y: 10) // Glow derrière le logo
                .scaleEffect(isAnimating ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isAnimating)
            
            VStack(spacing: 20) {
                Text("Work&Walk")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Valorisez votre activité\net estimez vos gains.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(UIColor.systemGray4)) // Gris clair pour le sous-titre (très lisible)
                    .padding(.horizontal)
            }
        }
    }
    
    // 2. PERMISSIONS
    var stepPermissions: some View {
        VStack(spacing: 25) {
            Text("Autorisations")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Pour fonctionner, l'application a besoin d'accéder à vos données de marche et de vous envoyer des rappels.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(UIColor.systemGray4))
                .padding(.horizontal)
            
            VStack(spacing: 15) {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium); generator.impactOccurred()
                }) {
                    HStack {
                        Image(systemName: "heart.fill").foregroundStyle(.red)
                        Text("Activer Santé (Podomètre)").foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                    .padding().background(Color(UIColor.systemGray6).opacity(0.3)).cornerRadius(15)
                }
                
                Button(action: {
                    NotificationManager.shared.requestAuthorization()
                    let generator = UIImpactFeedbackGenerator(style: .medium); generator.impactOccurred()
                }) {
                    HStack {
                        Image(systemName: "bell.fill").foregroundStyle(.orange)
                        Text("Activer Notifications").foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                    .padding().background(Color(UIColor.systemGray6).opacity(0.3)).cornerRadius(15)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // 3. PROFIL PHYSIQUE
    var stepPhysical: some View {
        VStack(spacing: 20) {
            Text("Votre Profil")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Ces infos permettent de calculer précisément vos calories brûlées.")
                .font(.subheadline).multilineTextAlignment(.center).foregroundStyle(Color(UIColor.systemGray4))
            
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "scalemass.fill").foregroundStyle(.orange)
                    Text("Poids (kg)").foregroundStyle(.white).bold()
                    Spacer()
                    TextField("70", value: $userWeight, format: .number)
                        .keyboardType(.decimalPad).focused($isInputFocused).multilineTextAlignment(.center)
                        .frame(width: 80, height: 40).background(Color.white).cornerRadius(10).foregroundStyle(.black)
                }
                .padding().background(Color(UIColor.systemGray6).opacity(0.3)).cornerRadius(15)
                
                HStack {
                    Image(systemName: "ruler.fill").foregroundStyle(.blue)
                    Text("Taille (cm)").foregroundStyle(.white).bold()
                    Spacer()
                    TextField("175", value: $userHeight, format: .number)
                        .keyboardType(.numberPad).focused($isInputFocused).multilineTextAlignment(.center)
                        .frame(width: 80, height: 40).background(Color.white).cornerRadius(10).foregroundStyle(.black)
                }
                .padding().background(Color(UIColor.systemGray6).opacity(0.3)).cornerRadius(15)
                
                Picker("Sexe", selection: $userGender) {
                    Text("Homme").tag("Homme"); Text("Femme").tag("Femme")
                }
                .pickerStyle(.segmented).padding().background(Color.white).cornerRadius(15)
            }
            .padding(.horizontal)
        }
    }
    
    // 4. FINANCE & IDENTITÉ
    var stepFinance: some View {
        VStack(spacing: 25) {
            Text("Dernière étape")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            VStack(alignment: .leading) {
                Text("Votre Prénom").font(.caption).foregroundStyle(.gray)
                TextField("Ex: Alan", text: $username)
                    .font(.title2.bold()).foregroundStyle(.black).padding().background(Color.white).cornerRadius(15).focused($isInputFocused)
            }
            .padding(.horizontal)
            
            VStack(spacing: 10) {
                Text("Votre taux horaire brut ?").font(.headline).foregroundStyle(.white)
                HStack {
                    Text("€").font(.title2).bold().foregroundStyle(.orange)
                    TextField("11.91", value: $hourlyRate, format: .number)
                        .keyboardType(.decimalPad).font(.system(size: 50, weight: .bold, design: .rounded)).foregroundStyle(.white).multilineTextAlignment(.center).focused($isInputFocused)
                    Text("/h").font(.title2).bold().foregroundStyle(.orange)
                }
            }
            .padding().frame(maxWidth: .infinity).background(Color(UIColor.systemGray6).opacity(0.3)).cornerRadius(20).padding(.horizontal)
        }
    }
    
    // 5. FIN
    var stepFinal: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle().fill(Color.orange).frame(width: 150, height: 150)
                    .shadow(color: .orange.opacity(0.5), radius: 20)
                Image(systemName: "checkmark").font(.system(size: 70, weight: .black)).foregroundStyle(.white)
            }
            .scaleEffect(isAnimating ? 1.1 : 1.0).animation(.spring(bounce: 0.5).repeatForever(autoreverses: true), value: isAnimating)
            
            VStack(spacing: 15) {
                Text("Tout est prêt !")
                    .font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                Text("Marchez, travaillez, et suivez votre progression.")
                    .font(.title3).multilineTextAlignment(.center).foregroundStyle(Color(UIColor.systemGray4))
            }
        }
    }
    
    // LOGIQUE NAVIGATION
    func nextStep() {
        let generator = UIImpactFeedbackGenerator(style: .medium); generator.impactOccurred()
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            if currentStep < 4 { currentStep += 1; isInputFocused = false } else { hasFinishedOnboarding = true }
        }
    }
}
