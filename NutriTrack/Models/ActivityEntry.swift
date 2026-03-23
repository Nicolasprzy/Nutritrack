import Foundation
import SwiftData

@Model
class ActivityEntry {
    var date: Date = Date()
    var activityType: String = ""   // "course", "marche", "musculation", "vélo", etc.
    var durationMinutes: Int = 0
    var caloriesBurned: Double = 0.0
    var notes: String = ""

    init(
        date: Date = Date(),
        activityType: String = "",
        durationMinutes: Int = 0,
        caloriesBurned: Double = 0,
        notes: String = ""
    ) {
        self.date = date
        self.activityType = activityType
        self.durationMinutes = durationMinutes
        self.caloriesBurned = caloriesBurned
        self.notes = notes
    }

    var durationFormatted: String {
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        if h > 0 {
            return "\(h)h\(m > 0 ? "\(m)min" : "")"
        }
        return "\(m) min"
    }

    var icone: String {
        switch activityType.lowercased() {
        case let t where t.contains("course") || t.contains("running"):
            return "figure.run"
        case let t where t.contains("marche") || t.contains("walk"):
            return "figure.walk"
        case let t where t.contains("muscu") || t.contains("gym"):
            return "dumbbell.fill"
        case let t where t.contains("vélo") || t.contains("cycling"):
            return "bicycle"
        case let t where t.contains("natation") || t.contains("swim"):
            return "figure.pool.swim"
        case let t where t.contains("yoga"):
            return "figure.mind.and.body"
        default:
            return "figure.mixed.cardio"
        }
    }
}
