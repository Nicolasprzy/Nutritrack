import SwiftUI

// MARK: - Tailles et dimensions NutriTrack
// Centralise toutes les dimensions de layout hardcodées.

enum NutriLayout {
    // MARK: Navigation
    static let sidebarWidth: CGFloat = 220
    static let sidebarMinWidth: CGFloat = 200
    static let sidebarMaxWidth: CGFloat = 280

    // MARK: Contenu principal
    static let contentMinWidth: CGFloat = 640
    static let contentIdealWidth: CGFloat = 800

    // MARK: Cards
    static let cardMinWidth: CGFloat = 280
    static let cardMaxWidth: CGFloat = 480
    static let dashboardLeftColumn: CGFloat = 360

    // MARK: Sheets (macOS)
    static let sheetCompactWidth: CGFloat = 520
    static let sheetCompactHeight: CGFloat = 480

    static let sheetStandardWidth: CGFloat = 640
    static let sheetStandardHeight: CGFloat = 640

    static let sheetLargeWidth: CGFloat = 800
    static let sheetLargeHeight: CGFloat = 720

    // MARK: Boutons (hauteurs)
    static let buttonSmall: CGFloat = 28
    static let buttonRegular: CGFloat = 36
    static let buttonLarge: CGFloat = 44

    // MARK: Composants
    static let fieldHeight: CGFloat = 36
    static let fieldMultilineMinHeight: CGFloat = 80
    static let fieldMultilineMaxHeight: CGFloat = 200

    // MARK: Icônes
    static let iconSmall: CGFloat = 14
    static let iconRegular: CGFloat = 18
    static let iconLarge: CGFloat = 24
    static let iconXL: CGFloat = 32
}

/// Tailles de sheet NutriTrack — utilisées par .nutriSheet()
enum NutriSheetSize {
    case compact
    case standard
    case large

    var width: CGFloat {
        switch self {
        case .compact: return NutriLayout.sheetCompactWidth
        case .standard: return NutriLayout.sheetStandardWidth
        case .large: return NutriLayout.sheetLargeWidth
        }
    }

    var height: CGFloat {
        switch self {
        case .compact: return NutriLayout.sheetCompactHeight
        case .standard: return NutriLayout.sheetStandardHeight
        case .large: return NutriLayout.sheetLargeHeight
        }
    }

    #if os(iOS)
    var detents: Set<PresentationDetent> {
        switch self {
        case .compact: return [.medium]
        case .standard: return [.medium, .large]
        case .large: return [.large]
        }
    }
    #endif
}
