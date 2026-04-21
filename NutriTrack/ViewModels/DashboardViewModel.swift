import Foundation
import SwiftData
import Observation

@Observable
class DashboardViewModel {

    var bilan: NutritionCalculator.BilanJour?
    var calories7Jours: [(date: Date, calories: Double)] = []
    var caloriesBruleesAujourdhui: Double = 0   // HealthKit
    var caloriesBruleesActivites: Double = 0    // activités manuelles
    var totalCaloriesBrulees: Double { caloriesBruleesAujourdhui + caloriesBruleesActivites }
    var pasAujourdhui: Double = 0
    var isLoadingHealthKit = false

    // Dernières métriques corporelles
    var dernierPoids: Double = 0
    var dernierIMC: Double = 0
    var derniereMasseGrasse: Double = 0

    // MARK: - Plan nutrition (Sprint 2)

    var currentDayContext: DayContext?
    var currentTarget: MacroTarget?
    var consumedKcal: Int = 0
    var consumedProteinG: Int = 0
    var suggestedTemplates: [MealTemplate] = []

    // MARK: - Chargement du bilan du jour

    func charger(context: ModelContext, profil: UserProfile?) {
        chargerBilanDuJour(context: context, profil: profil)
        chargerHistorique7Jours(context: context, profileID: profil?.profileID.uuidString ?? "")
        chargerDerniereMetrique(context: context, profileID: profil?.profileID.uuidString ?? "")
        chargerCaloriesActivites(context: context, profileID: profil?.profileID.uuidString ?? "")
    }

