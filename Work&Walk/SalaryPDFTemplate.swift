import SwiftUI

struct SalaryPDFTemplate: View {
    let month: String
    let hours: String
    let rate: Double
    let gross: String
    let taxRate: Double
    let taxAmount: String
    let net: String
    let symbol: String
    let userName: String
    
    var body: some View {
        VStack(spacing: 0) {
            // --- EN-TÊTE ---
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                    Text("Work&Walk")
                        .font(.title2).bold()
                        .foregroundStyle(.orange)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    // 👇 Traduction forcée
                    Text(LocalizedStringKey("FICHE ESTIMATIVE"))
                        .font(.headline)
                        .foregroundStyle(.gray)
                    Text(month.uppercased())
                        .font(.title3).bold()
                }
            }
            .padding(.bottom, 40)
            
            Divider()
            
            // --- INFO UTILISATEUR ---
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey("Employé :"))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(userName)
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(LocalizedStringKey("Date d'émission :"))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(Date().formatted(date: .numeric, time: .omitted))
                        .font(.body)
                }
            }
            .padding(.vertical, 30)
            
            // --- TABLEAU DES CHIFFRES ---
            VStack(spacing: 0) {
                // Header Tableau
                HStack {
                    Text(LocalizedStringKey("Désignation")).bold()
                    Spacer()
                    Text(LocalizedStringKey("Montant"))
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                
                // Lignes
                // On passe les clés de traduction directement
                row(label: "Volume Horaire", value: hours)
                row(label: "Taux Horaire", value: "\(rate) \(symbol)/h")
                Divider()
                row(label: "Salaire Brut", value: gross)
                
                // Cas spécial pour inclure le % dans la traduction si besoin, ou juste concaténer
                // Cas spécial pour inclure le %
                                HStack {
                                    // 1. Le texte traduit
                                    Text(LocalizedStringKey("Charges Sociales"))
                                    
                                    // 2. Le pourcentage (séparé, juste à côté)
                                    Text("(\(Int(taxRate))%)")
                                    
                                    Spacer()
                                    
                                    // 3. Le montant en rouge
                                    Text(taxAmount).foregroundStyle(.red)
                                }
                                .padding()
                
                Divider()
                
                // TOTAL
                HStack {
                    Text(LocalizedStringKey("NET À PAYER ESTIMÉ"))
                        .font(.headline)
                    Spacer()
                    Text(net)
                        .font(.title2).bold()
                        .foregroundStyle(.orange)
                }
                .padding()
                .background(Color.orange.opacity(0.05))
            }
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            
            Spacer()
            
            // --- PIED DE PAGE ---
            Text(LocalizedStringKey("Ce document est une estimation générée par Work&Walk et n'a pas de valeur légale."))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
        }
        .padding(40)
        .frame(width: 595, height: 842)
        .background(.white)
        .foregroundStyle(.black)
    }
    
    // Helper modifié pour accepter la traduction
    func row(label: String, value: String, isRed: Bool = false) -> some View {
        HStack {
            Text(LocalizedStringKey(label)) // <--- La magie est ici
            Spacer()
            Text(value)
                .foregroundStyle(isRed ? .red : .black)
        }
        .padding()
    }
}
