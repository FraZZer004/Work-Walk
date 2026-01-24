import SwiftUI

struct SplashScreenView: View {
    @State private var scale = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        ZStack {
            // Fond qui s'adapte au thème
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Votre Logo
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                
                // Le Titre (Police système standard)
                Text("Work&Walk")
                    .font(.largeTitle) // La taille standard des gros titres Apple
                    .fontWeight(.bold) // En gras
                    .foregroundStyle(.primary) // Couleur standard (Noir/Blanc)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
