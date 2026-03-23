import Foundation

struct NutritionCalculator {

    // MARK: - TDEE (Mifflin-St Jeor)

    static func bmr(poids: Double, taille: Double, age: Int, sexe: String) -> Double {
        let base = (10 * poids) + (6.25 * taille) - (5.0 * Double(age))
        return sexe == "homme" ? base + 5 : base - 161
    }

    static func tdee(poids: Double, taille: Double, age: Int, sexe: String, niveauActivite: String) -> Double {
        let bmr = bmr(poids: poids, taille: taille, age: age, sexe: sexe)
        let facteur = NiveauActivite(rawValue: niveauActivite)?.facteur ?? 1.55
        return bmr * facteur
    }

    static func tdee(profil: UserProfile, poids: Double) -> Double {
        tdee(
            poids: poids,
            taille: profil.taille,
            age: profil.age,
            sexe: profil.sexe,
            niveauActivite: profil.niveauActivite
        )
    }

    // MARK: - IMC

    static func imc(poids: Double, taille: Double) -> Double {
        guard taille > 0 else { return 0 }
        let tailleM = taille / 100.0
        return poids / (tailleM * tailleM)
    }

    // MARK: - Macros cibles (30% P / 40% G / 30% L)

    struct MacrosCibles {
        let proteines: Double  // g
        let glucides: Double   // g
        let lipides: Double    // g
    }

    static func macrosCibles(calories: Double) -> MacrosCibles {
        let proteines  = (calories * 0.30) / 4.0  // 4 kcal/g
        let glucides   = (calories * 0.40) / 4.0  // 4 kcal/g
        let lipides    = (calories * 0.30) / 9.0  // 9 kcal/g
        return MacrosCibles(proteines: proteines, glucides: glucides, lipides: lipides)
    }

    // MARK: - Bilan journalier

    struct BilanJour {
        let caloriesConsommees: Double
        let caloriesObjectif: Double
        let proteinesConsommees: Double
        let proteinesObjectif: Double
        let glucidesConsommes: Double
        let glucidesObjectif: Double
        let lipidesConsommes: Double
        let lipidesObjectif: Double

        var caloriesRestantes: Double {
            max(caloriesObjectif - caloriesConsommees, 0)
        }

        var progressionCalories: Double {
            caloriesConsommees.progression(sur: caloriesObjectif)
        }

        var progressionProteines: Double {
            proteinesConsommees.progression(sur: proteinesObjectif)
        }

        var progressionGlucides: Double {
            glucidesConsommes.progression(sur: glucidesObjectif)
        }

        var progressionLipides: Double {
            lipidesConsommes.progression(sur: lipidesObjectif)
        }

        var estObjectifAtteint: Bool {
            caloriesConsommees >= caloriesObjectif * 0.9 &&
            caloriesConsommees <= caloriesObjectif * 1.1
        }
    }

    static func bilan(
        entries: [FoodEntry],
        profil: UserProfile
    ) -> BilanJour {
        let totalCal = entries.reduce(0) { $0 + $1.calories }
        let totalProt = entries.reduce(0) { $0 + $1.proteins }
        let totalGluc = entries.reduce(0) { $0 + $1.carbohydrates }
        let totalLip  = entries.reduce(0) { $0 + $1.fats }

        return BilanJour(
            caloriesConsommees:  totalCal,
            caloriesObjectif:    profil.objectifCalorique,
            proteinesConsommees: totalProt,
            proteinesObjectif:   profil.objectifProteines,
            glucidesConsommes:   totalGluc,
            glucidesObjectif:    profil.objectifGlucides,
            lipidesConsommes:    totalLip,
            lipidesObjectif:     profil.objectifLipides
        )
    }

    // MARK: - Calories brûlées par activité (estimation MET simplifiée)

    static func caloriesBrulees(activite: String, dureeMin: Int, poidsKg: Double) -> Double {
        let met: Double
        switch activite.lowercased() {
        case let a where a.contains("course") || a.contains("running"):
            met = 8.0
        case let a where a.contains("marche") || a.contains("walk"):
            met = 3.5
        case let a where a.contains("muscu") || a.contains("gym"):
            met = 5.0
        case let a where a.contains("vélo") || a.contains("cycling"):
            met = 7.0
        case let a where a.contains("natation") || a.contains("swim"):
            met = 7.0
        case let a where a.contains("yoga"):
            met = 2.5
        default:
            met = 4.0
        }
        return met * poidsKg * (Double(dureeMin) / 60.0)
    }
}
