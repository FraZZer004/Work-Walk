import Foundation
import SwiftData

@Model
final class WorkSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var hourlyRate: Double
    
    // Constructeur mis à jour : permet de définir directement la fin si on veut
    init(startTime: Date = Date(), endTime: Date? = nil, hourlyRate: Double = 15.0) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.hourlyRate = hourlyRate
    }
    
    // Calcul de la durée en heures (utile pour l'affichage)
    var durationInHours: Double {
        guard let end = endTime else { return 0 }
        return end.timeIntervalSince(startTime) / 3600
    }
}
