import Foundation
import SwiftData

@Model
class WellnessScore {
    var profileID: String = ""
    var date: Date = Date()

    var energyScore: Int = 5
    var moodScore: Int = 5
    var sleepScore: Int = 5
    var sorenessScore: Int = 5

    var sleepHours: Double = 0.0
    var restingHR: Int = 0
    var hrvMs: Int = 0

    var notes: String = ""

    init(
        profileID: String = "",
        date: Date = Date(),
        energyScore: Int = 5,
        moodScore: Int = 5,
        sleepScore: Int = 5,
        sorenessScore: Int = 5,
        sleepHours: Double = 0,
        restingHR: Int = 0,
        hrvMs: Int = 0,
        notes: String = ""
    ) {
        self.profileID = profileID
        self.date = date
        self.energyScore = energyScore
        self.moodScore = moodScore
        self.sleepScore = sleepScore
        self.sorenessScore = sorenessScore
        self.sleepHours = sleepHours
        self.restingHR = restingHR
        self.hrvMs = hrvMs
        self.notes = notes
    }

    var scoreGlobal: Double {
        let scores = [energyScore, moodScore, sleepScore, 11 - sorenessScore]
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }
}
