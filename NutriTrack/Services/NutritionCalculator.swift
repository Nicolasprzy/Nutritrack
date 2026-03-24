import Foundation
import SwiftUI

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
        tdee(poids: poids, taille: profil.taille, age: profil.age,
             sexe: profil.sexe, niveauActivite: profil.niveauActivite)
    }

    // MARK: - IMC

    static func imc(poids: Double, taille: Double) -> Double {
        guard taille > 0 else { return 0 }
        let tailleM = taille / 100.0
        return poids / (tailleM * tailleM)
    }

    // MARK: - Jalon de transformation

    struct JalonTransformation: Identifiable {
        let id = UUID()
        let titre: String
        let detail: String
        let dateEstimee: Date
        let icone: String
        let couleur: Color
    }

    // MARK: - Objectifs de transformation

    struct ObjectifsCaloriques {
        let tdee: Double
        let objectifTransformation: Double
        let ajustement: Double
        let typeTransformation: String
        let semainesRestantes: Int
        let kgEstimes: Double
        // Approche
        let approche: ApprocheTransformation
        let perteSemaineEstimee: Double   // kg/semaine (positif = perte, négatif = gain)
        let jalons: [JalonTransformation]

        var estDeficit: Bool  { ajustement < -10 }
        var estSurplus: Bool  { ajustement > 10 }

        var couleurAjustement: Color {
            if estDeficit { return .blue }
            if estSurplus { return .orange }
            return .secondary
        }
        var iconeAjustement: String {
            if estDeficit { return "arrow.down.circle.fill" }
            if estSurplus { return "arrow.up.circle.fill" }
            return "equal.circle.fill"
        }
    }

    /// Calcule les objectifs caloriques de transformation, les macros, la perte/gain hebdomadaire
    /// et les jalons de progression en fonction du profil et de son `approcheTransformation`.
    static func objectifsCaloriques(profil: UserProfile) -> ObjectifsCaloriques {
        let tdeeVal  = tdee(profil: profil, poids: profil.poidsActuel)
        // Plancher clinique strict : 1 500 kcal homme / 1 200 kcal femme (NIH / ISSN).
        // On n'utilise pas BMR × 1.1 — ce facteur faisait converger "agressive" et
        // "très agressive" vers la même valeur pour la majorité des profils.
        let seuilMin = profil.sexe == "homme" ? 1_500.0 : 1_200.0
        let approche = profil.approcheEnum

        let semaines = max(0, Calendar.current.dateComponents(
            [.weekOfYear], from: Date(), to: profil.dateObjectif
        ).weekOfYear ?? 0)

        guard !profil.silhouetteObjectif.isEmpty, semaines > 0 else {
            return ObjectifsCaloriques(
                tdee: tdeeVal, objectifTransformation: tdeeVal,
                ajustement: 0, typeTransformation: "maintenance",
                semainesRestantes: semaines, kgEstimes: 0,
                approche: approche, perteSemaineEstimee: 0, jalons: []
            )
        }

        let indexActuel = SilhouetteObjectif(rawValue: profil.silhouetteActuelle)?.index ?? 3
        let indexCible  = SilhouetteObjectif(rawValue: profil.silhouetteObjectif)?.index ?? 3
        let distance    = abs(indexActuel - indexCible)
        let kgEstimes   = Double(distance) * 4.5

        let ajustement: Double
        let type: String
        let perteSemaine: Double
        let isDeficit: Bool

        if indexCible < indexActuel {
            // Perte de masse grasse — applique le déficit complet de l'approche choisie.
            // On ne plafonne plus au "brut" (déficit minimum pour atteindre l'objectif à temps)
            // car cela rendait toutes les approches identiques pour les petits objectifs.
            // L'utilisateur atteindra son objectif plus tôt avec une approche agressive.
            ajustement   = -approche.deficitMaxKcal
            type         = "déficit"
            perteSemaine = approche.deficitMaxKcal * 7 / 7_700
            isDeficit    = true
        } else if indexCible > indexActuel {
            // Prise de masse — même logique : applique le surplus complet de l'approche.
            ajustement   = approche.surplusMaxKcal
            type         = "surplus"
            perteSemaine = approche.surplusMaxKcal * 7 / 5_000
            isDeficit    = false
        } else {
            ajustement = 0; type = "maintenance"; perteSemaine = 0; isDeficit = true
        }

        let objectif = max(seuilMin, (tdeeVal + ajustement).rounded())
        let jalons = calculerJalons(
            poidsKg: profil.poidsActuel,
            perteSemaineKg: perteSemaine,
            isDeficit: isDeficit
        )

        return ObjectifsCaloriques(
            tdee: tdeeVal, objectifTransformation: objectif,
            ajustement: ajustement, typeTransformation: type,
            semainesRestantes: semaines, kgEstimes: kgEstimes,
            approche: approche, perteSemaineEstimee: perteSemaine, jalons: jalons
        )
    }

    // MARK: - Jalons

    static func calculerJalons(poidsKg: Double, perteSemaineKg: Double, isDeficit: Bool) -> [JalonTransformation] {
        guard perteSemaineKg > 0 else { return [] }

        func dateApresKg(_ kg: Double) -> Date {
            let semaines = kg / perteSemaineKg
            return Calendar.current.date(byAdding: .day, value: max(7, Int(semaines * 7)), to: Date()) ?? Date()
        }

        if isDeficit {
            return [
                JalonTransformation(
                    titre: "Changements internes",
                    detail: "Métabolisme qui s'adapte, meilleure hydratation cellulaire.",
                    dateEstimee: Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date(),
                    icone: "waveform.path.ecg",
                    couleur: .teal
                ),
                JalonTransformation(
                    titre: "Premiers effets ressentis",
                    detail: "Énergie et humeur améliorées. Vêtements légèrement moins serrés.",
                    dateEstimee: dateApresKg(poidsKg * 0.02),
                    icone: "bolt.circle.fill",
                    couleur: .blue
                ),
                JalonTransformation(
                    titre: "Visible dans le miroir",
                    detail: "Visage plus défini, silhouette qui s'affine nettement.",
                    dateEstimee: dateApresKg(poidsKg * 0.04),
                    icone: "figure.stand",
                    couleur: Color.nutriGreen
                ),
                JalonTransformation(
                    titre: "Remarqué par l'entourage",
                    detail: "Les changements deviennent évidents pour votre entourage.",
                    dateEstimee: dateApresKg(poidsKg * 0.06),
                    icone: "person.2.fill",
                    couleur: .orange
                ),
                JalonTransformation(
                    titre: "Transformation frappante",
                    detail: "Corps recomposé — silhouette transformée, énergie au top.",
                    dateEstimee: dateApresKg(poidsKg * 0.09),
                    icone: "star.fill",
                    couleur: .yellow
                ),
            ]
        } else {
            return [
                JalonTransformation(
                    titre: "Adaptation musculaire",
                    detail: "Le corps s'adapte à l'apport accru et aux entraînements.",
                    dateEstimee: Calendar.current.date(byAdding: .weekOfYear, value: 2, to: Date()) ?? Date(),
                    icone: "waveform.path.ecg",
                    couleur: .teal
                ),
                JalonTransformation(
                    titre: "Force accrue",
                    detail: "Gains de force notables, récupération améliorée entre les séances.",
                    dateEstimee: Calendar.current.date(byAdding: .weekOfYear, value: 4, to: Date()) ?? Date(),
                    icone: "dumbbell.fill",
                    couleur: .blue
                ),
                JalonTransformation(
                    titre: "Volume visible",
                    detail: "Muscles plus volumineux et définis dans le miroir.",
                    dateEstimee: Calendar.current.date(byAdding: .weekOfYear, value: 10, to: Date()) ?? Date(),
                    icone: "figure.arms.open",
                    couleur: Color.nutriGreen
                ),
                JalonTransformation(
                    titre: "Silhouette transformée",
                    detail: "Transformation nette et remarquable par l'entourage.",
                    dateEstimee: Calendar.current.date(byAdding: .weekOfYear, value: 20, to: Date()) ?? Date(),
                    icone: "star.fill",
                    couleur: .orange
                ),
            ]
        }
    }

    // MARK: - Macros cibles

    struct MacrosCibles {
        let proteines: Double  // g
        let glucides: Double   // g
        let lipides: Double    // g
    }

    /// Répartition standard 30/40/30 (maintenance ou fallback).
    static func macrosCibles(calories: Double) -> MacrosCibles {
        let proteines = (calories * 0.30) / 4.0
        let glucides  = (calories * 0.40) / 4.0
        let lipides   = (calories * 0.30) / 9.0
        return MacrosCibles(proteines: proteines, glucides: glucides, lipides: lipides)
    }

    /// Répartition adaptée à la transformation — tient compte de l'approche choisie.
    static func macrosCiblesTransformation(
        calories: Double,
        poidsKg: Double,
        ajustement: Double,
        approche: ApprocheTransformation = .normale
    ) -> MacrosCibles {
        if ajustement < -10 {
            // Déficit : protéines élevées selon l'approche pour préserver le muscle
            let p = min(poidsKg * approche.proteinesGParKg, calories * 0.42 / 4).rounded()
            let l = (calories * 0.27 / 9).rounded()
            let g = max(50, ((calories - p * 4 - l * 9) / 4).rounded())
            return MacrosCibles(proteines: p, glucides: g, lipides: l)
        } else if ajustement > 10 {
            // Surplus : glucides élevés pour la performance et la récupération
            let p = (poidsKg * approche.proteinesGParKg).rounded()
            let l = (calories * 0.25 / 9).rounded()
            let g = max(100, ((calories - p * 4 - l * 9) / 4).rounded())
            return MacrosCibles(proteines: p, glucides: g, lipides: l)
        } else {
            return macrosCibles(calories: calories)
        }
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

        var caloriesRestantes: Double { max(caloriesObjectif - caloriesConsommees, 0) }
        var progressionCalories: Double { caloriesConsommees.progression(sur: caloriesObjectif) }
        var progressionProteines: Double { proteinesConsommees.progression(sur: proteinesObjectif) }
        var progressionGlucides: Double { glucidesConsommes.progression(sur: glucidesObjectif) }
        var progressionLipides: Double { lipidesConsommes.progression(sur: lipidesObjectif) }
        var estObjectifAtteint: Bool {
            caloriesConsommees >= caloriesObjectif * 0.9 &&
            caloriesConsommees <= caloriesObjectif * 1.1
        }
    }

    static func bilan(entries: [FoodEntry], profil: UserProfile) -> BilanJour {
        let totalCal  = entries.reduce(0) { $0 + $1.calories }
        let totalProt = entries.reduce(0) { $0 + $1.proteins }
        let totalGluc = entries.reduce(0) { $0 + $1.carbohydrates }
        let totalLip  = entries.reduce(0) { $0 + $1.fats }
        let obj = objectifsCaloriques(profil: profil)
        let mac = macrosCiblesTransformation(
            calories: obj.objectifTransformation,
            poidsKg:  profil.poidsActuel,
            ajustement: obj.ajustement,
            approche: profil.approcheEnum
        )
        return BilanJour(
            caloriesConsommees:  totalCal,
            caloriesObjectif:    obj.objectifTransformation,
            proteinesConsommees: totalProt,
            proteinesObjectif:   mac.proteines,
            glucidesConsommes:   totalGluc,
            glucidesObjectif:    mac.glucides,
            lipidesConsommes:    totalLip,
            lipidesObjectif:     mac.lipides
        )
    }

    // MARK: - Calories brûlées par activité (MET)

    static func caloriesBrulees(activite: String, dureeMin: Int, poidsKg: Double) -> Double {
        let met: Double
        switch activite.lowercased() {
        case let a where a.contains("course") || a.contains("running"): met = 8.0
        case let a where a.contains("marche") || a.contains("walk"):    met = 3.5
        case let a where a.contains("muscu")  || a.contains("gym"):     met = 5.0
        case let a where a.contains("vélo")   || a.contains("cycling"): met = 7.0
        case let a where a.contains("natation") || a.contains("swim"):  met = 7.0
        case let a where a.contains("yoga"):                             met = 2.5
        default: met = 4.0
        }
        return met * poidsKg * (Double(dureeMin) / 60.0)
    }
}
