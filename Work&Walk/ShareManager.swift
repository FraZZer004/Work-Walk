import SwiftUI

// 1. LA FORME "PAPIER DÉCHIRÉ" 🧾
struct TicketShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Haut, Droite
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        
        // Le bas en Zig-Zag (dents de scie)
        let teethCount = 20
        let toothWidth = rect.width / CGFloat(teethCount)
        let toothHeight: CGFloat = 10
        
        for i in 0..<teethCount {
            let x = rect.width - (CGFloat(i) * toothWidth)
            path.addLine(to: CGPoint(x: x - (toothWidth / 2), y: rect.height - toothHeight))
            path.addLine(to: CGPoint(x: x - toothWidth, y: rect.height))
        }
        
        // Remonter à gauche
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}

// 2. LA VUE DU TICKET (Ce qui sera exporté en image)
struct DailyReceiptView: View {
    // Données à afficher
    let date: Date
    let steps: Int
    let hours: String
    let salary: Double
    let calories: Int
    
    var body: some View {
        VStack(spacing: 20) {
            
            // --- EN-TÊTE ---
            VStack(spacing: 5) {
                Image(systemName: "figure.walk.circle.fill") // Ou ton Logo "AppLogo"
                    .font(.system(size: 40))
                    .foregroundStyle(.black)
                
                Text("WORK & WALK")
                    .font(.system(.headline, design: .monospaced))
                    .fontWeight(.bold)
                    .tracking(2)
                
                Text("REÇU OFFICIEL")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                
                Text(date.formatted(date: .numeric, time: .omitted))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)
            
            Divider().background(Color.black)
            
            // --- LISTE DES COURSES ---
            VStack(spacing: 12) {
                ReceiptRow(label: "TEMPS TRAVAIL", value: hours)
                ReceiptRow(label: "SALAIRE EST.", value: String(format: "%.2f €", salary))
                ReceiptRow(label: "PAS EFFECTUÉS", value: "\(steps)")
                ReceiptRow(label: "CALORIES", value: "\(calories) kcal")
            }
            
            Divider().background(Color.black)
            
            // --- TOTAL ---
            HStack {
                Text("TOTAL GAIN")
                    .font(.system(.headline, design: .monospaced))
                    .fontWeight(.black)
                Spacer()
                Text("DOUBLE !")
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.black)
            }
            
            Text("(Argent + Santé)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            // --- PIED DE PAGE (Code Barre Faux) ---
            VStack(spacing: 5) {
                Text("Merci de votre visite")
                    .font(.system(.caption, design: .monospaced))
                    .italic()
                
                // Générateur de faux code-barre
                HStack(spacing: 2) {
                    ForEach(0..<40, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: CGFloat.random(in: 1...3), height: 30)
                    }
                }
                .padding(.top, 10)
                
                Text("www.workandwalk.app")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 40) // Espace pour les dents de scie
        }
        .padding(.horizontal, 25)
        .background(Color(red: 0.98, green: 0.97, blue: 0.95)) // Couleur papier blanc cassé
        .clipShape(TicketShape()) // La découpe magique
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .frame(width: 320) // Largeur fixe pour l'export Instagram (taille Story idéale)
    }
}

// Ligne du ticket
struct ReceiptRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            // Les petits points "......"
            Text(String(repeating: ".", count: 20))
                .lineLimit(1)
                .foregroundStyle(.secondary.opacity(0.5))
            Spacer()
            Text(value).fontWeight(.bold)
        }
        .font(.system(.caption, design: .monospaced))
        .foregroundStyle(.black)
    }
}

// 3. LA VUE DE PARTAGE (Fiche qui s'ouvre)
struct ShareReceiptSheet: View {
    @Environment(\.dismiss) var dismiss
    
    // Données reçues du Dashboard
    let steps: Int
    let hours: String
    let salary: Double
    let calories: Int
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Prévisualisation
                Text("Aperçu de votre Story")
                    .font(.caption).textCase(.uppercase).foregroundStyle(.secondary)
                
                // On affiche le ticket
                let receipt = DailyReceiptView(
                    date: Date(),
                    steps: steps,
                    hours: hours,
                    salary: salary,
                    calories: calories
                )
                
                receipt // Affiche le ticket à l'écran
                
                Spacer()
                
                // BOUTON DE PARTAGE MAGIQUE
                // ShareLink génère l'image automatiquement à partir de la vue 'receipt'
                ShareLink(
                    item: renderImage(view: receipt),
                    preview: SharePreview("Mon Ticket Work&Walk", image: renderImage(view: receipt))
                ) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Partager sur Instagram / Snap")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(30)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Partager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.gray)
                    }
                }
            }
        }
    }
    
    // Fonction technique pour transformer la Vue SwiftUI en Image partageable
    @MainActor
    func renderImage(view: DailyReceiptView) -> Image {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0 // Haute qualité
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "photo")
    }
}
