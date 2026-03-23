import SwiftUI
import Foundation

// MARK: - Double

extension Double {
    /// Arrondi à n décimales pour affichage
    func arrondi(_ decimales: Int = 1) -> String {
        String(format: "%.\(decimales)f", self)
    }

    /// Format calories (sans décimale)
    var kcal: String {
        String(format: "%.0f kcal", self)
    }

    /// Format grammes
    var grammes: String {
        if self < 10 {
            return String(format: "%.1f g", self)
        }
        return String(format: "%.0f g", self)
    }

    /// Format kg
    var kg: String {
        String(format: "%.1f kg", self)
    }

    /// Format cm
    var cm: String {
        String(format: "%.0f cm", self)
    }

    /// Progression clampée entre 0 et 1
    func progression(sur total: Double) -> Double {
        guard total > 0 else { return 0 }
        return min(max(self / total, 0), 1)
    }
}

// MARK: - Date

extension Date {
    /// Est-ce aujourd'hui ?
    var estAujourdhui: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Début de journée (minuit)
    var debutDeJour: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Fin de journée (23:59:59)
    var finDeJour: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: debutDeJour) ?? self
    }

    /// Format "Lundi 23 mars"
    var formatLong: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: self).capitalized
    }

    /// Format court "23/03"
    var formatCourt: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: self)
    }

    /// Format "23 mars 2026"
    var formatMedium: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }

    /// Il y a N jours
    static func ilYaJours(_ jours: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -jours, to: Date()) ?? Date()
    }

    /// Âge calculé depuis la date de naissance
    var age: Int {
        Calendar.current.dateComponents([.year], from: self, to: Date()).year ?? 0
    }
}

// MARK: - View

extension View {
    /// Carte en verre dépoli (shortcut)
    func glassCard(padding: CGFloat = Spacing.md, cornerRadius: CGFloat = Radius.lg) -> some View {
        self
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }

    /// Modifier conditionnel
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Color

extension Color {
    /// Dégradé vertical depuis une couleur
    func degrade(opacite: Double = 0.3) -> LinearGradient {
        LinearGradient(
            colors: [self.opacity(opacite), self.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Array

extension Array where Element == Double {
    var moyenne: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
