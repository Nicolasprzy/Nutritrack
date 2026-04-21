import SwiftUI

// MARK: - Couleurs sémantiques NutriTrack
// Ce fichier est la source de vérité pour toutes les couleurs de l'app.
// Les valeurs de base (nutriGreen, etc.) restent définies dans Utilities/Constants.swift
// pour éviter les doublons pendant la migration. À terme, toutes les extensions migrent ici.

extension Color {
    // MARK: Surface (champs, pickers)
    static var nutriSurface: Color { Color.nutriGreen.opacity(0.05) }
    static var nutriSurfaceFocus: Color { Color.nutriGreen.opacity(0.10) }
    static var nutriSurfaceError: Color { Color.red.opacity(0.08) }
    static var nutriSurfaceDisabled: Color { Color.secondary.opacity(0.06) }

    // MARK: Bordures
    static var nutriBorder: Color { Color.secondary.opacity(0.15) }
    static var nutriBorderFocus: Color { Color.nutriGreen.opacity(0.4) }
    static var nutriBorderError: Color { Color.red.opacity(0.5) }

    // MARK: Texte (alias sémantiques)
    static var nutriTextPrimary: Color { .primary }
    static var nutriTextSecondary: Color { .secondary }
    static var nutriTextTertiary: Color { Color.primary.opacity(0.4) }

    // MARK: Fonds spécialisés
    static var nutriElevatedSurface: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemBackground)
        #endif
    }

    // MARK: Feedback
    static var nutriSuccess: Color { Color.nutriGreen }
    static var nutriWarning: Color { Color.alerteOrange }
    static var nutriError: Color { .red }
    static var nutriInfo: Color { .blue }
}
