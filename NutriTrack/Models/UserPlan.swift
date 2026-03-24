import Foundation
import SwiftData

// MARK: - Modèle SwiftData

@Model
class UserPlan {
    var profileID: String = ""            // UUID du UserProfile propriétaire
    var dateCreation: Date = Date()
    var version: Int = 1
    var estActif: Bool = true

    // Critique de faisabilité
    var critiqueIA: String = ""
    var niveauFaisabilite: String = "realiste"   // NiveauFaisabilite.rawValue
    var alternativeSuggeree: String = ""
    var objectifForce: Bool = false              // true si l'utilisateur force malgré danger

    // Plans (JSON encodé)
    var planNutritionJSON: String = ""
    var planEntrainementJSON: String = ""
    var recommandationsVie: String = ""

    // Réévaluation
    var prochainReevaluation: Date = Date()
    var derniereReevaluation: Date = Date()

    init() {
        self.dateCreation = Date()
        self.version = 1
        self.estActif = true
        self.prochainReevaluation = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        self.derniereReevaluation = Date()
    }

    // MARK: - Computed

    var niveauFaisabiliteEnum: NiveauFaisabilite {
        NiveauFaisabilite(rawValue: niveauFaisabilite) ?? .realiste
    }

    var planNutrition: PlanNutritionnel? {
        decodePlanNutrition(from: planNutritionJSON)
    }

    var planEntrainement: PlanEntrainement? {
        decodePlanEntrainement(from: planEntrainementJSON)
    }

    func sauvegarderPlanNutrition(_ plan: PlanNutritionnel) {
        planNutritionJSON = encodePlanNutrition(plan)
    }

    func sauvegarderPlanEntrainement(_ plan: PlanEntrainement) {
        planEntrainementJSON = encodePlanEntrainement(plan)
    }
}

// PlanNutritionnel, PlanEntrainement, JourEntrainement, ExercicePlan, RepasTypePlan
// sont définis dans PlanModels.swift (séparé pour éviter les problèmes d'isolation @MainActor)
