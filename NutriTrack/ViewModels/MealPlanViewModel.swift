import Foundation
import SwiftData
import Observation

@Observable
class MealPlanViewModel {

    var plans: [MealPlan] = []
    var semaineCourante: Date = Date().debutDeSemaine
    var isGenerating = false
    var planGenere: String = ""
    var showPlanIA = false

    // MARK: - Chargement

    func charger(context: ModelContext) {
        let debut = semaineCourante
        guard let fin = Calendar.current.date(byAdding: .day, value: 7, to: debut) else { return }

        let descriptor = FetchDescriptor<MealPlan>(
            predicate: #Predicate<MealPlan> {
                $0.weekStartDate >= debut && $0.weekStartDate < fin
            },
            sortBy: [SortDescriptor(\.dayOfWeek), SortDescriptor(\.mealType)]
        )
        plans = (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Plans par jour

    func plans(pourJour jour: Int) -> [MealPlan] {
        plans.filter { $0.dayOfWeek == jour }
            .sorted { $0.mealType < $1.mealType }
    }

    // MARK: - Ajout

    func ajouterPlan(
        jour: Int,
        mealType: String,
        titre: String,
        notes: String,
        context: ModelContext
    ) {
        let plan = MealPlan(
            weekStartDate: semaineCourante,
            dayOfWeek:     jour,
            mealType:      mealType,
            title:         titre,
            notes:         notes
        )
        context.insert(plan)
        try? context.save()
        charger(context: context)
    }

    // MARK: - Suppression

    func supprimer(_ plan: MealPlan, context: ModelContext) {
        context.delete(plan)
        try? context.save()
        charger(context: context)
    }

    // MARK: - Navigation semaine

    func semainePrecedente(context: ModelContext) {
        if let precedente = Calendar.current.date(byAdding: .day, value: -7, to: semaineCourante) {
            semaineCourante = precedente
            charger(context: context)
        }
    }

    func semaineSuivante(context: ModelContext) {
        if let suivante = Calendar.current.date(byAdding: .day, value: 7, to: semaineCourante) {
            semaineCourante = suivante
            charger(context: context)
        }
    }

    // MARK: - Génération IA

    func genererAvecIA(service: ClaudeAIService, profil: UserProfile, context: ModelContext) async {
        guard profil.aUneCleAPI else { return }

        isGenerating = true
        defer { isGenerating = false }

        let contexte = ContexteNutritionnel(
            prenom:            profil.prenom,
            objectifCalorique: profil.objectifCalorique,
            objectifProteines: profil.objectifProteines,
            objectifGlucides:  profil.objectifGlucides,
            objectifLipides:   profil.objectifLipides,
            resumeSemaine:     "Génération d'un nouveau plan",
            tendancePoids:     "",
            dernierPoids:      0
        )

        let plan = await service.genererPlanRepas(contexte: contexte, apiKey: profil.claudeAPIKey)
        planGenere = plan ?? "Impossible de générer le plan. Vérifiez votre connexion."
        showPlanIA = true
    }

    var labelSemaine: String {
        let fin = Calendar.current.date(byAdding: .day, value: 6, to: semaineCourante) ?? semaineCourante
        return "\(semaineCourante.formatCourt) – \(fin.formatCourt)"
    }
}

// MARK: - Extension Date pour début de semaine

extension Date {
    var debutDeSemaine: Date {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Lundi
        return cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) ?? self
    }
}
