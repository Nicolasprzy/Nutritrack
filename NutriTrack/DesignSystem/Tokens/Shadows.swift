import SwiftUI

// MARK: - Élévations NutriTrack
// 3 niveaux. Utilisés sur cards, buttons (hover/pressed), sheets.

struct NutriShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    /// Ombre subtile pour cards au repos
    static let soft = NutriShadow(
        color: Color.black.opacity(0.05),
        radius: 8, x: 0, y: 2
    )

    /// Ombre médium pour éléments actifs (focus, hover)
    static let medium = NutriShadow(
        color: Color.black.opacity(0.10),
        radius: 12, x: 0, y: 4
    )

    /// Ombre prononcée pour modales et popovers
    static let elevated = NutriShadow(
        color: Color.black.opacity(0.18),
        radius: 24, x: 0, y: 8
    )
}

extension View {
    /// Applique une ombre NutriTrack standardisée
    func nutriShadow(_ shadow: NutriShadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}
