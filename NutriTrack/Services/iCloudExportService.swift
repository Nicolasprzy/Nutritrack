import Foundation
import SwiftData

// MARK: - Schémas d'export

struct ProfileExport: Codable {
    let version: Int
    let updatedAt: Date
    let profileID: String
    let prenom: String
    let sexe: String
    let dateNaissance: Date
    let tailleCm: Double
    let poidsActuelKg: Double
    let silhouetteActuelle: String
    let silhouetteObjectif: String
    let dateObjectif: Date
    let approche: String
    let niveauActivite: String
    let niveauSport: String
    let equipementSport: String
    let regimeAlimentaire: String
    let allergies: [String]
    let sportsAprecies: [String]
    let objectifs: ObjectifsExport
}

struct ObjectifsExport: Codable {
    let kcal: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let eauL: Double
}

struct DailyLogExport: Codable {
    let version: Int
    let updatedAt: Date
    let entries: [DayExport]
}

struct DayExport: Codable {
    let date: Date
    let meals: [MealExport]
    let dailyTotals: MacrosExport
}

struct MealExport: Codable {
    let id: String
    let loggedAt: Date
    let mealType: String
    let items: [FoodItemExport]
    let totals: MacrosExport
}

struct FoodItemExport: Codable {
    let name: String
    let quantityG: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let kcal: Double
}

struct MacrosExport: Codable {
    let kcal: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
}

struct BodyMetricsExport: Codable {
    let version: Int
    let updatedAt: Date
    let entries: [BodyMetricExport]
}

struct BodyMetricExport: Codable {
    let date: Date
    let weightKg: Double
    let bmi: Double
    let bodyFatPct: Double
    let waistCm: Double
    let hipsCm: Double
    let chestCm: Double
    let armRightCm: Double
    let thighCm: Double
    let notes: String
}

struct WorkoutsExport: Codable {
    let version: Int
    let updatedAt: Date
    let entries: [WorkoutExport]
}

struct WorkoutExport: Codable {
    let date: Date
    let activityType: String
    let durationMinutes: Int
    let caloriesBurned: Double
    let notes: String
}

struct WellnessExport: Codable {
    let version: Int
    let updatedAt: Date
    let entries: [WellnessEntryExport]
}

struct WellnessEntryExport: Codable {
    let date: Date
    let energyScore: Int
    let moodScore: Int
    let sleepScore: Int
    let sorenessScore: Int
    let sleepHours: Double
    let restingHR: Int
    let hrvMs: Int
    let scoreGlobal: Double
    let notes: String
}

// MARK: - Service

@Observable
class iCloudExportService {
    static let shared = iCloudExportService()

    private let ubiquityContainerID = "iCloud.com.nicolasnutritrack.app"
    private let schemaVersion = 1

    var derniereExportDate: Date? {
        get {
            if let ts = UserDefaults.standard.object(forKey: "derniereExportDate") as? Date { return ts }
            return nil
        }
        set { UserDefaults.standard.set(newValue, forKey: "derniereExportDate") }
    }

    enum ExportError: Error {
        case iCloudUnavailable
        case writeFailed(String)
    }

    // MARK: - Path iCloud

    var iCloudDocumentsURL: URL? {
        guard let containerURL = FileManager.default.url(
            forUbiquityContainerIdentifier: ubiquityContainerID
        ) else {
            return nil
        }
        return containerURL.appendingPathComponent("Documents/NutriTrack", isDirectory: true)
    }

    var iCloudAvailable: Bool { iCloudDocumentsURL != nil }

    func iCloudPathAffichable() -> String {
        iCloudDocumentsURL?.path ?? "iCloud Drive non configuré"
    }

    // MARK: - Export principal

