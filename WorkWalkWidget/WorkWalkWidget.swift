import WidgetKit
import SwiftUI

// 1. LE PROVIDER (Gère les données)
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), steps: 5000, hours: "4h 00m", calories: 250)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), steps: 8500, hours: "6h 30m", calories: 450)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let data = WidgetDataManager.load()
        let entry = SimpleEntry(
            date: Date(),
            steps: data.steps,
            hours: data.hours,
            calories: data.calories
        )
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// 2. LA STRUCTURE DE DONNÉES
struct SimpleEntry: TimelineEntry {
    let date: Date
    let steps: Double
    let hours: String
    let calories: Double
}

// 3. LE FOND GLOW SPÉCIFIQUE AU WIDGET
struct WidgetGlowBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white)
            
            Circle()
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.4 : 0.3))
                .blur(radius: 30)
                .offset(x: -20, y: -20)
            
            Circle()
                .fill(Color.red.opacity(colorScheme == .dark ? 0.2 : 0.15))
                .blur(radius: 25)
                .offset(x: 20, y: 20)
        }
        .ignoresSafeArea()
    }
}

// 4. LA VUE (Mise en page originale + Style Glow + Décalage Gauche)
struct WorkWalkWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // HEADER
            HStack {
                Text("WORK & WALK")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.orange)
                    .tracking(1.2)
                Spacer()
            }
            
            Spacer()
            
            if family == .systemSmall {
                // --- PETIT WIDGET ---
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(entry.steps))")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("pas aujourd'hui")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 12)
                
                HStack(spacing: 6) {
                    Image(systemName: "briefcase.fill").font(.caption2)
                    Text(entry.hours).font(.caption).fontWeight(.semibold)
                }
                .padding(.vertical, 5).padding(.horizontal, 10)
                .background(Color.orange.opacity(0.15))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
                
            } else {
                // --- MOYEN WIDGET ---
                HStack(alignment: .center, spacing: 15) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Activité").font(.caption).fontWeight(.bold).foregroundStyle(.secondary).textCase(.uppercase)
                        Text("\(Int(entry.steps))")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("pas").font(.subheadline).foregroundStyle(.orange).fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "briefcase.fill").foregroundStyle(.blue).font(.caption)
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Travail").font(.system(size: 9)).foregroundStyle(.secondary)
                                Text(entry.hours).font(.subheadline).fontWeight(.bold)
                            }
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill").foregroundStyle(.red).font(.caption)
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Énergie").font(.system(size: 9)).foregroundStyle(.secondary)
                                Text("\(Int(entry.calories)) kcal").font(.subheadline).fontWeight(.bold)
                            }
                        }
                    }
                }
            }
        }
        // 👇 AJUSTEMENT DU DÉCALAGE GAUCHE ICI
        .padding(.leading, 4)   // On réduit la marge de gauche (6 au lieu de 12)
        .padding(.trailing, 12) // Marge standard à droite
        .padding(.vertical, 12) // Marge standard haut/bas
        .containerBackground(for: .widget) {
            WidgetGlowBackground()
        }
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
