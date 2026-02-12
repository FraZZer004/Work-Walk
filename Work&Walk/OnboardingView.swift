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
            // 1. FOND "DEEP DARK"
            Color.black.ignoresSafeArea()
            
            // 2. LUEURS D'AMBIANCE
            Circle()
                .fill(Color.orange.opacity(0.4))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -350)
            
            Circle()
                .fill(Color.orange.opacity(0.3))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 100, y: 350)
            
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { isInputFocused = false }
            
            VStack {
                // BARRE DE NAVIGATION (RETOUR + PROGRESSION ALIGNÉS)
                HStack(spacing: 15) {
                    // Zone Bouton Retour
                    Group {
                        if currentStep > 0 {
                            Button(action: previousStep) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Retour")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.orange)
                            }
                        } else {
                            // Espace réservé pour maintenir l'alignement à l'étape 0
                            Text("Retour")
                                .font(.system(size: 16, weight: .medium))
                                .opacity(0)
                        }
                    }
                    .frame(width: 70, alignment: .leading)

                    // Barre de progression
                    HStack(spacing: 6) {
                        ForEach(0..<5) { step in
                            Capsule()
                                .fill(step <= currentStep ? Color.orange : Color.white.opacity(0.1))
                                .frame(height: 4)
                                .frame(maxWidth: 35)
                                .animation(.spring, value: currentStep)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 25)
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
                        .background(Color.orange)
                        .cornerRadius(20)
                        .shadow(color: .orange.opacity(0.4), radius: 15, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .onAppear { isAnimating = true }
    }
    
    // --- ÉTAPES ---
    
    var stepWelcome: some View {
        VStack(spacing: 30) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .cornerRadius(35)
                .shadow(color: .orange.opacity(0.3), radius: 30, x: 0, y: 10)
                .scaleEffect(isAnimating ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isAnimating)
            
            VStack(spacing: 20) {
                Text("Work&Walk")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Valorisez votre activité\net estimez vos gains.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white) // Texte blanc pour lisibilité
                    .padding(.horizontal)
            }
        }
    }
    
    var stepPermissions: some View {
        VStack(spacing: 25) {
            Text("Autorisations")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Pour fonctionner, l'application a besoin d'accéder à vos données de marche.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white) // Texte blanc pour lisibilité
                .padding(.horizontal)
            
            VStack(spacing: 15) {
                PermissionToggle(icon: "heart.fill", color: .red, title: "Activer Santé") {
                    // Code HealthKit
                }
                PermissionToggle(icon: "bell.fill", color: .orange, title: "Activer Notifications") {
                    NotificationManager.shared.requestAuthorization()
                }
            }
            .padding(.horizontal)
        }
    }
    
    var stepPhysical: some View {
        VStack(spacing: 25) {
            Text("Votre Profil")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            VStack(spacing: 20) {
                // POIDS
                HStack {
                    Label("Poids (kg)", systemImage: "scalemass.fill").foregroundStyle(.orange).bold()
                    Spacer()
                    TextField("70", value: $userWeight, format: .number)
                        .keyboardType(.decimalPad).focused($isInputFocused)
                        .multilineTextAlignment(.center)
                        .frame(width: 70, height: 40)
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(10)
                        .foregroundStyle(.black) // Texte noir sur fond gris clair
                        .glowBorder(cornerRadius: 10)
                }
                .padding().background(Color(UIColor.systemGray6).opacity(0.3)).cornerRadius(15)
                
                // TAILLE
                HStack {
                    Label("Taille (cm)", systemImage: "ruler.fill").foregroundStyle(.orange).bold()
                    Spacer()
                    TextField("175", value: $userHeight, format: .number)
                        .keyboardType(.numberPad).focused($isInputFocused)
                        .multilineTextAlignment(.center)
                        .frame(width: 70, height: 40)
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(10)
                        .foregroundStyle(.black) // Texte noir sur fond gris clair
                        .glowBorder(cornerRadius: 10)
                }
                .padding().background(Color(UIColor.systemGray6).opacity(0.3)).cornerRadius(15)
                
                Picker("Sexe", selection: $userGender) {
                    Text("Homme").tag("Homme")
                    Text("Femme").tag("Femme")
                }
                .pickerStyle(.segmented)
                .padding(5)
                .background(Color(UIColor.systemGray6).opacity(0.5))
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
    
    var stepFinance: some View {
        VStack(spacing: 25) {
            Text("Dernière étape")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Votre Prénom").font(.caption).foregroundStyle(.gray).padding(.leading, 5)
                TextField("Ex: Alan", text: $username)
                    .font(.title2.bold())
                    .padding()
                    .background(Color(UIColor.systemGray6).opacity(0.5))
                    .cornerRadius(15)
                    .foregroundStyle(.white)
                    .focused($isInputFocused)
                    .glowBorder(cornerRadius: 15)
            }
            .padding(.horizontal)
            
            VStack(spacing: 15) {
                Text("Votre taux horaire brut ?").font(.headline).foregroundStyle(.white)
                HStack {
                    Text("€").font(.title2).bold().foregroundStyle(.orange)
                    TextField("11.91", value: $hourlyRate, format: .number)
                        .keyboardType(.decimalPad).font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundStyle(.white).multilineTextAlignment(.center).focused($isInputFocused)
                    Text("/h").font(.title2).bold().foregroundStyle(.orange)
                }
            }
            .padding().frame(maxWidth: .infinity).background(Color(UIColor.systemGray6).opacity(0.3)).cornerRadius(20).padding(.horizontal)
        }
    }
    
    var stepFinal: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle().fill(Color.orange).frame(width: 140, height: 140).shadow(color: .orange.opacity(0.5), radius: 20)
                Image(systemName: "checkmark").font(.system(size: 60, weight: .black)).foregroundStyle(.white)
            }
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .animation(.spring(bounce: 0.5).repeatForever(), value: isAnimating)
            
            Text("Tout est prêt !")
                .font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundStyle(.white)
        }
    }
    
    // LOGIQUE NAVIGATION
    func nextStep() {
        let generator = UIImpactFeedbackGenerator(style: .medium); generator.impactOccurred()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if currentStep < 4 { currentStep += 1; isInputFocused = false } else { hasFinishedOnboarding = true }
        }
    }
    
    func previousStep() {
        let generator = UIImpactFeedbackGenerator(style: .light); generator.impactOccurred()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if currentStep > 0 { currentStep -= 1; isInputFocused = false }
        }
    }
}

// Composant pour les autorisations
struct PermissionToggle: View {
    let icon: String; let color: Color; let title: String; let action: () -> Void
    @State private var isDone = false
    
    var body: some View {
        Button(action: { isDone = true; action() }) {
            HStack {
                Image(systemName: icon).foregroundStyle(color).frame(width: 30)
                Text(title).foregroundStyle(.white)
                Spacer()
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle").foregroundStyle(isDone ? .green : .gray)
            }
            .padding().background(Color(UIColor.systemGray6).opacity(0.3)).cornerRadius(15)
        }
    }
}
