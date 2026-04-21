import Foundation
import SwiftData

/// Service de seeding du plan nutrition (cibles macro + templates de repas).
/// Idempotent via UserProfile.planSeeded.
@MainActor
enum NutritionPlanSeeder {

    /// Seed minimal : 4 MacroTarget (muscle/rest/trailLong/trailVeryLong) + 3 templates.
    /// Ne fait rien si `profile.planSeeded == true`.
    static func seedMinimalPlan(for profile: UserProfile, context: ModelContext) {
        guard !profile.planSeeded else { return }

        let profileID = profile.profileID.uuidString

        // --- MacroTargets ---
        let targets: [(DayType, Int, Int, Int, Int)] = [
            (.muscle,         2200, 200, 200, 75),
            (.rest,           1950, 180, 150, 70),
            (.trailLong,      2700, 200, 270, 80),
            (.trailVeryLong,  3000, 200, 330, 85)
        ]
        for (dayType, kcal, prot, carbs, fat) in targets {
            let t = MacroTarget(
                profileID: profileID,
                dayType: dayType.rawValue,
                kcal: kcal, protein: prot, carbs: carbs, fat: fat
            )
            context.insert(t)
        }

        // --- Template 1 : Petit-déjeuner type (fixed, 7j/7) ---
        let breakfast = MealTemplate(
            profileID: profileID,
            name: "Petit-déjeuner type",
            mealType: .breakfast,
            rotationTag: "fixed",
            dayOfWeekHint: "7j/7"
        )
        context.insert(breakfast)
        let breakfastItems: [(String, Double, Double, Double, Double, Int)] = [
            ("Fromage blanc 0%",       300, 24,  12,  0.6, 135),
            ("Blanc d'œuf liquide",    150, 17,  1,   0,   70),
            ("Flocons d'avoine",       80,  10,  48,  5.6, 304),
            ("Myrtilles",              100, 0.7, 14,  0.3, 57),
            ("Café noir",              0,   0,   0,   0,   5)
        ]
        for (idx, item) in breakfastItems.enumerated() {
            let (name, qty, p, c, f, kcal) = item
            let i = MealTemplateItem(
                foodName: name, quantityG: qty,
                proteinG: p, carbsG: c, fatG: f, kcal: kcal,
                orderIndex: idx
            )
            i.template = breakfast
            context.insert(i)
        }

        // --- Template 2 : Bowl poulet-lentilles-légumes (lunchA, Lun/Mar/Mer) ---
        let lunch = MealTemplate(
            profileID: profileID,
            name: "Bowl poulet-lentilles-légumes",
            mealType: .lunch,
            rotationTag: "lunchA",
            dayOfWeekHint: "Lun/Mar/Mer"
        )
        context.insert(lunch)
        let lunchItems: [(String, Double, Double, Double, Double, Int)] = [
            ("Blanc de poulet",          200, 46, 0,  3, 220),
            ("Lentilles corail cuites",  160, 14, 32, 1, 200),
            ("Légumes rôtis",            160, 3,  10, 2, 70),
            ("Concombre",                150, 1,  5,  0, 24),
            ("Huile d'olive",            5,   0,  0,  5, 44)
        ]
        for (idx, item) in lunchItems.enumerated() {
            let (name, qty, p, c, f, kcal) = item
            let i = MealTemplateItem(
                foodName: name, quantityG: qty,
                proteinG: p, carbsG: c, fatG: f, kcal: kcal,
                orderIndex: idx
            )
            i.template = lunch
            context.insert(i)
        }

        // --- Template 3 : Omelette-légumes (dinnerA, Lun/Jeu) ---
        let dinner = MealTemplate(
            profileID: profileID,
            name: "Omelette-légumes",
            mealType: .dinner,
            rotationTag: "dinnerA",
            dayOfWeekHint: "Lun/Jeu"
        )
        context.insert(dinner)
        let dinnerItems: [(String, Double, Double, Double, Double, Int)] = [
            ("Œufs entiers (3)",              150, 19,   1,   15,  210),
            ("Blanc d'œuf liquide",           100, 11,   0.7, 0,   47),
            ("Haricots verts surgelés",       250, 5,    15,  0.5, 88),
            ("Tomates",                       150, 1.4,  6,   0.3, 27),
            ("Huile d'olive",                 5,   0,    0,   5,   44)
        ]
        for (idx, item) in dinnerItems.enumerated() {
            let (name, qty, p, c, f, kcal) = item
            let i = MealTemplateItem(
                foodName: name, quantityG: qty,
                proteinG: p, carbsG: c, fatG: f, kcal: kcal,
                orderIndex: idx
            )
            i.template = dinner
            context.insert(i)
        }

        // --- Mark as seeded ---
        profile.planSeeded = true

        do {
            try context.save()
        } catch {
            print("NutritionPlanSeeder save error: \(error)")
        }
    }

    /// Reset : supprime tous les MacroTarget/MealTemplate/MealTemplateItem du profil
    /// puis remet planSeeded = false. Idempotent.
    @MainActor
    static func resetPlan(for profile: UserProfile, context: ModelContext) {
        let profileID = profile.profileID.uuidString

        // Delete MacroTargets
        let targetDescriptor = FetchDescriptor<MacroTarget>(
            predicate: #Predicate { $0.profileID == profileID }
        )
        if let targets = try? context.fetch(targetDescriptor) {
            for t in targets { context.delete(t) }
        }

        // Delete MealTemplates (cascade items via relationship)
        let templateDescriptor = FetchDescriptor<MealTemplate>(
            predicate: #Predicate { $0.profileID == profileID }
        )
        if let templates = try? context.fetch(templateDescriptor) {
            for t in templates { context.delete(t) }
        }

        profile.planSeeded = false

        try? context.save()
    }
}
