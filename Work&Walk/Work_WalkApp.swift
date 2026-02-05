import SwiftUI
import SwiftData

@main
struct Work_WalkApp: App {
    // Stockage
    @AppStorage("hasFinishedOnboarding") var hasFinishedOnboarding: Bool = false
    
    // Par défaut 2 = Mode Sombre pour l'application principale
    @AppStorage("selectedAppearance") private var selectedAppearance: Int = 2
    
    @State private var isSplashFinished = false
    
    init() {
        HealthManager.shared.startBackgroundObserver()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if hasFinishedOnboarding {
                        // --- 2. L'APPLICATION (APRÈS INTRO) ---
                        // Elle prend le thème défini (Sombre par défaut)
                        ContentView()
                            .preferredColorScheme(selectedAppearance == 1 ? .light : (selectedAppearance == 2 ? .dark : nil))
                    } else {
                        // --- 1. L'INTRODUCTION (ONBOARDING) ---
                        // 👇 ON FORCE LE MODE CLAIR ICI
                        // Cela oblige les TextFields et Pickers à rester BLANCS et nets,
                        // pour qu'ils ressortent bien sur ton fond noir manuel.
                        OnboardingView()
                            .preferredColorScheme(.light)
                    }
                }
                
                // SPLASH SCREEN
                if !isSplashFinished {
                    SplashView(isFinished: $isSplashFinished)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        }
        .modelContainer(for: WorkSession.self)
    }
}
