import Foundation
import SwiftData

@Model
class FoodEntry {
    var profileID: String = ""          // UUID du UserProfile propriétaire
    var date: Date = Date()
    var mealType: String = "dejeuner"   // "petit_dejeuner", "dejeuner", "diner", "collation"
    var quantity: Double = 100.0        // en grammes

    var foodItem: FoodItem?

    // Valeurs calculées stockées pour performance
    var calories: Double = 0.0
    var proteins: Double = 0.0
    var carbohydrates: Double = 0.0
    var fats: Double = 0.0

    init(
        date: Date = Date(),
        mealType: String = "dejeuner",
        quantity: Double = 100.0,
        foodItem: FoodItem? = nil
    ) {
        self.date = date
        self.mealType = mealType
        self.quantity = quantity
        self.foodItem = foodItem
        calculerMacros()
    }

    // MARK: - Calcul des macros

    func calculerMacros() {
        guard let item = foodItem else { return }
        let ratio = quantity / 100.0
        calories      = item.calories      * ratio
        proteins      = item.proteins      * ratio
        carbohydrates = item.carbohydrates * ratio
        fats          = item.fats          * ratio
    }

    var mealTypeEnum: MealType {
        MealType(rawValue: mealType) ?? .dejeuner
    }
}
