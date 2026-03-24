import SwiftUI

// MARK: - Environment key pour le profil actif

private struct ActiveProfileIDKey: EnvironmentKey {
    static let defaultValue: String = ""
}

extension EnvironmentValues {
    var activeProfileID: String {
        get { self[ActiveProfileIDKey.self] }
        set { self[ActiveProfileIDKey.self] = newValue }
    }
}
