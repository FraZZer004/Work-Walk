import SwiftUI

struct OnboardingView: View {
    // Ce paramètre enregistre si l'onboarding est fini
    @AppStorage("hasFinishedOnboarding") var hasFinishedOnboarding: Bool = false
    
    // Les infos à collecter
    @AppStorage("username") private var username: String = ""
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    
    // État local pour gérer les étapes (0 = Bienvenue, 1 = Langue, 2 = Nom)
    @State private var currentStep = 0
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Fond dégradé subtil
            LinearGradient(colors: [.orange.opacity(0.8), .orange.opacity(0.3), .white], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // --- CONTENU CHANGEANT SELON L'ÉTAPE ---
                Group {
                    if currentStep == 0 {
                        welcomeStep
                    } else if currentStep == 1 {
                        languageStep
                    } else {
                        nameStep
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
                
                Spacer()
                
                // --- BOUTON SUIVANT ---
                Button(action: nextStep) {
                    Text(currentStep == 2 ? "C'est parti !" : "Continuer")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black) // Noir pour le contraste style "Pro"
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                .disabled(currentStep == 2 && username.isEmpty) // Bloque si pas de nom
                .opacity(currentStep == 2 && username.isEmpty ? 0.5 : 1)
            }
        }
        .onAppear { isAnimating = true }
    }
    
    // ÉTAPE 1 : BIENVENUE
    var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.white)
                .shadow(radius: 10)
                .scaleEffect(isAnimating ? 1 : 0.8)
                .animation(.bouncy(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            
            Text("Bienvenue sur\nWork&Walk")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            
            Text("L'application qui réconcilie votre santé et votre vie professionnelle.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundStyle(.secondary)
        }
    }
    
    // ÉTAPE 2 : LANGUE
    var languageStep: some View {
        VStack(spacing: 30) {
            Text("Quelle langue parlez-vous ?")
                .font(.title2)
                .bold()
            
            HStack(spacing: 20) {
                LanguageButton(lang: "fr", label: "Français", selected: $selectedLanguage)
                LanguageButton(lang: "en", label: "English", selected: $selectedLanguage)
            }
        }
    }
    
    // ÉTAPE 3 : PRÉNOM
    var nameStep: some View {
        VStack(spacing: 30) {
            Text("Comment doit-on vous appeler ?")
                .font(.title2)
                .bold()
            
            TextField("Votre Prénom", text: $username)
                .font(.system(size: 30, weight: .bold))
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.white.opacity(0.5))
                .cornerRadius(15)
                .padding(.horizontal, 40)
                .submitLabel(.done)
        }
    }
    
    // LOGIQUE DE NAVIGATION
    func nextStep() {
        withAnimation {
            if currentStep < 2 {
                currentStep += 1
            } else {
                // Fin de l'intro : on enregistre et on ferme
                hasFinishedOnboarding = true
            }
        }
    }
}

// Petit bouton pour les langues
struct LanguageButton: View {
    let lang: String
    let label: String
    @Binding var selected: String
    
    var body: some View {
        Button(action: { selected = lang }) {
            VStack {
                Text(label).font(.caption).bold()
            }
            .frame(width: 100, height: 100)
            .background(selected == lang ? Color.white : Color.white.opacity(0.3))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(selected == lang ? Color.black : Color.clear, lineWidth: 3)
            )
            .foregroundColor(.black)
            .scaleEffect(selected == lang ? 1.1 : 1.0)
            .animation(.spring, value: selected)
        }
    }
}
