import SwiftUI

// MARK: - Hiérarchie typographique NutriTrack
// 10 niveaux sémantiques. Toujours `.rounded` design.
// Les tokens existants dans Constants.swift sont conservés pour compat (nutriLargeTitle, nutriTitle, etc.)
// Ce fichier AJOUTE les tokens manquants.

extension Font {
    // Déjà existant dans Constants.swift (ne pas redéclarer) :
    // nutriLargeTitle, nutriTitle, nutriTitle2, nutriHeadline, nutriBody, nutriCaption

    /// 18pt semibold — sections dans cards
    static let nutriTitle3 = Font.system(.title3, design: .rounded, weight: .semibold)

    /// 14pt semibold — emphase inline
    static let nutriBodyBold = Font.system(.body, design: .rounded, weight: .semibold)

    /// 11pt regular — mentions, footers
    static let nutriCaption2 = Font.system(.caption2, design: .rounded)

    /// 14pt monospace — chiffres alignés (poids, calories)
    static let nutriMonoBody = Font.system(.body, design: .monospaced)
}
