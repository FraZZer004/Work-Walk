import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Group {
                    Text("Dernière mise à jour : 24 Janvier 2026")
                        .font(.caption).foregroundStyle(.secondary)
                    
                    Text("1. Collecte des données")
                        .font(.headline)
                    Text("L'application Work&Walk collecte les données suivantes uniquement via Apple HealthKit : nombre de pas, distance parcourue, énergie active (calories) et fréquence cardiaque. Ces données sont utilisées exclusivement pour afficher vos statistiques dans l'onglet 'Analyse'.")
                    
                    Text("2. Stockage des données")
                        .font(.headline)
                    Text("Toutes vos données (sessions de travail, salaire, historique santé) sont stockées LOCALEMENT sur votre appareil via la technologie SwiftData. Aucune donnée n'est envoyée vers un serveur externe, un cloud tiers ou une base de données marketing.")
                    
                    Text("3. Partage des données")
                        .font(.headline)
                    Text("Nous ne vendons, n'échangeons et ne transférons aucune de vos données personnelles à des tiers. Vos données restent sur votre iPhone.")
                }
                
                Group {
                    Text("4. Santé (HealthKit)")
                        .font(.headline)
                    Text("L'application demande l'accès en lecture à vos données Santé. Vous pouvez révoquer cet accès à tout moment dans les Réglages iOS > Santé > Accès aux données et appareils > Work&Walk.")
                    
                    Text("5. Contact")
                        .font(.headline)
                    Text("Pour toute question concernant cette politique, vous pouvez nous contacter via l'App Store.")
                }
            }
            .padding()
            .font(.body)
        }
        .navigationTitle("Confidentialité")
    }
}