    @MainActor
    func exportAll(context: ModelContext, profile: UserProfile) async throws {
        guard let baseURL = iCloudDocumentsURL else {
            throw ExportError.iCloudUnavailable
        }

        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        let photosURL = baseURL.appendingPathComponent("photos", isDirectory: true)
        try FileManager.default.createDirectory(at: photosURL, withIntermediateDirectories: true)

        let pid = profile.profileID.uuidString

        try exportProfile(profile, to: baseURL)
        try exportDailyLog(context: context, profileID: pid, to: baseURL)
        try exportBodyMetrics(context: context, profileID: pid, to: baseURL)
        try exportWorkouts(context: context, profileID: pid, to: baseURL)
        try exportWellness(context: context, profileID: pid, to: baseURL)
        try exportPhotos(context: context, profileID: pid, to: photosURL)

        derniereExportDate = Date()
    }

    // MARK: - Export profil

    private func exportProfile(_ profile: UserProfile, to baseURL: URL) throws {
        let data = ProfileExport(
            version: schemaVersion,
            updatedAt: Date(),
            profileID: profile.profileID.uuidString,
            prenom: profile.prenom,
            sexe: profile.sexe,
            dateNaissance: profile.dateNaissance,
            tailleCm: profile.taille,
            poidsActuelKg: profile.poidsActuel,
            silhouetteActuelle: profile.silhouetteActuelle,
            silhouetteObjectif: profile.silhouetteObjectif,
            dateObjectif: profile.dateObjectif,
            approche: profile.approcheTransformation,
            niveauActivite: profile.niveauActivite,
            niveauSport: profile.niveauSport,
            equipementSport: profile.equipementSport,
            regimeAlimentaire: profile.regimeAlimentaire,
            allergies: profile.allergies,
            sportsAprecies: profile.sportsAprecies,
            objectifs: ObjectifsExport(
                kcal: profile.objectifCalorique,
                proteinG: profile.objectifProteines,
                carbsG: profile.objectifGlucides,
                fatG: profile.objectifLipides,
                eauL: profile.objectifEau
            )
        )
        try writeJSON(data, to: baseURL.appendingPathComponent("profile.json"))
    }

    // MARK: - Export daily log

