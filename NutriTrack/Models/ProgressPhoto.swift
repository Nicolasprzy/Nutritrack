import Foundation
import SwiftData

@Model
class ProgressPhoto {
    var profileID: String = ""
    var date: Date = Date()
    var angle: String = "front"

    @Attribute(.externalStorage) var imageData: Data?

    var notes: String = ""

    init(
        profileID: String = "",
        date: Date = Date(),
        angle: String = "front",
        imageData: Data? = nil,
        notes: String = ""
    ) {
        self.profileID = profileID
        self.date = date
        self.angle = angle
        self.imageData = imageData
        self.notes = notes
    }

    var angleEnum: PhotoAngle {
        PhotoAngle(rawValue: angle) ?? .front
    }

    var dateFormatted: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}

enum PhotoAngle: String, CaseIterable, Codable {
    case front
    case side
    case back

    var label: String {
        switch self {
        case .front: return "Face"
        case .side: return "Profil"
        case .back: return "Dos"
        }
    }

    var icon: String {
        switch self {
        case .front: return "person.fill"
        case .side: return "person.fill.turn.right"
        case .back: return "person.fill.turn.down"
        }
    }
}
