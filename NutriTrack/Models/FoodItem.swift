import Foundation
import SwiftData

@Model
class FoodItem {
    var barcode: String = ""
    var name: String = ""
    var brand: String = ""
    var calories: Double = 0.0        // kcal pour 100g
    var proteins: Double = 0.0
    var carbohydrates: Double = 0.0
    var fats: Double = 0.0
    var fiber: Double = 0.0
    var sugar: Double = 0.0
    var sodium: Double = 0.0
    var servingSize: Double = 100.0
    var servingUnit: String = "g"
    var imageURL: String = ""
    var source: String = "OpenFoodFacts"
    var lastUpdated: Date = Date()
    var isFavorite: Bool = false
    var dateLastConsumed: Date? = nil

    @Relationship(deleteRule: .cascade) var entries: [FoodEntry] = []

    init(
        barcode: String = "",
        name: String,
        brand: String = "",
        calories: Double = 0,
        proteins: Double = 0,
        carbohydrates: Double = 0,
        fats: Double = 0,
        fiber: Double = 0,
        sugar: Double = 0,
        sodium: Double = 0,
        servingSize: Double = 100,
        servingUnit: String = "g",
        imageURL: String = "",
        source: String = "OpenFoodFacts"
    ) {
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.calories = calories
        self.proteins = proteins
        self.carbohydrates = carbohydrates
        self.fats = fats
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.imageURL = imageURL
        self.source = source
        self.lastUpdated = Date()
    }

    // MARK: - Calcul pour une quantité donnée

    func calories(pour quantite: Double) -> Double {
        calories * quantite / 100.0
    }

    func proteins(pour quantite: Double) -> Double {
        proteins * quantite / 100.0
    }

    func carbs(pour quantite: Double) -> Double {
        carbohydrates * quantite / 100.0
    }

    func fats(pour quantite: Double) -> Double {
        fats * quantite / 100.0
    }

    /// Résumé nutritionnel affiché dans les listes
    var resumeNutritionnel: String {
        "\(calories.arrondi(0)) kcal · P: \(proteins.arrondi(1))g · G: \(carbohydrates.arrondi(1))g · L: \(fats.arrondi(1))g"
    }

    var nomComplet: String {
        brand.isEmpty ? name : "\(name) — \(brand)"
    }
}
