import WidgetKit
import SwiftUI

// 1. LE PROVIDER (Gère les données et les mises à jour)
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        // Données bidons pour l'aperçu
        SimpleEntry(date: Date(), steps: 5000, hours: "4h 00m", calories: 250)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        // Aperçu galerie
        let entry = SimpleEntry(date: Date(), steps: 8500, hours: "6h 30m", calories: 450)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // 1. C'est CETTE ligne qui va chercher les infos dans le tuyau
        let data = WidgetDataManager.load()
        
        // 2. On crée l'entrée avec les données récupérées
        let entry = SimpleEntry(
            date: Date(),
            steps: data.steps,      // <--- Vérifie que tu passes bien data.steps ici
            hours: data.hours,      // <--- et data.hours ici
            calories: data.calories // <--- et data.calories ici
        )

        // 3. On dit au widget de se rafraîchir plus tard
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// 2. LA STRUCTURE DE DONNÉES (C'est ici qu'il manquait 'steps' !)
struct SimpleEntry: TimelineEntry {
    let date: Date
    let steps: Double    // <--- C'est ça qui manquait
    let hours: String
    let calories: Double
}

// 3. LA VUE (Le Design Vibrant corrigé pour iOS 17)
struct WorkWalkWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    // Ta couleur orange
    let accentColor = Color.orange
    
    var body: some View {
        VStack(alignment: .leading) {
            
            // 1. EN-TÊTE (Sans l'image, texte en Orange)
            HStack(spacing: 6) {
                Text("WORK & WALK")
                    .font(.caption2)
                    .fontWeight(.black) // J'ai mis "black" pour que ce soit bien lisible
                    .foregroundStyle(.orange) // 👈 C'est ici que la magie opère !
                    .tracking(1) // Espacement léger des lettres pour le style
                
                Spacer()
            }
            .padding(.bottom, 2)
            
            Spacer()
            
            if family == .systemSmall {
                // --- PETIT WIDGET ---
                Text("\(Int(entry.steps))")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("pas aujourd'hui")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
                
                HStack(spacing: 6) {
                    Image(systemName: "briefcase.fill").font(.caption2)
                    Text(entry.hours).font(.caption).fontWeight(.semibold)
                }
                .padding(.vertical, 5).padding(.horizontal, 10)
                .background(accentColor.opacity(0.15))
                .foregroundStyle(accentColor)
                .clipShape(Capsule())
                
            } else {
                // --- MOYEN WIDGET ---
                HStack(alignment: .center, spacing: 30) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Activité").font(.caption).fontWeight(.bold).foregroundStyle(.secondary).textCase(.uppercase)
                        Text("\(Int(entry.steps))")
                            .font(.system(size: 42, weight: .heavy, design: .rounded))
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())
                        Text("pas").font(.subheadline).foregroundStyle(accentColor).fontWeight(.medium)
                    }
                    Rectangle().fill(Color.secondary.opacity(0.2)).frame(width: 1).padding(.vertical, 5)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Circle().fill(Color.blue.opacity(0.15)).frame(width: 32, height: 32)
                                .overlay(Image(systemName: "briefcase.fill").foregroundStyle(.blue).font(.caption))
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Travail").font(.caption2).foregroundStyle(.secondary)
                                Text(entry.hours).font(.subheadline).fontWeight(.bold)
                            }
                        }
                        HStack(spacing: 10) {
                            Circle().fill(Color.red.opacity(0.15)).frame(width: 32, height: 32)
                                .overlay(Image(systemName: "flame.fill").foregroundStyle(.red).font(.caption))
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Énergie").font(.caption2).foregroundStyle(.secondary)
                                Text("\(Int(entry.calories)) kcal").font(.subheadline).fontWeight(.bold)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .fontDesign(.rounded)
        .containerBackground(for: .widget) { Color(UIColor.systemBackground) }
    }
}

// 4. SOUS-VUE POUR LE STYLE
struct StatBlockVibrant: View {
    let icon: String; let title: String; let value: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .frame(width: 24, height: 24)
                .background(.white.opacity(0.2)).clipShape(Circle())
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.caption2).foregroundStyle(.white.opacity(0.7))
                Text(value).font(.callout).fontWeight(.bold)
            }
        }
        .foregroundStyle(.white)
    }
}

// 5. CONFIGURATION DU WIDGET
@main
struct WorkWalkWidget: Widget {
    let kind: String = "WorkWalkWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WorkWalkWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Stats Work&Walk")
        .description("Vos pas et heures de travail en direct.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
