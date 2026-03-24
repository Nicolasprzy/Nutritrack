import Foundation

// MARK: - Helpers JSON nonisolés (utilisés par UserPlan @Model)

func decodePlanNutrition(from json: String) -> PlanNutritionnel? {
    guard !json.isEmpty, let data = json.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(PlanNutritionnel.self, from: data)
}

func decodePlanEntrainement(from json: String) -> PlanEntrainement? {
    guard !json.isEmpty, let data = json.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(PlanEntrainement.self, from: data)
}

func encodePlanNutrition(_ plan: PlanNutritionnel) -> String {
    guard let data = try? JSONEncoder().encode(plan),
          let json = String(data: data, encoding: .utf8) else { return "" }
    return json
}

func encodePlanEntrainement(_ plan: PlanEntrainement) -> String {
    guard let data = try? JSONEncoder().encode(plan),
          let json = String(data: data, encoding: .utf8) else { return "" }
    return json
}

// MARK: - Plan Nutritionnel

struct PlanNutritionnel: Codable {
    var caloriesJournalieres: Double
    var proteinesG: Double
    var glucidesG: Double
    var lipidesG: Double
    var recommandations: [String]
    var repasTypes: [RepasTypePlan]
}

struct RepasTypePlan: Codable, Identifiable {
    var id: String
    var nom: String
    var caloriesCibles: Double
    var suggestions: [String]
}

// MARK: - Plan Entraînement

struct PlanEntrainement: Codable {
    var semaineType: [JourEntrainement]
    var recommandations: [String]
    var noteGenerale: String
}

struct JourEntrainement: Codable, Identifiable {
    var id: String
    var jourLabel: String            // "Lundi", "Mercredi"…
    var typeSeance: String           // "Force", "Cardio", "Repos", "HIIT"
    var exercices: [ExercicePlan]
    var dureeMinutes: Int
    var seanceFaite: Bool = false
    var dateFaite: String? = nil     // ISO8601

    var estJourRepos: Bool {
        typeSeance.lowercased() == "repos"
    }

    var iconeSeance: String {
        switch typeSeance.lowercased() {
        case "force":                return "dumbbell.fill"
        case "cardio":               return "heart.fill"
        case "hiit":                 return "bolt.fill"
        case "mobilite", "mobilité": return "figure.mind.and.body"
        default:                     return "moon.fill"
        }
    }
}

struct ExercicePlan: Codable, Identifiable {
    var id: String
    var nom: String
    var series: Int
    var repetitions: String          // "8-12" ou "30 sec" ou "AMRAP"
    var reposSecondes: Int
    var wgerId: Int?                 // lien vers Exercise (Wger)
    var musclesCibles: [String]
    var notes: String?
}
