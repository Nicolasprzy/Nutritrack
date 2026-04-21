import Foundation
import SwiftData

@Model
final class MacroTarget {
    var id: UUID = UUID()
    var profileID: String = ""
    var dayType: String = ""          // "muscle" | "rest" | "trailLong" | "trailVeryLong"
    var targetKcal: Int = 0
    var targetProteinG: Int = 0
    var targetCarbsG: Int = 0
    var targetFatG: Int = 0
    var createdAt: Date = Date()

    init(profileID: String, dayType: String, kcal: Int, protein: Int, carbs: Int, fat: Int) {
        self.id = UUID()
        self.profileID = profileID
        self.dayType = dayType
        self.targetKcal = kcal
        self.targetProteinG = protein
        self.targetCarbsG = carbs
        self.targetFatG = fat
        self.createdAt = Date()
    }
}

enum DayType: String, CaseIterable, Identifiable {
    case muscle = "muscle"
    case rest = "rest"
    case trailLong = "trailLong"
    case trailVeryLong = "trailVeryLong"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .muscle: return "Muscu / Trail court"
        case .rest: return "Repos"
        case .trailLong: return "Trail long"
        case .trailVeryLong: return "Trail très long"
        }
    }

    var shortName: String {
        switch self {
        case .muscle: return "Muscu"
        case .rest: return "Repos"
        case .trailLong: return "Trail"
        case .trailVeryLong: return "Trail++"
        }
    }
}
