import SwiftUI

// MARK: - Couleurs

// Permet d'utiliser .nutriGreen directement dans .foregroundStyle()
extension ShapeStyle where Self == Color {
    static var nutriGreen: Color { Color(red: 0.2, green: 0.8, blue: 0.4) }
    static var nutriGreenDark: Color { Color(red: 0.1, green: 0.65, blue: 0.3) }
    static var proteineColor: Color { Color(red: 0.3, green: 0.6, blue: 1.0) }
    static var glucideColor: Color { Color(red: 1.0, green: 0.75, blue: 0.2) }
    static var lipideColor: Color { Color(red: 1.0, green: 0.35, blue: 0.35) }
}

extension Color {
    // Vert santé principal (style Apple Fitness)
    static let nutriGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let nutriGreenDark = Color(red: 0.1, green: 0.65, blue: 0.3)

    // Macronutriments
    static let proteineColor = Color(red: 0.3, green: 0.6, blue: 1.0)   // bleu
    static let glucideColor  = Color(red: 1.0, green: 0.75, blue: 0.2)  // orange-jaune
    static let lipideColor   = Color(red: 1.0, green: 0.35, blue: 0.35) // rouge-rose

    // Alerte / objectif dépassé
    static let alerteOrange = Color(red: 1.0, green: 0.6, blue: 0.0)

    // Fond adaptatif
    static var fondPrincipal: Color {
        #if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color(uiColor: .systemGroupedBackground)
        #endif
    }
}

// MARK: - Typographie

extension Font {
    static let nutriLargeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let nutriTitle      = Font.system(.title, design: .rounded, weight: .semibold)
    static let nutriTitle2     = Font.system(.title2, design: .rounded, weight: .semibold)
    static let nutriHeadline   = Font.system(.headline, design: .rounded)
    static let nutriBody       = Font.system(.body, design: .rounded)
    static let nutriCaption    = Font.system(.caption, design: .rounded)
}

// MARK: - Espacement

enum Spacing {
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 16
    static let lg: CGFloat  = 24
    static let xl: CGFloat  = 32
    static let xxl: CGFloat = 48
}

// MARK: - Coins arrondis

enum Radius {
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 12
    static let lg: CGFloat  = 16
    static let xl: CGFloat  = 24
}

// MARK: - Types de repas

enum MealType: String, CaseIterable {
    case petitDejeuner = "petit_dejeuner"
    case dejeuner      = "dejeuner"
    case diner         = "diner"
    case collation     = "collation"

    var label: String {
        switch self {
        case .petitDejeuner: return "Petit-déjeuner"
        case .dejeuner:      return "Déjeuner"
        case .diner:         return "Dîner"
        case .collation:     return "Collation"
        }
    }

    var icon: String {
        switch self {
        case .petitDejeuner: return "sunrise.fill"
        case .dejeuner:      return "sun.max.fill"
        case .diner:         return "moon.fill"
        case .collation:     return "fork.knife"
        }
    }

    var couleur: Color {
        switch self {
        case .petitDejeuner: return .orange
        case .dejeuner:      return .yellow
        case .diner:         return .indigo
        case .collation:     return .teal
        }
    }
}

// MARK: - Niveaux d'activité

enum NiveauActivite: String, CaseIterable {
    case sedentaire  = "sedentaire"
    case leger       = "leger"
    case modere      = "modere"
    case actif       = "actif"
    case tres_actif  = "tres_actif"

    var label: String {
        switch self {
        case .sedentaire: return "Sédentaire"
        case .leger:      return "Légèrement actif"
        case .modere:     return "Modérément actif"
        case .actif:      return "Actif"
        case .tres_actif: return "Très actif"
        }
    }

    var facteur: Double {
        switch self {
        case .sedentaire: return 1.2
        case .leger:      return 1.375
        case .modere:     return 1.55
        case .actif:      return 1.725
        case .tres_actif: return 1.9
        }
    }
}

// MARK: - Sexe

enum Sexe: String, CaseIterable {
    case homme = "homme"
    case femme = "femme"

    var label: String {
        switch self {
        case .homme: return "Homme"
        case .femme: return "Femme"
        }
    }
}

// MARK: - Navigation

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard      = "dashboard"
    case journal        = "journal"
    case corps          = "corps"
    case activite       = "activite"
    case planRepas      = "planRepas"
    case coach          = "coach"
    case profil         = "profil"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dashboard:  return "Tableau de bord"
        case .journal:    return "Journal alimentaire"
        case .corps:      return "Suivi corporel"
        case .activite:   return "Activité"
        case .planRepas:  return "Plan de repas"
        case .coach:      return "Coach IA"
        case .profil:     return "Profil"
        }
    }

    var icon: String {
        switch self {
        case .dashboard:  return "chart.bar.fill"
        case .journal:    return "fork.knife"
        case .corps:      return "chart.line.uptrend.xyaxis"
        case .activite:   return "figure.run"
        case .planRepas:  return "calendar"
        case .coach:      return "brain.head.profile"
        case .profil:     return "person.circle.fill"
        }
    }

    var couleur: Color {
        switch self {
        case .dashboard:  return .nutriGreen
        case .journal:    return .orange
        case .corps:      return .blue
        case .activite:   return .red
        case .planRepas:  return .purple
        case .coach:      return .cyan
        case .profil:     return .gray
        }
    }
}

// MARK: - API

enum APIConstants {
    static let openFoodFactsSearch  = "https://world.openfoodfacts.org/cgi/search.pl"
    static let openFoodFactsProduct = "https://world.openfoodfacts.org/api/v0/product"
    static let claudeAPIEndpoint    = "https://api.anthropic.com/v1/messages"
    static let claudeModel          = "claude-sonnet-4-20250514"
    static let claudeVersion        = "2023-06-01"
}
