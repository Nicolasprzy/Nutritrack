import Foundation
import SwiftData

@Model
final class DayContext {
    var id: UUID = UUID()
    var profileID: String = ""
    var date: Date = Date()        // normalisée à minuit local
    var dayType: String = "muscle"
    var notes: String?
    var createdAt: Date = Date()

    init(profileID: String, date: Date, dayType: DayType, notes: String? = nil) {
        self.id = UUID()
        self.profileID = profileID
        self.date = Calendar.current.startOfDay(for: date)
        self.dayType = dayType.rawValue
        self.notes = notes
        self.createdAt = Date()
    }
}
