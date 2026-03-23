import Foundation
import SwiftData

@Model
class UserProfile {
    var prenom: String = ""
    var dateNaissance: Date = Date()
    var sexe: String = "homme"          // "homme", "femme"
    var taille: Double = 175.0          // cm
    var objectifPoids: Double = 0.0
    var niveauActivite: String = "modere"
    var objectifCalorique: Double = 2000.0
    var objectifProteines: Double = 150.0
    var objectifGlucides: Double = 200.0
    var objectifLipides: Double = 65.0
    var claudeAPIKey: String = ""
    var createdAt: Date = Date()

    // Préférences tracking
    var healthKitActif: Bool = false
    var objectifEau: Double = 2.5       // litres

    init(
        prenom: String = "",
        dateNaissance: Date = Date(),
        sexe: String = "homme",
        taille: Double = 175.0,
        objectifPoids: Double = 75.0,
        niveauActivite: String = "modere"
    ) {
        self.prenom = prenom
        self.dateNaissance = dateNaissance
        self.sexe = sexe
        self.taille = taille
        self.objectifPoids = objectifPoids
        self.niveauActivite = niveauActivite
        self.createdAt = Date()
    }

    var sexeEnum: Sexe {
        Sexe(rawValue: sexe) ?? .homme
    }

    var niveauActiviteEnum: NiveauActivite {
        NiveauActivite(rawValue: niveauActivite) ?? .modere
    }

    var age: Int {
        dateNaissance.age
    }

    var prenomAffiche: String {
        prenom.isEmpty ? "toi" : prenom
    }

    var aUneCleAPI: Bool {
        !claudeAPIKey.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