    private func chargerCaloriesActivites(context: ModelContext, profileID: String) {
        guard !profileID.isEmpty else { return }
        let debut = Date().debutDeJour
        let fin   = Date().finDeJour
        let pid   = profileID
        let descriptor = FetchDescriptor<ActivityEntry>(
            predicate: #Predicate<ActivityEntry> {
                $0.date >= debut && $0.date <= fin && $0.profileID == pid
            }
        )
        let activites = (try? context.fetch(descriptor)) ?? []
        caloriesBruleesActivites = activites.reduce(0) { $0 + $1.caloriesBurned }
    }

    private func chargerBilanDuJour(context: ModelContext, profil: UserProfile?) {
        guard let profil else { bilan = nil; return }
        let aujourd = Date()
        let debut = aujourd.debutDeJour
        let fin   = aujourd.finDeJour
        let pid   = profil.profileID.uuidString

        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> {
                $0.date >= debut && $0.date <= fin && $0.profileID == pid
            }
        )
        let entries = (try? context.fetch(descriptor)) ?? []
        bilan = NutritionCalculator.bilan(entries: entries, profil: profil)
    }

    private func chargerHistorique7Jours(context: ModelContext, profileID: String) {
        var resultats: [(date: Date, calories: Double)] = []
        let pid = profileID

        for i in 0..<7 {
            guard let jour = Calendar.current.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let debut = jour.debutDeJour
            let fin   = jour.finDeJour

            let descriptor = FetchDescriptor<FoodEntry>(
                predicate: #Predicate<FoodEntry> {
                    $0.date >= debut && $0.date <= fin && $0.profileID == pid
                }
            )
            let entries = (try? context.fetch(descriptor)) ?? []
            let totalCal = entries.reduce(0) { $0 + $1.calories }
            resultats.append((date: jour, calories: totalCal))
        }

        calories7Jours = resultats.reversed()
    }

    private func chargerDerniereMetrique(context: ModelContext, profileID: String) {
        guard !profileID.isEmpty else { return }
        let pid = profileID
        var descriptor = FetchDescriptor<BodyMetric>(
            predicate: #Predicate<BodyMetric> { $0.profileID == pid },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let derniere = (try? context.fetch(descriptor))?.first else { return }
        dernierPoids       = derniere.weight
        dernierIMC         = derniere.bmi
        derniereMasseGrasse = derniere.bodyFatPercentage
    }

    // MARK: - HealthKit

    func chargerDonneesHealthKit(service: HealthKitService) async {
        guard service.isAuthorized else { return }

        isLoadingHealthKit = true
        defer { isLoadingHealthKit = false }

        async let cal = service.lireCaloriesBrulees()
        async let pas = service.lirePasDuJour()

        caloriesBruleesAujourdhui = await cal
        pasAujourdhui = await pas
    }

    // MARK: - Plan nutrition (Sprint 2)

    /// Appelée à l'ouverture du Dashboard pour charger/créer le DayContext du jour.
    @MainActor
    func chargerPlanNutrition(context: ModelContext, profileID: String) {
        guard !profileID.isEmpty else {
            currentDayContext = nil
            currentTarget = nil
            suggestedTemplates = []
            consumedKcal = 0
            consumedProteinG = 0
            return
        }

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        let pid = profileID

        // Fetch DayContext existant pour aujourd'hui
        let descriptor = FetchDescriptor<DayContext>(
            predicate: #Predicate<DayContext> {
                $0.profileID == pid && $0.date >= today && $0.date < tomorrow
            }
        )
        if let existing = try? context.fetch(descriptor).first {
            currentDayContext = existing
        } else {
            currentDayContext = nil
        }

        // Fetch target si DayContext existe
        if let ctx = currentDayContext {
            let dayTypeRaw = ctx.dayType
            let targetDescriptor = FetchDescriptor<MacroTarget>(
                predicate: #Predicate<MacroTarget> {
                    $0.profileID == pid && $0.dayType == dayTypeRaw
                }
            )
            currentTarget = try? context.fetch(targetDescriptor).first
        } else {
            currentTarget = nil
        }

        // Suggested templates selon l'heure
        let mealType = suggestedMealType(at: Date())
        let mealTypeRaw = mealType.rawValue
        let templateDescriptor = FetchDescriptor<MealTemplate>(
            predicate: #Predicate<MealTemplate> {
                $0.profileID == pid && $0.isActive == true && $0.mealType == mealTypeRaw
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        suggestedTemplates = (try? context.fetch(templateDescriptor)) ?? []

        // Recalculer consommation du jour
        recalculerConsommation(context: context, profileID: profileID)
    }

    /// Sélectionne (ou crée) le DayType pour aujourd'hui. Unicité par (profileID, date).
    @MainActor
    func selectDayType(_ type: DayType, context: ModelContext, profileID: String) {
        guard !profileID.isEmpty else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        let pid = profileID
        let descriptor = FetchDescriptor<DayContext>(
            predicate: #Predicate<DayContext> {
                $0.profileID == pid && $0.date >= today && $0.date < tomorrow
            }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.dayType = type.rawValue
            currentDayContext = existing
        } else {
            let newCtx = DayContext(
                profileID: profileID,
                date: Date(),
                dayType: type
            )
            context.insert(newCtx)
            currentDayContext = newCtx
        }

        try? context.save()

        // Recharger target
        let dayTypeRaw = type.rawValue
        let targetDescriptor = FetchDescriptor<MacroTarget>(
            predicate: #Predicate<MacroTarget> {
                $0.profileID == pid && $0.dayType == dayTypeRaw
            }
        )
        currentTarget = try? context.fetch(targetDescriptor).first
    }

    /// Logue un template en créant N FoodEntry (copie des valeurs pour survivre à une modification du template).
    @MainActor
    func logTemplate(_ template: MealTemplate, context: ModelContext, profileID: String) {
        guard !profileID.isEmpty else { return }

        let mealTypeFR = convertToFrMealType(template.mealType)
        let now = Date()

        for item in (template.items ?? []).sorted(by: { $0.orderIndex < $1.orderIndex }) {
            // On crée le FoodEntry sans FoodItem (copie des valeurs calculées directement)
            let entry = FoodEntry(
                date: now,
                mealType: mealTypeFR,
                quantity: item.quantityG,
                foodItem: nil
            )
            entry.profileID = profileID
            // Copie directe des macros (pas de FoodItem → on bypass calculerMacros)
            entry.calories      = Double(item.kcal)
            entry.proteins      = item.proteinG
            entry.carbohydrates = item.carbsG
            entry.fats          = item.fatG
            context.insert(entry)
        }

        try? context.save()
        recalculerConsommation(context: context, profileID: profileID)
    }

    /// Heuristique "quel type de repas selon l'heure courante".
    func suggestedMealType(at date: Date) -> TemplateMealType {
        let h = Calendar.current.component(.hour, from: date)
        switch h {
        case 5...10: return .breakfast
        case 11...14: return .lunch
        case 15...17: return .snack
        case 18...22: return .dinner
        default: return .breakfast
        }
    }

    /// Convertit la rawValue de TemplateMealType en string attendue par FoodEntry.mealType
    /// (raws de l'enum MealType français : petit_dejeuner, dejeuner, diner, collation)
    private func convertToFrMealType(_ rawTemplate: String) -> String {
        switch rawTemplate {
        case "breakfast": return "petit_dejeuner"
        case "lunch":     return "dejeuner"
        case "dinner":    return "diner"
        case "snack":     return "collation"
        default:          return "dejeuner"
        }
    }

    @MainActor
    private func recalculerConsommation(context: ModelContext, profileID: String) {
        guard !profileID.isEmpty else {
            consumedKcal = 0
            consumedProteinG = 0
            return
        }
        let pid = profileID
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Date().finDeJour
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> {
                $0.profileID == pid && $0.date >= startOfDay && $0.date <= endOfDay
            }
        )
        let entries = (try? context.fetch(descriptor)) ?? []
        consumedKcal = Int(entries.reduce(0.0) { $0 + $1.calories })
        consumedProteinG = Int(entries.reduce(0.0) { $0 + $1.proteins })
    }
}
