import Foundation
import SwiftData

// MARK: - Wger API Models

private struct WgerPageResponse: Decodable {
    let count: Int
    let next: String?
    let results: [WgerExerciseInfo]
}

private struct WgerExerciseInfo: Decodable {
    let id: Int
    let category: WgerCategory?
    let muscles: [WgerMuscle]
    let muscles_secondary: [WgerMuscle]
    let equipment: [WgerEquipment]
    let images: [WgerImage]
    let translations: [WgerTranslation]
}

private struct WgerCategory: Decodable {
    let id: Int
    let name: String
}

private struct WgerMuscle: Decodable {
    let id: Int
    let name_en: String
}

private struct WgerEquipment: Decodable {
    let id: Int
    let name: String
}

private struct WgerImage: Decodable {
    let image: String
    let is_main: Bool?
}

private struct WgerTranslation: Decodable {
    let language: Int
    let name: String
    let description: String
}

// MARK: - WgerSeedService

struct WgerSeedService {

    private let baseURL = "https://wger.de/api/v2/exerciseinfo/"
    private let pageSize = 50
    private let maxExercises = 300   // 6 pages × 50

    // MARK: - Point d'entrée

    func seedIfNeeded(context: ModelContext) async {
        // Vérifie si déjà seedé
        let descriptor = FetchDescriptor<Exercise>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        var offset = 0
        var total = 0

        repeat {
            guard let page = await fetchPage(offset: offset) else { break }
            if total == 0 { total = page.count }

            let exercises = page.results.compactMap { mapToExercise($0) }
            for ex in exercises {
                context.insert(ex)
            }
            try? context.save()

            offset += pageSize
        } while offset < min(maxExercises, total)
    }

    // MARK: - Fetch

    private func fetchPage(offset: Int) async -> WgerPageResponse? {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            .init(name: "format", value: "json"),
            .init(name: "limit", value: "\(pageSize)"),
            .init(name: "offset", value: "\(offset)")
        ]
        guard let url = components.url else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(WgerPageResponse.self, from: data)
        } catch {
            return nil
        }
    }

    // MARK: - Mapping

    private func mapToExercise(_ info: WgerExerciseInfo) -> Exercise? {
        // Traduction : English (2) en priorité, sinon la première
        let translation = info.translations.first(where: { $0.language == 2 })
                       ?? info.translations.first
        guard let t = translation, !t.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }

        // Nettoyer la description HTML
        let description = stripHTML(t.description)

        // Muscles → noms français
        let musclesPrimaires = info.muscles.map { muscleFR($0.name_en) }
        let musclesSecondaires = info.muscles_secondary.map { muscleFR($0.name_en) }

        // Équipement → enum
        let equipement = mapEquipement(info.equipment)

        // Catégorie → notre système
        let categorie = mapCategorie(info.category?.name ?? "")

        // Image principale (GIF ou JPG)
        let imageURL = info.images.first(where: { $0.is_main == true })?.image
                    ?? info.images.first?.image
                    ?? ""

        return Exercise(
            wgerId: info.id,
            nom: t.name,
            descriptionExercice: description,
            musclesPrimaires: musclesPrimaires,
            musclesSecondaires: musclesSecondaires,
            equipement: equipement,
            categorie: categorie,
            niveauDifficulte: "debutant",
            gifURL: imageURL,
            videoURL: "",
            source: "Wger"
        )
    }

    // MARK: - Helpers de mapping

    private func muscleFR(_ nameEN: String) -> String {
        let map: [String: String] = [
            "Anterior deltoid":    "Deltoïde antérieur",
            "Biceps brachii":      "Biceps",
            "Brachialis":          "Brachialis",
            "Serratus anterior":   "Grand dentelé",
            "Pectoralis major":    "Pectoraux",
            "Triceps brachii":     "Triceps",
            "Rectus abdominis":    "Abdominaux",
            "Gastrocnemius":       "Mollets",
            "Gluteus maximus":     "Fessiers",
            "Soleus":              "Soléaire",
            "Quadriceps femoris":  "Quadriceps",
            "Biceps femoris":      "Ischio-jambiers",
            "Posterior deltoid":   "Deltoïde postérieur",
            "Trapezius":           "Trapèzes",
            "Latissimus dorsi":    "Grand dorsal",
            "Obliquus externus abdominis": "Obliques",
            "Erector spinae":      "Érecteurs du rachis",
            "Infraspinatus":       "Infraépineux",
            "Subscapularis":       "Sous-scapulaire",
            "Supraspinatus":       "Sus-épineux",
            "Teres major":         "Grand rond",
            "Iliopsoas":           "Iliopsoas",
            "Tensor fasciae latae": "Tenseur fascia lata",
            "Tibialis anterior":   "Tibial antérieur"
        ]
        return map[nameEN] ?? nameEN
    }

    private func mapEquipement(_ equipment: [WgerEquipment]) -> String {
        let ids = Set(equipment.map { $0.id })
        // Corps uniquement
        if ids.isSubset(of: [4, 5, 6, 7]) { return EquipementSport.poidsCorps.rawValue }
        // Haltères / barres
        if ids.intersection([1, 2, 3, 10]).isEmpty == false { return EquipementSport.halteres.rawValue }
        // Machines / banc
        return EquipementSport.salle.rawValue
    }

    private func mapCategorie(_ categoryName: String) -> String {
        switch categoryName.lowercased() {
        case "cardio":          return "cardio"
        case "stretching":      return "mobilite"
        default:                return "force"
        }
    }

    private func stripHTML(_ html: String) -> String {
        html
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
