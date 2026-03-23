import Foundation
import HealthKit
import SwiftData

@Observable
class HealthKitService {

    var isAvailable: Bool = HKHealthStore.isHealthDataAvailable()
    var isAuthorized: Bool = false
    var errorMessage: String?

    private let store = HKHealthStore()

    private let typesALire: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let poids = HKQuantityType.quantityType(forIdentifier: .bodyMass) { types.insert(poids) }
        if let calories = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(calories) }
        if let pas = HKQuantityType.quantityType(forIdentifier: .stepCount) { types.insert(pas) }
        if let alimentation = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) { types.insert(alimentation) }
        return types
    }()

    private let typesAEcrire: Set<HKSampleType> = {
        var types = Set<HKSampleType>()
        if let poids = HKQuantityType.quantityType(forIdentifier: .bodyMass) { types.insert(poids) }
        if let alimentation = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) { types.insert(alimentation) }
        return types
    }()

    // MARK: - Autorisation

    func demanderAutorisation() async -> Bool {
        guard isAvailable else {
            errorMessage = "HealthKit n'est pas disponible sur cet appareil."
            return false
        }

        do {
            try await store.requestAuthorization(toShare: typesAEcrire, read: typesALire)
            isAuthorized = true
            return true
        } catch {
            errorMessage = "Autorisation HealthKit refusée : \(error.localizedDescription)"
            isAuthorized = false
            return false
        }
    }

    // MARK: - Lecture du poids (30 derniers jours)

    func lirePoids(jours: Int = 30) async -> [(date: Date, poids: Double)] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return [] }

        let debut = Date.ilYaJours(jours)
        let predicate = HKQuery.predicateForSamples(withStart: debut, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                guard let samples = samples as? [HKQuantitySample], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                let resultats = samples.map { sample -> (date: Date, poids: Double) in
                    let poids = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                    return (date: sample.startDate, poids: poids)
                }
                continuation.resume(returning: resultats)
            }
            store.execute(query)
        }
    }

    // MARK: - Écriture du poids

    func ecrirePoids(_ poids: Double, date: Date = Date()) async -> Bool {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return false }

        let quantite = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: poids)
        let sample = HKQuantitySample(type: type, quantity: quantite, start: date, end: date)

        do {
            try await store.save(sample)
            return true
        } catch {
            errorMessage = "Impossible d'enregistrer le poids dans Santé."
            return false
        }
    }

    // MARK: - Calories brûlées du jour

    func lireCaloriesBrulees(date: Date = Date()) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }

        let debut = date.debutDeJour
        let fin   = date.finDeJour
        let predicate = HKQuery.predicateForSamples(withStart: debut, end: fin)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let calories = stats?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: calories)
            }
            store.execute(query)
        }
    }

    // MARK: - Pas du jour

    func lirePasDuJour(date: Date = Date()) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }

        let debut = date.debutDeJour
        let fin   = date.finDeJour
        let predicate = HKQuery.predicateForSamples(withStart: debut, end: fin)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let pas = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: pas)
            }
            store.execute(query)
        }
    }

    // MARK: - Écriture calories alimentaires

    func ecrireCaloriesAlimentaires(_ calories: Double, date: Date = Date()) async -> Bool {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else { return false }

        let quantite = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
        let sample = HKQuantitySample(type: type, quantity: quantite, start: date, end: date)

        do {
            try await store.save(sample)
            return true
        } catch {
            errorMessage = "Impossible d'enregistrer les calories dans Santé."
            return false
        }
    }

    // MARK: - Import poids vers BodyMetric

    func importerPoidsDansSwiftData(context: ModelContext) async {
        let donneesPoids = await lirePoids(jours: 30)

        for (date, poids) in donneesPoids {
            // Vérifier que cette mesure n'existe pas déjà
            let debutJour = date.debutDeJour
            let finJour = date.finDeJour
            let descriptor = FetchDescriptor<BodyMetric>(
                predicate: #Predicate<BodyMetric> {
                    $0.date >= debutJour && $0.date <= finJour && $0.weight > 0
                }
            )

            if let existantes = try? context.fetch(descriptor), !existantes.isEmpty {
                continue
            }

            let metric = BodyMetric(date: date, weight: poids)
            context.insert(metric)
        }

        try? context.save()
    }
}
