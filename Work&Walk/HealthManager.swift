import Foundation
import HealthKit
import Observation

@Observable
class HealthManager {
    
    var stepsToday: Double = 0.0
    let healthStore = HKHealthStore()
    
    // On ajoute le rythme cardiaque à la liste
    let typesToRead: Set = [
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKQuantityType.quantityType(forIdentifier: .heartRate)!
    ]
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                self.fetchTodaySteps()
            }
        }
    }
    
    func fetchTodaySteps() {
        fetchQuantity(type: .stepCount, start: Calendar.current.startOfDay(for: Date()), end: Date()) { count in
            self.stepsToday = count
        }
    }
    
    // --- LA FONCTION UNIVERSELLE (Pas, Cal, Dist, Cœur) ---
    func fetchQuantity(type: HKQuantityTypeIdentifier, start: Date, end: Date, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: type) else { return }
        
        // Si c'est le coeur, on veut la MOYENNE. Sinon (Pas, Cal...), on veut la SOMME.
        let options: HKStatisticsOptions = (type == .heartRate) ? .discreteAverage : .cumulativeSum
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: options) { _, result, error in
            
            var value: Double = 0
            
            if let stats = result {
                if type == .heartRate {
                    // Pour le coeur : Moyenne
                    if let avg = stats.averageQuantity() {
                        value = avg.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    }
                } else {
                    // Pour le reste : Somme
                    if let sum = stats.sumQuantity() {
                        if type == .stepCount {
                            value = sum.doubleValue(for: HKUnit.count())
                        } else if type == .activeEnergyBurned {
                            value = sum.doubleValue(for: HKUnit.kilocalorie())
                        } else if type == .distanceWalkingRunning {
                            value = sum.doubleValue(for: HKUnit.meter()) / 1000 // Km
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(value)
            }
        }
        healthStore.execute(query)
    }
}
