import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 0.0
    @State private var scale: Double = 0.9
    @Binding var isFinished: Bool
    
    var body: some View {
        ZStack {
            // 1. FOND : Dégradé Orange
            LinearGradient(
                colors: [Color.orange, Color(red: 1.0, green: 0.7, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 2. MOTIF D'ARRIÈRE-PLAN (Pattern)
            // On disperse des icônes pour combler le vide
            ZStack {
                // Haut Gauche : Valise
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.1)) // Très discret
                    .rotationEffect(.degrees(-15))
                    .offset(x: -120, y: -250)
                
                // Haut Droite : Cœur
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.1))
                    .rotationEffect(.degrees(10))
                    .offset(x: 130, y: -200)
                
                // Bas Gauche : Chronomètre
                Image(systemName: "timer")
                    .font(.system(size: 70))
                    .foregroundStyle(.white.opacity(0.1))
                    .rotationEffect(.degrees(-10))
                    .offset(x: -130, y: 200)
                
                // Bas Droite : Pas
                Image(systemName: "shoeprints.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.1))
                    .rotationEffect(.degrees(-20))
                    .offset(x: 120, y: 300)
                
                // Milieu Gauche : Flamme (Calories)
                Image(systemName: "flame.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white.opacity(0.08))
                    .offset(x: -160, y: 0)
                
                // Milieu Droite : Carte
                Image(systemName: "map.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white.opacity(0.08))
                    .offset(x: 160, y: 50)
            }
            // Le motif disparaitra en même temps que le reste à la fin
            .opacity(opacity)
            
            // 3. LE CONTENU PRINCIPAL (Logo + Texte)
            VStack(spacing: 25) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 0)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 4)
                
                Text("Work&Walk")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 4)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // --- SÉQUENCE D'ANIMATION ---
            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 1.0
                scale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scale = 0.9
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeIn(duration: 0.6)) {
                        scale = 50
                        opacity = 0
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation {
                        isFinished = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView(isFinished: .constant(false))
}