    private func exportDailyLog(context: ModelContext, profileID: String, to baseURL: URL) throws {
        let pid = profileID
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate<FoodEntry> { $0.profileID == pid },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let entries = (try? context.fetch(descriptor)) ?? []

        let calendar = Calendar.current
        let groupe = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.date)
        }

        var jours: [DayExport] = []
        for (date, entriesJour) in groupe.sorted(by: { $0.key < $1.key }) {
            let parRepas = Dictionary(grouping: entriesJour) { $0.mealType }

            var meals: [MealExport] = []
            for (mealType, mealEntries) in parRepas.sorted(by: { $0.key < $1.key }) {
                let items = mealEntries.map { e in
                    FoodItemExport(
                        name: e.foodItem?.name ?? "Inconnu",
                        quantityG: e.quantity,
                        proteinG: e.proteins,
                        carbsG: e.carbohydrates,
                        fatG: e.fats,
                        kcal: e.calories
                    )
                }
                let totals = MacrosExport(
                    kcal: items.reduce(0) { $0 + $1.kcal },
                    proteinG: items.reduce(0) { $0 + $1.proteinG },
                    carbsG: items.reduce(0) { $0 + $1.carbsG },
                    fatG: items.reduce(0) { $0 + $1.fatG }
                )
                meals.append(MealExport(
                    id: "\(date.ISO8601Format())-\(mealType)",
                    loggedAt: mealEntries.first?.date ?? date,
                    mealType: mealType,
                    items: items,
                    totals: totals
                ))
            }

            let dailyTotals = MacrosExport(
                kcal: meals.reduce(0) { $0 + $1.totals.kcal },
                proteinG: meals.reduce(0) { $0 + $1.totals.proteinG },
                carbsG: meals.reduce(0) { $0 + $1.totals.carbsG },
                fatG: meals.reduce(0) { $0 + $1.totals.fatG }
            )

            jours.append(DayExport(date: date, meals: meals, dailyTotals: dailyTotals))
        }

        let export = DailyLogExport(version: schemaVersion, updatedAt: Date(), entries: jours)
        try writeJSON(export, to: baseURL.appendingPathComponent("daily_log.json"))
    }

    // MARK: - Export body metrics

    private func exportBodyMetrics(context: ModelContext, profileID: String, to baseURL: URL) throws {
        let pid = profileID
        let descriptor = FetchDescriptor<BodyMetric>(
            predicate: #Predicate<BodyMetric> { $0.profileID == pid },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let entries = (try? context.fetch(descriptor)) ?? []
        let mapped = entries.map { m in
            BodyMetricExport(
                date: m.date,
                weightKg: m.weight,
                bmi: m.bmi,
                bodyFatPct: m.bodyFatPercentage,
                waistCm: m.waist,
                hipsCm: m.hips,
                chestCm: m.chest,
                armRightCm: m.armRight,
                thighCm: m.thigh,
                notes: m.notes
            )
        }
        let export = BodyMetricsExport(version: schemaVersion, updatedAt: Date(), entries: mapped)
        try writeJSON(export, to: baseURL.appendingPathComponent("body_metrics.json"))
    }

    // MARK: - Export workouts

    private func exportWorkouts(context: ModelContext, profileID: String, to baseURL: URL) throws {
        let pid = profileID
        let descriptor = FetchDescriptor<ActivityEntry>(
            predicate: #Predicate<ActivityEntry> { $0.profileID == pid },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let entries = (try? context.fetch(descriptor)) ?? []
        let mapped = entries.map { a in
            WorkoutExport(
                date: a.date,
                activityType: a.activityType,
                durationMinutes: a.durationMinutes,
                caloriesBurned: a.caloriesBurned,
                notes: a.notes
            )
        }
        let export = WorkoutsExport(version: schemaVersion, updatedAt: Date(), entries: mapped)
        try writeJSON(export, to: baseURL.appendingPathComponent("workouts.json"))
    }

    // MARK: - Export wellness

    private func exportWellness(context: ModelContext, profileID: String, to baseURL: URL) throws {
        let pid = profileID
        let descriptor = FetchDescriptor<WellnessScore>(
            predicate: #Predicate<WellnessScore> { $0.profileID == pid },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let entries = (try? context.fetch(descriptor)) ?? []
        let mapped = entries.map { w in
            WellnessEntryExport(
                date: w.date,
                energyScore: w.energyScore,
                moodScore: w.moodScore,
                sleepScore: w.sleepScore,
                sorenessScore: w.sorenessScore,
                sleepHours: w.sleepHours,
                restingHR: w.restingHR,
                hrvMs: w.hrvMs,
                scoreGlobal: w.scoreGlobal,
                notes: w.notes
            )
        }
        let export = WellnessExport(version: schemaVersion, updatedAt: Date(), entries: mapped)
        try writeJSON(export, to: baseURL.appendingPathComponent("wellness.json"))
    }

    // MARK: - Export photos

    private func exportPhotos(context: ModelContext, profileID: String, to photosURL: URL) throws {
        let pid = profileID
        let descriptor = FetchDescriptor<ProgressPhoto>(
            predicate: #Predicate<ProgressPhoto> { $0.profileID == pid },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let photos = (try? context.fetch(descriptor)) ?? []

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for photo in photos {
            guard let data = photo.imageData else { continue }
            let nom = "\(formatter.string(from: photo.date))-\(photo.angle).jpg"
            let dest = photosURL.appendingPathComponent(nom)
            do {
                try writeAtomically(data, to: dest)
            } catch {
                print("Erreur export photo \(nom) : \(error)")
            }
        }
    }

    // MARK: - Écriture atomique

    private func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(value)
        try writeAtomically(data, to: url)
    }

    private func writeAtomically(_ data: Data, to url: URL) throws {
        let tmp = url.appendingPathExtension("tmp")
        try data.write(to: tmp, options: .atomic)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        try FileManager.default.moveItem(at: tmp, to: url)
    }
}
