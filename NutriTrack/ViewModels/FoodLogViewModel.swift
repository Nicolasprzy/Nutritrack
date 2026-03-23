import Foundation
import SwiftData
import Observation

@Observable
class FoodLogViewModel {

    var dateSelectionnee: Date = Date()
    var entriesParRepas: [String: [FoodEntry]] = [:]
    var showAddFood: Bool = false
    var mealTypeEnCours: String = "dejeuner"
    var isLoading: Bool = false

    // MARK: - Chargement

    func charger(context: ModelContext) {
        let debut = dateSelectionnee.debutDeJour
        let fin   = dateSelectionnee.finDeJour

        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> { $0.date >= debut && $0.date <= fin },
            sortBy: [SortDescriptor(\.date)]
        )

        let toutes = (try? context.fetch(descriptor)) ?? []

        var grouped: [String: [FoodEntry]] = [:]
        for type in MealType.allCases {
            grouped[type.rawValue] = toutes.filter { $0.mealType == type.rawValue }
        }
        entriesParRepas = grouped
    }

    // MARK: - Totaux par repas

    func caloriesRepas(_ type: MealType) -> Double {
        (entriesParRepas[type.rawValue] ?? []).reduce(0) { $0 + $1.calories }
    }

    func totalJour() -> (calories: Double, proteines: Double, glucides: Double, lipides: Double) {
        let toutes = entriesParRepas.values.flatMap { $0 }
        return (
            calories:  toutes.reduce(0) { $0 + $1.calories },
            proteines: toutes.reduce(0) { $0 + $1.proteins },
            glucides:  toutes.reduce(0) { $0 + $1.carbohydrates },
            lipides:   toutes.reduce(0) { $0 + $1.fats }
        )
    }

    // MARK: - Ajout d'une entrée

    func ajouterEntree(
        foodItem: FoodItem,
        quantite: Double,
        mealType: String,
        context: ModelContext
    ) {
        let entry = FoodEntry(
            date:     dateSelectionnee,
            mealType: mealType,
            quantity: quantite,
            foodItem: foodItem
        )
        entry.calculerMacros()
        context.insert(entry)

        // Mettre à jour lastUpdated du FoodItem
        foodItem.lastUpdated = Date()

        try? context.save()
        charger(context: context)
    }

    // MARK: - Suppression

    func supprimerEntree(_ entry: FoodEntry, context: ModelContext) {
        context.delete(entry)
        try? context.save()
        charger(context: context)
    }

    // MARK: - Navigation date

    func jourSuivant(context: ModelContext) {
        if let demain = Calendar.current.date(byAdding: .day, value: 1, to: dateSelectionnee) {
            if demain <= Date() {
                dateSelectionnee = demain
                charger(context: context)
            }
        }
    }

    func jourPrecedent(context: ModelContext) {
        if let hier = Calendar.current.date(byAdding: .day, value: -1, to: dateSelectionnee) {
            dateSelectionnee = hier
            charger(context: context)
        }
    }

    var estAujourdhui: Bool {
        Calendar.current.isDateInToday(dateSelectionnee)
    }
}
