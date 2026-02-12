import SwiftUI

struct GlowBorderModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .orange.opacity(0.6), // Commence Orange visible
                                .orange.opacity(0.3), // S'estompe un peu
                                .clear,               // Disparaît
                                .clear                // Reste invisible sur le reste
                            ],
                            startPoint: .bottomLeading, // Départ : Bas Gauche
                            endPoint: .topTrailing      // Fin : Haut Droite
                        ),
                        lineWidth: 1.5 // Finesse du trait
                    )
            )
    }
}

// Extension pour l'utiliser facilement : .glowBorder()
extension View {
    func glowBorder(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(GlowBorderModifier(cornerRadius: cornerRadius))
    }
}
