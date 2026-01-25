import SwiftUI
import SwiftData

@main
struct Work_WalkApp: App {
    // Stockage
    @AppStorage("hasFinishedOnboarding") var hasFinishedOnboarding: Bool = false
    @AppStorage("selectedAppearance") private var selectedAppearance: Int = 0
    
    // 👇 CHANGEMENT DE LOGIQUE :
    // On utilise une variable "isSplashFinished" initialisée à 'false'.
    // Quand l'animation Zoom sera terminée, elle passera à 'true'.
    @State private var isSplashFinished = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                // 1. L'APPLICATION (Cachée en dessous au début)
                Group {
                    if hasFinishedOnboarding {
                        ContentView()
                    } else {
                        OnboardingView()
                    }
                }
                
                // 2. LE NOUVEAU SPLASH SCREEN
                // On l'affiche tant que l'animation n'est PAS finie (!isSplashFinished)
                if !isSplashFinished {
                    // On appelle la vue SplashView qu'on vient de créer
                    // On lui passe la liaison ($) pour qu'elle puisse dire "C'est fini !"
                    SplashView(isFinished: $isSplashFinished)
                        .transition(.opacity) // Disparition douce
                        .zIndex(1) // Toujours au premier plan
                }
            }
            // Application du thème global
            .preferredColorScheme(selectedAppearance == 1 ? .light : (selectedAppearance == 2 ? .dark : nil))
            
            // ⚠️ NOTE : J'ai supprimé le bloc .onAppear ici.
            // C'est maintenant le fichier SplashView.swift qui gère le timing (0.8s) et l'animation.
        }
        .modelContainer(for: WorkSession.self)
    }
}
