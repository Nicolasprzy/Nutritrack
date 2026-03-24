import Foundation
import SwiftData
import Observation

@Observable
class BodyTrackingViewModel {

    var metrics: [BodyMetric] = []
    var periode: Periode = .trentejours
    var showAddMetric = false

    enum Periode: String, CaseIterable {
        case trentejours  = "30J"
        case quatrevingtdixjours = "90J"
        case unan         = "1 An"

        var jours: Int {
            switch self {
            case .trentejours:           return 30
            case .quatrevingtdixjours:   return 90
            case .unan:                  return 365
            }
        }
    }

    // MARK: - Chargement

    func charger(context: ModelContext, profileID: String = "") {
        let debut = Date.ilYaJours(periode.jours)
        let pid = profileID
        let descriptor: FetchDescriptor<BodyMetric>
        if pid.isEmpty {
            descriptor = FetchDescriptor<BodyMetric>(
                predicate: #Predicate<BodyMetric> { $0.date >= debut },
                sortBy: [SortDescriptor(\.date)]
            )
        } else {
            descriptor = FetchDescriptor<BodyMetric>(
                predicate: #Predicate<BodyMetric> { $0.date >= debut && $0.profileID == pid },
                sortBy: [SortDescriptor(\.date)]
            )
        }
        metrics = (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Données calculées

    var dernierPoids: Double {
        metrics.last?.weight ?? 0
    }

    var dernierIMC: Double {
        metrics.last?.bmi ?? 0
    }

    var evolutionPoids: Double {
        guard metrics.count >= 2 else { return 0 }
        return metrics.last!.weight - metrics.first!.weight
    }

    var evolutionPoidsFormatee: String {
        let diff = evolutionPoids
        if diff == 0 { return "Stable" }
        return diff > 0 ? "+\(diff.arrondi(1)) kg" : "\(diff.arrondi(1)) kg"
    }

    var couleurEvolution: String {
        evolutionPoids > 0.5 ? "red" : (evolutionPoids < -0.5 ? "green" : "primary")
    }

    // Données pour le graphique poids
    var donneesPoids: [(date: Date, poids: Double)] {
        metrics.filter { $0.weight > 0 }.map { ($0.date, $0.weight) }
    }

    var donneesTourDeTaille: [(date: Date, valeur: Double)] {
        metrics.filter { $0.waist > 0 }.map { ($0.date, $0.waist) }
    }

    var donneesTourDeHanches: [(date: Date, valeur: Double)] {
        metrics.filter { $0.hips > 0 }.map { ($0.date, $0.hips) }
    }

    var donneesPoitrine: [(date: Date, valeur: Double)] {
        metrics.filter { $0.chest > 0 }.map { ($0.date, $0.chest) }
    }

    var donneesBras: [(date: Date, valeur: Double)] {
        metrics.filter { $0.armRight > 0 }.map { ($0.date, $0.armRight) }
    }

    var donneesCuisse: [(date: Date, valeur: Double)] {
        metrics.filter { $0.thigh > 0 }.map { ($0.date, $0.thigh) }
    }

    var donneesIMC: [(date: Date, valeur: Double)] {
        metrics.filter { $0.bmi > 0 }.map { ($0.date, $0.bmi) }
    }

    var donneesMasseGrasse: [(date: Date, valeur: Double)] {
        metrics.filter { $0.bodyFatPercentage > 0 }.map { ($0.date, $0.bodyFatPercentage) }
    }

    var derniereMensuration: BodyMetric? {
        metrics.reversed().first { $0.aMensurations }
    }

    // MARK: - Ajout

    func ajouterMetric(
        poids: Double,
        bmi: Double,
        tourTaille: Double,
        tourHanches: Double,
        poitrine: Double,
        bras: Double,
        cuisse: Double,
        masseGrasse: Double,
        notes: String,
        profileID: String = "",
        context: ModelContext
    ) {
        let metric = BodyMetric(
            date:               Date(),
            weight:             poids,
            bmi:                bmi,
            waist:              tourTaille,
            hips:               tourHanches,
            chest:              poitrine,
            armRight:           bras,
            thigh:              cuisse,
            bodyFatPercentage:  masseGrasse,
            notes:              notes
        )
        metric.profileID = profileID
        context.insert(metric)
        try? context.save()
        charger(context: context, profileID: profileID)
    }

    // MARK: - Suppression

    func supprimer(_ metric: BodyMetric, context: ModelContext) {
        context.delete(metric)
        try? context.save()
        charger(context: context)
    }
}
