import Foundation
import SwiftData

@Model
class UserProfile {
    // MARK: - Identité unique (multi-profils)
    var profileID: UUID = UUID()

    // MARK: - Identité de base
    var prenom: String = ""
    var dateNaissance: Date = Date()
    var sexe: String = "homme"          // Sexe.rawValue
    var taille: Double = 175.0          // cm

    // MARK: - Poids
    var poidsActuel: Double = 75.0           // mis à jour à chaque BodyMetric

    // MARK: - Objectifs nutritionnels (calculés automatiquement)
    var objectifPoids: Double = 0.0
    var objectifCalorique: Double = 2000.0
    var objectifProteines: Double = 150.0
    var objectifGlucides: Double = 200.0
    var objectifLipides: Double = 65.0
    var objectifEau: Double = 2.5       // litres

    // MARK: - Objectif de silhouette (v2)
    var silhouetteActuelle: String = ""  // SilhouetteObjectif.rawValue — silhouette de départ
    var silhouetteObjectif: String = ""  // SilhouetteObjectif.rawValue — silhouette cible
    var dateObjectif: Date = Date()
    var frequenceReevaluation: Int = 7   // jours
    var onboardingV2Complete: Bool = false
    var approcheTransformation: String = "normale"  // ApprocheTransformation.rawValue

    // MARK: - Mensurations initiales (v2)
    var mensurationTailleCm: Double = 0      // tour de taille (cm)
    var mensurationHanchesCm: Double = 0
    var mensurationPoitrineCm: Double = 0
    var mensurationBrasDroitCm: Double = 0
    var mensurationCuisseCm: Double = 0
    var masseGraisseuse: Double = 0          // % masse graisseuse (0 = non renseigné)

    // MARK: - Préférences sportives (v2)
    var niveauSport: String = "debutant"           // NiveauSport.rawValue
    var equipementSport: String = "salle"          // EquipementSport.rawValue
    var sportsApreciesJSON: String = "[]"          // [String] JSON
    var frequenceEntrainementJours: Int = 3
    var dureeSeanceMinutes: Int = 60

    // MARK: - Préférences alimentaires (v2)
    var regimeAlimentaire: String = "omnivore"     // RegimeAlimentaire.rawValue
    var allergiesJSON: String = "[]"               // [String] JSON
    var nbRepasJour: Int = 3
    var alimentsAimes: String = ""
    var alimentsDetestes: String = ""

    // MARK: - Habitudes de vie (v2)
    var niveauActivite: String = "modere"          // NiveauActivite.rawValue (TDEE + questionnaire)
    var qualiteSommeil: Int = 3                    // 1-5
    var dureeSommeilHeures: Double = 7.0
    var niveauStress: Int = 3                      // 1-5
    var alcool: String = "jamais"                  // AlcoolHabitude.rawValue
    var tabac: Bool = false
    var hydratationHabituelleLitres: Double = 1.5

    // MARK: - Intégrations
    var healthKitActif: Bool = false

    // MARK: - Objectifs physiques (Sprint 1)
    // CloudKit : optionnels OK, pas de default requis
    var targetWeightKg: Double?
    var targetBodyFatPct: Double?
    var targetDate: Date?

    // Flag de seeding du plan nutrition (CloudKit : default value)
    var planSeeded: Bool = false

    var createdAt: Date = Date()

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

    // MARK: - Computed

    var sexeEnum: Sexe {
        Sexe(rawValue: sexe) ?? .homme
    }

    var niveauActiviteEnum: NiveauActivite {
        NiveauActivite(rawValue: niveauActivite) ?? .modere
    }

    var silhouetteEnum: SilhouetteObjectif? {
        SilhouetteObjectif(rawValue: silhouetteObjectif)
    }

    var approcheEnum: ApprocheTransformation {
        ApprocheTransformation(rawValue: approcheTransformation) ?? .normale
    }

    var niveauSportEnum: NiveauSport {
        NiveauSport(rawValue: niveauSport) ?? .debutant
    }

    var equipementEnum: EquipementSport {
        EquipementSport(rawValue: equipementSport) ?? .salle
    }

    var regimeEnum: RegimeAlimentaire {
        RegimeAlimentaire(rawValue: regimeAlimentaire) ?? .omnivore
    }

    var alcoolEnum: AlcoolHabitude {
        AlcoolHabitude(rawValue: alcool) ?? .jamais
    }

    var sportsAprecies: [String] {
        get { (try? JSONDecoder().decode([String].self, from: Data(sportsApreciesJSON.utf8))) ?? [] }
        set { sportsApreciesJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    var allergies: [String] {
        get { (try? JSONDecoder().decode([String].self, from: Data(allergiesJSON.utf8))) ?? [] }
        set { allergiesJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]" }
    }

    var age: Int {
        dateNaissance.age
    }

    var prenomAffiche: String {
        prenom.isEmpty ? "toi" : prenom
    }

    var aUnObjectifSilhouette: Bool {
        !silhouetteObjectif.isEmpty
    }
}
