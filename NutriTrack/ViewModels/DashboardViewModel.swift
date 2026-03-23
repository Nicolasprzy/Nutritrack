import Foundation
import SwiftData
import Observation

@Observable
class DashboardViewModel {

    var bilan: NutritionCalculator.BilanJour?
    var calories7Jours: [(date: Date, calories: Double)] = []
    var caloriesBruleesAujourdhui: Double = 0
    var pasAujourdhui: Double = 0
    var conseilIA: String = ""
    var isLoadingConseil = false
    var isLoadingHealthKit = false

    // MARK: - Chargement du bilan du jour

    func charger(context: ModelContext) {
        chargerBilanDuJour(context: context)
        chargerHistorique7Jours(context: context)
    }

    private func chargerBilanDuJour(context: ModelContext) {
        let aujourd = Date()
        let debut = aujourd.debutDeJour
        let fin   = aujourd.finDeJour

        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> {
                $0.date >= debut && $0.date <= fin
            }
        )

        let entries = (try? context.fetch(descriptor)) ?? []

        let profilDescriptor = FetchDescriptor<UserProfile>()
        guard let profil = try? context.fetch(profilDescriptor).first else {
            bilan = nil
            return
        }

        bilan = NutritionCalculator.bilan(entries: entries, profil: profil)
    }

    private func chargerHistorique7Jours(context: ModelContext) {
        var resultats: [(date: Date, calories: Double)] = []

        for i in 0..<7 {
            guard let jour = Calendar.current.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let debut = jour.debutDeJour
            let fin   = jour.finDeJour

            let descriptor = FetchDescriptor<FoodEntry>(
                predicate: #Predicate<FoodEntry> { $0.date >= debut && $0.date <= fin }
            )
            let entries = (try? context.fetch(descriptor)) ?? []
            let totalCal = entries.reduce(0) { $0 + $1.calories }
            resultats.append((date: jour, calories: totalCal))
        }

        calories7Jours = resultats.reversed()
    }

    // MARK: - HealthKit

    func chargerDonneesHealthKit(service: HealthKitService) async {
        guard service.isAuthorized else { return }

        isLoadingHealthKit = true
        defer { isLoadingHealthKit = false }

        async let cal = service.lireCaloriesBrulees()
        async let pas = service.lirePasDuJour()

        caloriesBruleesAujourdhui = await cal
        pasAujourdhui = await pas
    }

    // MARK: - Conseil IA du jour

    func chargerConseilIA(service: ClaudeAIService, profil: UserProfile, context: ModelContext) async {
        guard profil.aUneCleAPI else { return }

        isLoadingConseil = true
        defer { isLoadingConseil = false }

        let contexte = construireContexte(profil: profil, context: context)
        let conseil = await service.conseilDuJour(contexte: contexte, apiKey: profil.claudeAPIKey)
        conseilIA = conseil ?? ""
    }

    private func construireContexte(profil: UserProfile, context: ModelContext) -> ContexteNutritionnel {
        var resumeJours: [String] = []
        for i in 0..<7 {
            guard let jour = Calendar.current.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let debut = jour.debutDeJour
            let fin   = jour.finDeJour
            let descriptor = FetchDescriptor<FoodEntry>(
                predicate: #Predicate<FoodEntry> { $0.date >= debut && $0.date <= fin }
            )
            let entries = (try? context.fetch(descriptor)) ?? []
            let cal  = entries.reduce(0) { $0 + $1.calories }
            let prot = entries.reduce(0) { $0 + $1.proteins }
            resumeJours.append("\(jour.formatCourt) : \(cal.arrondi(0)) kcal / Prot: \(prot.arrondi(0))g")
        }

        let metricsDesc = FetchDescriptor<BodyMetric>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let metrics = (try? context.fetch(metricsDesc)) ?? []
        let dernierPoids = metrics.first?.weight ?? 0
        let tendance: String
        if metrics.count >= 2 {
            let diff = metrics[0].weight - metrics.min(by: { abs($0.date.timeIntervalSinceNow) > abs($1.date.timeIntervalSinceNow) })!.weight
            tendance = diff > 0 ? "+\(diff.arrondi(1)) kg" : "\(diff.arrondi(1)) kg"
        } else {
            tendance = "Données insuffisantes"
        }

        return ContexteNutritionnel(
            prenom:             profil.prenom,
            objectifCalorique:  profil.objectifCalorique,
            objectifProteines:  profil.objectifProteines,
            objectifGlucides:   profil.objectifGlucides,
            objectifLipides:    profil.objectifLipides,
            resumeSemaine:      resumeJours.joined(separator: "\n"),
            tendancePoids:      tendance,
            dernierPoids:       dernierPoids
        )
    }
}
