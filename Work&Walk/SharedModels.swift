import SwiftUI
import SwiftData

// MARK: - MODÈLES PARTAGÉS

enum MetricType: String, Identifiable, Codable, CaseIterable {
    case steps, calories, distance, heart
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .steps: return "Pas"
        case .calories: return "Calories"
        case .distance: return "Distance"
        case .heart: return "Cardio"
        }
    }
    
    var unit: String {
        switch self {
        case .steps: return "pas"
        case .calories: return "kcal"
        case .distance: return "km"
        case .heart: return "bpm"
        }
    }
    
    var color: Color {
        switch self {
        case .steps: return .orange
        case .calories: return .red
        case .distance: return .green
        case .heart: return .pink
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .steps: return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .calories: return LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .distance: return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .heart: return LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct DashboardWidget: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var type: MetricType
    var isVisible: Bool
}

struct DailyActivity: Identifiable {
    let id: UUID
    let dayName: String
    let date: Date
    let workSteps: Double
    let personalSteps: Double
    let workCal: Double
    let personalCal: Double
    let workDist: Double
    let personalDist: Double
    let workHeart: Double
    let personalHeart: Double
}

struct DailyData: Identifiable {
    let id: UUID
    let date: Date
    let dayName: String
    let workVal: Double
    let lifeVal: Double
}
