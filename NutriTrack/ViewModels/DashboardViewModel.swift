import Foundation
import SwiftData
import Observation

@Observable
class DashboardViewModel {

    var bilan: NutritionCalculator.BilanJour?
    var calories7Jours: [(date: Date, calories: Double)] = []
    var caloriesBruleesAujourdhui: Double = 0   // HealthKit
    var caloriesBruleesActivites: Double = 0    // activités manuelles
    var totalCaloriesBrulees: Double { caloriesBruleesAujourdhui + caloriesBruleesActivites }
    var pasAujourdhui: Double = 0
    var conseilIA: String = ""
    var isLoadingConseil = false
    var isLoadingHealthKit = false

    // Dernières métriques corporelles
    var dernierPoids: Double = 0
    var dernierIMC: Double = 0
    var derniereMasseGrasse: Double = 0

    // MARK: - Chargement du bilan du jour

    func charger(context: ModelContext, profil: UserProfile?) {
        chargerBilanDuJour(context: context, profil: profil)
        chargerHistorique7Jours(context: context, profileID: profil?.profileID.uuidString ?? "")
        chargerDerniereMetrique(context: context, profileID: profil?.profileID.uuidString ?? "")
        chargerCaloriesActivites(context: context, profileID: profil?.profileID.uuidString ?? "")
    }

    private func chargerCaloriesActivites(context: ModelContext, profileID: String) {
        guard !profileID.isEmpty else { return }
        let debut = Date().debutDeJour
        let fin   = Date().finDeJour
        let pid   = profileID
        let descriptor = FetchDescriptor<ActivityEntry>(
            predicate: #Predicate<ActivityEntry> {
                $0.date >= debut && $0.date <= fin && $0.profileID == pid
            }
        )
        let activites = (try? context.fetch(descriptor)) ?? []
        caloriesBruleesActivites = activites.reduce(0) { $0 + $1.caloriesBurned }
    }

    private func chargerBilanDuJour(context: ModelContext, profil: UserProfile?) {
        guard let profil else { bilan = nil; return }
        let aujourd = Date()
        let debut = aujourd.debutDeJour
        let fin   = aujourd.finDeJour
        let pid   = profil.profileID.uuidString

        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> {
                $0.date >= debut && $0.date <= fin && $0.profileID == pid
            }
        )
        let entries = (try? context.fetch(descriptor)) ?? []
        bilan = NutritionCalculator.bilan(entries: entries, profil: profil)
    }

    private func chargerHistorique7Jours(context: ModelContext, profileID: String) {
        var resultats: [(date: Date, calories: Double)] = []
        let pid = profileID

        for i in 0..<7 {
            guard let jour = Calendar.current.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let debut = jour.debutDeJour
            let fin   = jour.finDeJour

            let descriptor = FetchDescriptor<FoodEntry>(
                predicate: #Predicate<FoodEntry> {
                    $0.date >= debut && $0.date <= fin && $0.profileID == pid
                }
            )
            let entries = (try? context.fetch(descriptor)) ?? []
            let totalCal = entries.reduce(0) { $0 + $1.calories }
            resultats.append((date: jour, calories: totalCal))
        }

        calories7Jours = resultats.reversed()
    }

    private func chargerDerniereMetrique(context: ModelContext, profileID: String) {
        guard !profileID.isEmpty else { return }
        let pid = profileID
        var descriptor = FetchDescriptor<BodyMetric>(
            predicate: #Predicate<BodyMetric> { $0.profileID == pid },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let derniere = (try? context.fetch(descriptor))?.first else { return }
        dernierPoids       = derniere.weight
        dernierIMC         = derniere.bmi
        derniereMasseGrasse = derniere.bodyFatPercentage
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

    // MARK: - Conseil IA du jour (cache 1 appel/jour)

    func chargerConseilIA(service: ClaudeAIService, profil: UserProfile, context: ModelContext) async {
        guard profil.aUneCleAPI else { return }

        // Afficher le cache existant immédiatement
        if !profil.conseilIADuJour.isEmpty {
            conseilIA = profil.conseilIADuJour
        }

        // Ne pas rappeler l'API si le conseil du jour est déjà frais
        let dejaFrais = Calendar.current.isDateInToday(profil.conseilIADate)
        guard !dejaFrais else { return }

        isLoadingConseil = true
        defer { isLoadingConseil = false }

        let contexte = construireContexte(profil: profil, context: context)
        let conseil = await service.conseilDuJour(contexte: contexte, apiKey: profil.claudeAPIKey)

        if let texte = conseil {
            conseilIA = texte
            // Sauvegarder en cache dans UserProfile
            profil.conseilIADuJour = texte
            profil.conseilIADate = Date()
            try? context.save()
        }
    }

    func rafraichirConseilIA(service: ClaudeAIService, profil: UserProfile, context: ModelContext) async {
        guard profil.aUneCleAPI else { return }
        isLoadingConseil = true
        defer { isLoadingConseil = false }

        let contexte = construireContexte(profil: profil, context: context)
        let conseil = await service.conseilDuJour(contexte: contexte, apiKey: profil.claudeAPIKey)

        if let texte = conseil {
            conseilIA = texte
            profil.conseilIADuJour = texte
            profil.conseilIADate = Date()
            try? context.save()
        }
    }

    private func construireContexte(profil: UserProfile, context: ModelContext) -> ContexteNutritionnel {
        let pid = profil.profileID.uuidString
        var resumeJours: [String] = []
        for i in 0..<7 {
            guard let jour = Calendar.current.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let debut = jour.debutDeJour
            let fin   = jour.finDeJour
            let descriptor = FetchDescriptor<FoodEntry>(
                predicate: #Predicate<FoodEntry> {
                    $0.date >= debut && $0.date <= fin && $0.profileID == pid
                }
            )
            let entries = (try? context.fetch(descriptor)) ?? []
            let cal  = entries.reduce(0) { $0 + $1.calories }
            let prot = entries.reduce(0) { $0 + $1.proteins }
            resumeJours.append("\(jour.formatCourt) : \(cal.arrondi(0)) kcal / Prot: \(prot.arrondi(0))g")
        }

        let metricsDesc = FetchDescriptor<BodyMetric>(
            predicate: #Predicate<BodyMetric> { $0.profileID == pid },
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

        let objTransfo = NutritionCalculator.objectifsCaloriques(profil: profil)
        let macTransfo = NutritionCalculator.macrosCiblesTransformation(
            calories:   objTransfo.objectifTransformation,
            poidsKg:    profil.poidsActuel,
            ajustement: objTransfo.ajustement,
            approche:   profil.approcheEnum
        )
        return ContexteNutritionnel(
            prenom:             profil.prenom,
            objectifCalorique:  objTransfo.objectifTransformation,
            objectifProteines:  macTransfo.proteines,
            objectifGlucides:   macTransfo.glucides,
            objectifLipides:    macTransfo.lipides,
            resumeSemaine:      resumeJours.joined(separator: "\n"),
            tendancePoids:      tendance,
            dernierPoids:       dernierPoids
        )
    }
}
