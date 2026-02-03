import SwiftUI
import SwiftData

@main
struct Work_WalkApp: App {
    // Stockage
    @AppStorage("hasFinishedOnboarding") var hasFinishedOnboarding: Bool = false
    @AppStorage("selectedAppearance") private var selectedAppearance: Int = 0
    
    // Logique du Splash Screen
    @State private var isSplashFinished = false
    
    // 👇 ÉTAPE 3 : ON AJOUTE L'INITIALISATION ICI
    // Le init() est appelé dès que l'application se lance en mémoire.
    // C'est le moment parfait pour dire à HealthKit de nous surveiller.
    init() {
        HealthManager.shared.startBackgroundObserver()
        print("🚀 Application lancée : Observateur HealthKit démarré")
    }

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
                
                // 2. LE SPLASH SCREEN
                // On l'affiche tant que l'animation n'est PAS finie
                if !isSplashFinished {
                    SplashView(isFinished: $isSplashFinished)
                        .transition(.opacity) // Disparition douce
                        .zIndex(1) // Toujours au premier plan
                }
            }
            // Application du thème global
            .preferredColorScheme(selectedAppearance == 1 ? .light : (selectedAppearance == 2 ? .dark : nil))
        }
        .modelContainer(for: WorkSession.self)
    }
}
