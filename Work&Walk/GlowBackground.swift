import SwiftUI

struct GlowBackground: View {
    @State private var animate = false
    // On récupère le mode actuel (Clair ou Sombre)
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // 1. LA COULEUR DE FOND
            // Mode Sombre : Noir profond
            // Mode Clair : Blanc pur (pour que les couleurs ressortent mieux que sur du gris)
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()
            
            // 2. TACHE ORANGE PRINCIPALE (Haut Gauche)
            Circle()
                // 👇 C'est ici qu'on a boosté : 0.4 en mode clair (au lieu de 0.15)
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.5 : 0.4))
                .frame(width: 350, height: 350)
                .blur(radius: 80)
                .offset(x: animate ? -50 : -100, y: animate ? -100 : -150)
            
            // 3. TACHE ROUGE/ROSE (Bas Droite)
            Circle()
                // 👇 Boosté à 0.3 en mode clair
                .fill(Color.red.opacity(colorScheme == .dark ? 0.4 : 0.3))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: animate ? 100 : 50, y: animate ? 150 : 100)
            
            // 4. TACHE JAUNE (Milieu)
            Circle()
                // 👇 Boosté à 0.3 en mode clair (le jaune est dur à voir sur du blanc)
                .fill(Color.yellow.opacity(colorScheme == .dark ? 0.3 : 0.3))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: animate ? -30 : 30, y: animate ? 50 : -50)
        }
        .onAppear {
            // Animation lente et fluide
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

#Preview {
    // Tu peux tester le rendu ici en changeant .dark par .light
    GlowBackground()
        .preferredColorScheme(.light)
}
