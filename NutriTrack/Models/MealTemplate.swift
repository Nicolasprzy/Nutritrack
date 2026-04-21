import Foundation
import SwiftData

@Model
final class MealTemplate {
    var id: UUID = UUID()
    var profileID: String = ""
    var name: String = ""
    var mealType: String = "breakfast"    // "breakfast" | "lunch" | "dinner" | "snack"
    var rotationTag: String?              // "fixed" | "lunchA" | "lunchB" | "lunchC" | "dinnerA"...
    var dayOfWeekHint: String?
    var isActive: Bool = true
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \MealTemplateItem.template)
    var items: [MealTemplateItem]? = []

    init(profileID: String, name: String, mealType: TemplateMealType, rotationTag: String? = nil, dayOfWeekHint: String? = nil) {
        self.id = UUID()
        self.profileID = profileID
        self.name = name
        self.mealType = mealType.rawValue
        self.rotationTag = rotationTag
        self.dayOfWeekHint = dayOfWeekHint
        self.isActive = true
        self.createdAt = Date()
        self.items = []
    }
}

@Model
final class MealTemplateItem {
    var id: UUID = UUID()
    var foodName: String = ""
    var quantityG: Double = 0
    var proteinG: Double = 0
    var carbsG: Double = 0
    var fatG: Double = 0
    var kcal: Int = 0
    var orderIndex: Int = 0

    var template: MealTemplate?

    init(foodName: String, quantityG: Double, proteinG: Double, carbsG: Double, fatG: Double, kcal: Int, orderIndex: Int) {
        self.id = UUID()
        self.foodName = foodName
        self.quantityG = quantityG
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.kcal = kcal
        self.orderIndex = orderIndex
    }
}

enum TemplateMealType: String, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .breakfast: return "Petit-déjeuner"
        case .lunch: return "Déjeuner"
        case .dinner: return "Dîner"
        case .snack: return "Collation"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "fork.knife"
        }
    }
}
