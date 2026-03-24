import Foundation
import SwiftData

@Model
class Exercise {
    var wgerId: Int = 0
    var nom: String = ""
    var descriptionExercice: String = ""
    var musclesPrimairesJSON: String = "[]"      // [String] JSON
    var musclesSecondairesJSON: String = "[]"    // [String] JSON
    var equipement: String = "poids_corps"       // EquipementSport.rawValue
    var categorie: String = "force"              // "force", "cardio", "mobilite", "hiit"
    var niveauDifficulte: String = "debutant"    // NiveauSport.rawValue
    var gifURL: String = ""
    var videoURL: String = ""
    var source: String = "Wger"                  // "Wger", "Local"

    init(
        wgerId: Int = 0,
        nom: String = "",
        descriptionExercice: String = "",
        musclesPrimaires: [String] = [],
        musclesSecondaires: [String] = [],
        equipement: String = "poids_corps",
        categorie: String = "force",
        niveauDifficulte: String = "debutant",
        gifURL: String = "",
        videoURL: String = "",
        source: String = "Wger"
    ) {
        self.wgerId = wgerId
        self.nom = nom
        self.descriptionExercice = descriptionExercice
        self.musclesPrimairesJSON = (try? String(data: JSONEncoder().encode(musclesPrimaires), encoding: .utf8)) ?? "[]"
        self.musclesSecondairesJSON = (try? String(data: JSONEncoder().encode(musclesSecondaires), encoding: .utf8)) ?? "[]"
        self.equipement = equipement
        self.categorie = categorie
        self.niveauDifficulte = niveauDifficulte
        self.gifURL = gifURL
        self.videoURL = videoURL
        self.source = source
    }

    // MARK: - Computed

    var musclesPrimaires: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(musclesPrimairesJSON.utf8))) ?? []
    }

    var musclesSecondaires: [String] {
        (try? JSONDecoder().decode([String].self, from: Data(musclesSecondairesJSON.utf8))) ?? []
    }

    var tousLesMuscles: [String] {
        musclesPrimaires + musclesSecondaires
    }

    var icone: String {
        switch categorie.lowercased() {
        case "cardio":          return "heart.fill"
        case "hiit":            return "bolt.fill"
        case "mobilite", "mobilité": return "figure.mind.and.body"
        default:                return "dumbbell.fill"
        }
    }

    var equipementEnum: EquipementSport {
        EquipementSport(rawValue: equipement) ?? .poidsCorps
    }
}
