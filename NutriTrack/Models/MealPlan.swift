import Foundation
import SwiftData

@Model
class MealPlan {
    var weekStartDate: Date = Date()
    var dayOfWeek: Int = 0              // 0=lundi … 6=dimanche
    var mealType: String = "dejeuner"   // "petit_dejeuner", "dejeuner", "diner", "collation"
    var title: String = ""
    var notes: String = ""

    @Relationship(deleteRule: .nullify) var foods: [FoodItem] = []

    init(
        weekStartDate: Date = Date(),
        dayOfWeek: Int = 0,
        mealType: String = "dejeuner",
        title: String = "",
        notes: String = ""
    ) {
        self.weekStartDate = weekStartDate
        self.dayOfWeek = dayOfWeek
        self.mealType = mealType
        self.title = title
        self.notes = notes
    }

    var jourLabel: String {
        let jours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
        guard dayOfWeek >= 0 && dayOfWeek < jours.count else { return "?" }
        return jours[dayOfWeek]
    }

    var mealTypeEnum: MealType {
        MealType(rawValue: mealType) ?? .dejeuner
    }

    // Calories estimées depuis les aliments planifiés
    var caloriesEstimees: Double {
        foods.reduce(0) { $0 + $1.calories }
    }
}
