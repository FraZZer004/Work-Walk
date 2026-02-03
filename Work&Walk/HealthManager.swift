import Foundation
import HealthKit
import Combine

class HealthManager: ObservableObject {
    static let shared = HealthManager()
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
    
    // 1. Fonction à lancer au démarrage de l'app
    func startBackgroundObserver() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        // Active la mise à jour en arrière-plan
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
            if success { print("✅ Background Delivery activé") }
        }
        
        // L'observateur qui réveille l'app quand les pas changent
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            guard error == nil else { return }
            
            // ⚠️ IMPORTANT : On est en arrière-plan, on recalcule et on sauvegarde
            print("🔄 Mouvement détecté en arrière-plan !")
            self?.fetchTodayStepsAndRefreshWidget()
        }
        
        healthStore.execute(query)
    }
    
    // 2. Fonction qui calcule et sauvegarde
    // Dans HealthManager.swift

        func fetchTodayStepsAndRefreshWidget() {
            let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
            // On garde ta logique de pas qui fonctionne
            let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date(), options: .strictStartDate)
            
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                guard let result = result, let sum = result.sumQuantity() else { return }
                
                // 1. Les Pas (On garde ça, c'est le background qui marche)
                let totalStepsToday = sum.doubleValue(for: HKUnit.count())
                let estimatedCalories = totalStepsToday * 0.04
                
                // 2. Le Salaire & Heures (C'EST ICI QU'ON CHANGE)
                // On ne calcule PLUS rien basé sur les pas.
                // On lit juste la valeur "fixe" sauvegardée par ta vue Salaire.
                // Si tu n'as rien saisi, par défaut ce sera 0.
                let savedSalary = UserDefaults.standard.double(forKey: "manual_today_salary")
                let savedHours = UserDefaults.standard.string(forKey: "manual_today_hours") ?? "0h"
                
                // 3. On envoie au Widget
                DispatchQueue.main.async {
                    #if os(iOS)
                    WidgetDataManager.save(
                        steps: totalStepsToday, // Les pas bougent tout seuls (c'est ce qu'on veut)
                        hours: savedHours,      // Les heures restent fixes (selon ta saisie)
                        calories: estimatedCalories,
                        salary: savedSalary     // Le salaire reste fixe (selon ta saisie)
                    )
                    #endif
                }
            }
            
            healthStore.execute(query)
        }
}
