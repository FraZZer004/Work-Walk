import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @ObservedObject var premiumManager = PremiumManager.shared
    
    // --- CONNEXION AU MOTEUR DE PAIEMENT ---
    @StateObject var storeManager = StoreManager.shared
    
    // --- ÉTATS ---
    @State private var selectedPlan: String = "annual"
    @State private var showRestoreAlert = false
    @State private var showPrivacyPolicy = false
    @State private var restoreMessage = ""
    
    // --- LIENS LÉGAUX ---
    let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    
    var body: some View {
        ZStack {
            // 1. FOND ADAPTATIF (GlowBackground)
            GlowBackground()
            
            VStack(spacing: 0) {
                // BOUTON FERMER
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary) // S'adapte au mode clair/sombre
                            .padding()
                    }
                }
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // 1. HEADER
                        VStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 10)
                                
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 55))
                                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                                    .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
                            }
                            
                            VStack(spacing: 5) {
                                Text("Work&Walk PRO")
                                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.primary) // Noir jour / Blanc nuit
                                
                                Text("Passez au niveau supérieur.")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 10)
                        
                        // 2. LISTE DES AVANTAGES (Bloc Verre + Glow)
                        VStack(spacing: 24) {
                            DetailedFeatureRow(icon: "clock.arrow.circlepath", color: .blue, title: "Historique Illimité", subtitle: "Remontez le temps sans limite de 2 semaines.")
                            DetailedFeatureRow(icon: "doc.text.fill", color: .orange, title: "Export PDF Certifié", subtitle: "Générez des fiches de paie pour vos dossiers.")
                            DetailedFeatureRow(icon: "heart.text.square.fill", color: .pink, title: "Santé Avancée", subtitle: "Analysez votre distance, cardio et étages.")
                            DetailedFeatureRow(icon: "star.fill", color: .yellow, title: "Soutenez le Développeur", subtitle: "Aidez à maintenir et améliorer l'application.")
                        }
                        .padding(25)
                        // ✨ DESIGN GLOW & GLASS ✨
                        .background(
                            {
                                if #available(iOS 15.0, macOS 12.0, *) {
                                    return AnyShapeStyle(.ultraThinMaterial)
                                } else {
                                    return AnyShapeStyle(Color(.systemBackground).opacity(0.6))
                                }
                            }()
                        )
                        .cornerRadius(24)
                        .glowBorder(cornerRadius: 24)
                        .padding(.horizontal)
                        
                        // 3. SÉLECTEUR DE PLAN
                        VStack(spacing: 12) {
                            PlanSelectorCard(title: "Annuel", price: "39,99 € / an", subtitle: "Soit 3,33 € / mois", badge: "-33%", isSelected: selectedPlan == "annual") { withAnimation { selectedPlan = "annual" } }
                            PlanSelectorCard(title: "Mensuel", price: "4,99 € / mois", subtitle: "Sans engagement", badge: nil, isSelected: selectedPlan == "monthly") { withAnimation { selectedPlan = "monthly" } }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    .padding(.bottom, 40)
                }
                .scrollContentBackground(.hidden) // Enlève le fond par défaut
                .background(Color.clear)          // Transparence
                
                // 4. FOOTER (BOUTON + LIENS)
                VStack(spacing: 15) {
                    // BOUTON D'ACHAT RÉEL
                    Button(action: {
                        Task {
                            let productID = selectedPlan == "annual" ? "workwalk_premium_annual" : "workwalk_premium_monthly"
                            if let product = storeManager.subscriptions.first(where: { $0.id == productID }) {
                                do {
                                    try await storeManager.purchase(product)
                                    if premiumManager.isPremium { dismiss() }
                                } catch {
                                    print("Erreur achat: \(error)")
                                }
                            }
                        }
                    }) {
                        Text(selectedPlan == "annual" ? "Commencer l'essai gratuit" : "S'abonner maintenant")
                            .font(.headline.bold())
                            .foregroundStyle(.white) // Reste blanc car fond orange
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(16)
                            .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    
                    // LIENS LÉGAUX
                    HStack(spacing: 20) {
                        Button("Restaurer") {
                            Task {
                                try? await AppStore.sync()
                                await storeManager.updatePurchasedProducts()
                                restoreMessage = premiumManager.isPremium ? "Achats restaurés avec succès !" : "Aucun achat trouvé."
                                showRestoreAlert = true
                            }
                        }
                        
                        Button("Conditions") { openURL(termsURL) }
                        
                        Button("Confidentialité") { showPrivacyPolicy = true }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    {
                        if #available(iOS 15.0, macOS 12.0, *) {
                            return AnyShapeStyle(.ultraThinMaterial)
                        } else {
                            return AnyShapeStyle(Color(.systemBackground).opacity(0.6))
                        }
                    }()
                ) // Fond footer effet verre
            }
        }
        // MODALE CONFIDENTIALITÉ INTERNE
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationStack {
                PrivacyPolicyView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Fermer") { showPrivacyPolicy = false }
                        }
                    }
            }
        }
        // ALERTE RESTAURATION
        .alert("Restauration", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreMessage)
        }
    }
}

// MARK: - COMPOSANTS UI ADAPTATIFS

struct DetailedFeatureRow: View {
    let icon: String; let color: Color; let title: String; let subtitle: String
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 40, height: 40)
                Image(systemName: icon).font(.headline).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(.primary) // Adaptatif
                Text(subtitle).font(.caption).foregroundStyle(.secondary) // Adaptatif
                    .fixedSize(horizontal: false, vertical: true).lineLimit(nil)
            }
            Spacer()
        }
    }
}

struct PlanSelectorCard: View {
    let title: String; let price: String; let subtitle: String; let badge: String?; let isSelected: Bool; let action: () -> Void
    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isSelected ? .orange : .gray)
                .padding(.trailing, 5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(.primary) // Adaptatif
                Text(subtitle).font(.caption).foregroundStyle(.secondary) // Adaptatif
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let badgeText = badge {
                    Text(badgeText)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .cornerRadius(4)
                }
                Text(price).font(.headline).fontWeight(.bold).foregroundStyle(.primary) // Adaptatif
            }
        }
        .padding()
        // Fond adaptatif
        .background(
            isSelected
            ? AnyShapeStyle(Color.orange.opacity(0.1))
            : {
                if #available(iOS 15.0, macOS 12.0, *) {
                    return AnyShapeStyle(.ultraThinMaterial)
                } else {
                    return AnyShapeStyle(Color(.systemBackground).opacity(0.6))
                }
            }()
        )
        .cornerRadius(16)
        // Bordure Orange si sélectionné, sinon GlowBorder standard
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
        )
        // Ajout du liseré stylé si non sélectionné (pour garder le style app)
        .glowBorder(cornerRadius: 16)
        .contentShape(Rectangle())
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }
    }
}

