import Foundation
import SwiftData

@Model
class BodyMetric {
    var profileID: String = ""            // UUID du UserProfile propriétaire
    var date: Date = Date()
    var weight: Double = 0.0              // kg
    var bmi: Double = 0.0

    // Mensurations (cm) — tous optionnels (0 = non saisi)
    var waist: Double = 0.0              // tour de taille
    var hips: Double = 0.0              // hanches
    var chest: Double = 0.0             // poitrine
    var armRight: Double = 0.0          // bras droit
    var thigh: Double = 0.0             // cuisse

    var bodyFatPercentage: Double = 0.0
    var notes: String = ""

    init(
        date: Date = Date(),
        weight: Double = 0,
        bmi: Double = 0,
        waist: Double = 0,
        hips: Double = 0,
        chest: Double = 0,
        armRight: Double = 0,
        thigh: Double = 0,
        bodyFatPercentage: Double = 0,
        notes: String = ""
    ) {
        self.date = date
        self.weight = weight
        self.bmi = bmi
        self.waist = waist
        self.hips = hips
        self.chest = chest
        self.armRight = armRight
        self.thigh = thigh
        self.bodyFatPercentage = bodyFatPercentage
        self.notes = notes
    }

    // MARK: - IMC

    var categorieBMI: String {
        switch bmi {
        case ..<18.5: return "Insuffisance pondérale"
        case 18.5..<25: return "Poids normal"
        case 25..<30: return "Surpoids"
        default: return "Obésité"
        }
    }

    var couleurBMI: String {
        switch bmi {
        case ..<18.5: return "blue"
        case 18.5..<25: return "green"
        case 25..<30: return "orange"
        default: return "red"
        }
    }

    // MARK: - Helpers

    var aMensurations: Bool {
        waist > 0 || hips > 0 || chest > 0 || armRight > 0 || thigh > 0
    }
}
