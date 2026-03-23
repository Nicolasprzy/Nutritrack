import Foundation
import SwiftData

@Model
class BodyMetric {
    var date: Date = Date()
    var weight: Double = 0.0              // kg
    var bmi: Double = 0.0
    var waist: Double = 0.0               // cm
    var hips: Double = 0.0                // cm
    var bodyFatPercentage: Double = 0.0
    var notes: String = ""

    init(
        date: Date = Date(),
        weight: Double = 0,
        bmi: Double = 0,
        waist: Double = 0,
        hips: Double = 0,
        bodyFatPercentage: Double = 0,
        notes: String = ""
    ) {
        self.date = date
        self.weight = weight
        self.bmi = bmi
        self.waist = waist
        self.hips = hips
        self.bodyFatPercentage = bodyFatPercentage
        self.notes = notes
    }

    // MARK: - Catégorie IMC

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
}
