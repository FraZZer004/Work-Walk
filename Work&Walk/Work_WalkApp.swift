import SwiftUI
import SwiftData

@main
struct Work_WalkApp: App {
    // Stockage
    @AppStorage("hasFinishedOnboarding") var hasFinishedOnboarding: Bool = false
    @AppStorage("selectedAppearance") private var selectedAppearance: Int = 0
    
    // État pour gérer l'affichage du Splash Screen
    @State private var showSplash = true

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
                
                // 2. LE SPLASH SCREEN (Superposé au dessus)
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity) // Disparition en fondu
                        .zIndex(1) // S'assure qu'il est bien devant
                }
            }
            // Application du thème global (Splash + App)
            .preferredColorScheme(selectedAppearance == 1 ? .light : (selectedAppearance == 2 ? .dark : nil))
            // Gestion du timing
            .onAppear {
                // On attend 2 secondes, puis on cache le splash
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
        .modelContainer(for: WorkSession.self)
    }
}
