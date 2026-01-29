import Foundation
import HealthKit
import Combine

class HealthManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var stepsToday: Double = 0
    @Published var caloriesToday: Double = 0
    @Published var distanceToday: Double = 0
    @Published var flightsToday: Double = 0 // 👈 AJOUTÉ
    
    func requestAuthorization() {
        // 👇 AJOUT DE .flightsClimbed DANS LES TYPES À LIRE
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success { self.fetchTodayData() }
        }
    }
    
    func fetchTodayData() {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        fetchQuantity(type: .stepCount, start: startOfDay, end: now) { count in DispatchQueue.main.async { self.stepsToday = count } }
        fetchQuantity(type: .activeEnergyBurned, start: startOfDay, end: now) { count in DispatchQueue.main.async { self.caloriesToday = count } }
        fetchQuantity(type: .distanceWalkingRunning, start: startOfDay, end: now) { count in DispatchQueue.main.async { self.distanceToday = count } }
        // 👇 AJOUT RÉCUPÉRATION ÉTAGES AUJOURD'HUI
        fetchQuantity(type: .flightsClimbed, start: startOfDay, end: now) { count in DispatchQueue.main.async { self.flightsToday = count } }
    }
    
    // Fonction générique modifiée pour gérer les étages
    func fetchQuantity(type: HKQuantityTypeIdentifier, start: Date, end: Date, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: type) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { completion(0); return }
            
            // 👇 GESTION DES UNITÉS
            if type == .distanceWalkingRunning {
                completion(sum.doubleValue(for: HKUnit.meter()) / 1000.0) // km
            } else if type == .activeEnergyBurned {
                completion(sum.doubleValue(for: HKUnit.kilocalorie())) // kcal
            } else if type == .heartRate {
                // Pour le coeur c'est une moyenne, pas une somme, mais ta fonction gère des sommes.
                // On simplifie ici pour l'instant.
                completion(sum.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
            } else {
                // Pas et Étages = Count
                completion(sum.doubleValue(for: HKUnit.count()))
            }
        }
        
        // Pour le coeur, on utilise une requête différente (moyenne)
        if type == .heartRate {
            let heartQuery = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
                guard let result = result, let avg = result.averageQuantity() else { completion(0); return }
                completion(avg.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
            }
            healthStore.execute(heartQuery)
        } else {
            healthStore.execute(query)
        }
    }
}
