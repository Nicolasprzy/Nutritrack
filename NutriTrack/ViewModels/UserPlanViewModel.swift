import Foundation
import SwiftData
import Observation

@Observable
class UserPlanViewModel {

    var planActif: UserPlan?
    var isGenerating: Bool = false
    var errorMessage: String?
    var showProgrammeComplet: Bool = false
    var showPlanNutritionComplet: Bool = false

    private let service = ClaudeAIService()

    // MARK: - Chargement

    func chargerPlanActif(context: ModelContext) {
        let descriptor = FetchDescriptor<UserPlan>(
            predicate: #Predicate<UserPlan> { $0.estActif == true },
            sortBy: [SortDescriptor(\.dateCreation, order: .reverse)]
        )
        planActif = (try? context.fetch(descriptor))?.first
    }

    // MARK: - Génération

    func genererPlan(profil: UserProfile, context: ModelContext) async {
        guard profil.aUneCleAPI else {
            errorMessage = "Clé API Claude requise. Ajoutez-la dans votre Profil."
            return
        }
        isGenerating = true
        errorMessage = nil

        let response = await service.genererPlanComplet(profil: profil, apiKey: profil.claudeAPIKey)

        if let r = response {
            // Désactiver l'ancien plan
            if let ancien = planActif {
                ancien.estActif = false
            }

            // Créer le nouveau plan associé au profil
            let plan = UserPlan()
            plan.profileID = profil.profileID.uuidString
            plan.critiqueIA = r.critique
            plan.niveauFaisabilite = r.niveauFaisabilite
            plan.alternativeSuggeree = r.alternativeSuggeree
            plan.recommandationsVie = r.recommandationsVie
            plan.sauvegarderPlanNutrition(r.planNutrition)
            plan.sauvegarderPlanEntrainement(r.planEntrainement)
            plan.prochainReevaluation = Calendar.current.date(
                byAdding: .day, value: profil.frequenceReevaluation, to: Date()
            ) ?? Date()
            plan.derniereReevaluation = Date()

            context.insert(plan)

            // Mettre à jour les objectifs nutritionnels du profil
            profil.objectifCalorique = r.planNutrition.caloriesJournalieres
            profil.objectifProteines = r.planNutrition.proteinesG
            profil.objectifGlucides  = r.planNutrition.glucidesG
            profil.objectifLipides   = r.planNutrition.lipidesG

            try? context.save()
            planActif = plan

            // Planifier la notification de réévaluation
            let prenom = profil.prenom
            let jours  = profil.frequenceReevaluation
            Task { @MainActor in
                await NotificationService.shared.demanderAutorisation()
                NotificationService.shared.planifierReevaluation(dans: jours, prenom: prenom)
            }
        } else {
            errorMessage = service.errorMessage ?? "Erreur lors de la génération du plan."
        }

        isGenerating = false
    }

    func reevaluerPlan(profil: UserProfile, context: ModelContext) async {
        await genererPlan(profil: profil, context: context)
    }

    // MARK: - Marquer séance comme faite

    func marquerSeanceFaite(jourId: String, context: ModelContext) {
        guard let plan = planActif,
              var entrainement = plan.planEntrainement else { return }

        if let idx = entrainement.semaineType.firstIndex(where: { $0.id == jourId }) {
            entrainement.semaineType[idx].seanceFaite = true
            entrainement.semaineType[idx].dateFaite = ISO8601DateFormatter().string(from: Date())
        }
        plan.sauvegarderPlanEntrainement(entrainement)
        try? context.save()
    }

    // MARK: - Séance du jour

    var seanceDuJour: JourEntrainement? {
        guard let entrainement = planActif?.planEntrainement else { return nil }
        let weekday = Calendar.current.component(.weekday, from: Date())
        let jourIdx = (weekday + 5) % 7  // 0=Lundi…6=Dimanche
        let jours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
        let label = jourIdx < jours.count ? jours[jourIdx] : ""
        return entrainement.semaineType.first { $0.jourLabel.lowercased().contains(label.lowercased()) }
            ?? (entrainement.semaineType.indices.contains(jourIdx) ? entrainement.semaineType[jourIdx] : nil)
    }

    // MARK: - Réévaluation nécessaire ?

    var reevaluationRequise: Bool {
        guard let plan = planActif else { return false }
        return Date() >= plan.prochainReevaluation
    }

    var joursAvantReevaluation: Int {
        guard let plan = planActif else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: plan.prochainReevaluation).day ?? 0
        return max(0, days)
    }
}
