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

    // MARK: - Chargement (filtré par profil)

    func charger(context: ModelContext, profileID: String = "") {
        let debut = dateSelectionnee.debutDeJour
        let fin   = dateSelectionnee.finDeJour

        // Migration : si des enregistrements sans profileID existent, on les assigne
        // au profil courant (migration one-shot depuis v1)
        if !profileID.isEmpty {
            let orphelins = (try? context.fetch(FetchDescriptor<FoodEntry>(
                predicate: #Predicate<FoodEntry> { $0.profileID == "" }
            ))) ?? []
            if !orphelins.isEmpty {
                orphelins.forEach { $0.profileID = profileID }
                try? context.save()
            }
        }

        let pid = profileID
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> {
                $0.date >= debut && $0.date <= fin && $0.profileID == pid
            },
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
        profileID: String = "",
        context: ModelContext
    ) {
        let entry = FoodEntry(
            date:     dateSelectionnee,
            mealType: mealType,
            quantity: quantite,
            foodItem: foodItem
        )
        entry.profileID = profileID
        entry.calculerMacros()
        context.insert(entry)

        foodItem.lastUpdated = Date()

        try? context.save()
        charger(context: context, profileID: profileID)
    }

    // MARK: - Suppression

    func supprimerEntree(_ entry: FoodEntry, profileID: String = "", context: ModelContext) {
        context.delete(entry)
        try? context.save()
        charger(context: context, profileID: profileID)
    }

    // MARK: - Navigation date

    func jourSuivant(context: ModelContext, profileID: String = "") {
        if let demain = Calendar.current.date(byAdding: .day, value: 1, to: dateSelectionnee) {
            if demain <= Date() {
                dateSelectionnee = demain
                charger(context: context, profileID: profileID)
            }
        }
    }

    func jourPrecedent(context: ModelContext, profileID: String = "") {
        if let hier = Calendar.current.date(byAdding: .day, value: -1, to: dateSelectionnee) {
            dateSelectionnee = hier
            charger(context: context, profileID: profileID)
        }
    }

    var estAujourdhui: Bool {
        Calendar.current.isDateInToday(dateSelectionnee)
    }
}
