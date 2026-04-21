import SwiftUI

/// Carte statistique Lumina — point pulsant + valeur display italic serif + unité mono
struct StatCard: View {
    let titre: String
    let valeur: String
    let unite: String
    let icone: String
    let couleur: Color
    var tendance: String? = nil

    @State private var pulsing = false

    var body: some View {
        GlassCard(padding: Spacing.md) {
            VStack(alignment: .leading, spacing: 10) {

                // ── Étiquette avec point pulsant ─────────────────────────────
                HStack(spacing: 6) {
                    Circle()
                        .fill(couleur)
                        .frame(width: 5, height: 5)
                        .shadow(color: couleur.opacity(0.8), radius: pulsing ? 4 : 2)
                        .scaleEffect(pulsing ? 1.35 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                            value: pulsing
                        )
                        .onAppear { pulsing = true }

                    Text(titre.uppercased())
                        .font(.luminaCardLabel)
                        .tracking(2.5)
                        .foregroundStyle(Color.luminaInkMuted)
                        .lineLimit(1)

                    Spacer()
                }

                // ── Valeur display + unité ────────────────────────────────────
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(valeur)
                        .font(.luminaDisplay(32, weight: .thin))
                        .foregroundStyle(Color.luminaInkPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text(unite)
                        .font(.luminaMono(11))
                        .foregroundStyle(Color.luminaInkMuted)
                        .lineLimit(1)
                }

                // ── Tendance (optionnelle) ────────────────────────────────────
                if let tendance {
                    Text(tendance)
                        .font(.luminaMono(9))
                        .tracking(1)
                        .foregroundStyle(couleur.opacity(0.8))
                }
            }
        }
        .accessibilityLabel("\(titre) : \(valeur) \(unite)")
    }
}

/// Grande carte stat Lumina — version étendue avec barre de progression
struct StatCardLarge: View {
    let titre: String
    let valeur: String
    let sousTitre: String
    let icone: String
    let couleur: Color
    var progressionValue: Double? = nil

    @State private var pulsing = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {

                // Eyebrow
                HStack(spacing: 6) {
                    Circle()
                        .fill(couleur)
                        .frame(width: 5, height: 5)
                        .shadow(color: couleur.opacity(0.8), radius: pulsing ? 4 : 2)
                        .scaleEffect(pulsing ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulsing)
                        .onAppear { pulsing = true }

                    Text(titre.uppercased())
                        .font(.luminaCardLabel)
                        .tracking(2.5)
                        .foregroundStyle(Color.luminaInkMuted)
                }

                // Valeur
                Text(valeur)
                    .font(.luminaDisplay(44, weight: .thin))
                    .foregroundStyle(Color.luminaInkPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                // Barre progression
                if let progression = progressionValue {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.luminaInkFaint)
                                .frame(height: 2)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [couleur, couleur.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * min(1, progression), height: 2)
                        }
                    }
                    .frame(height: 2)
                }

                // Sous-titre
                Text(sousTitre)
                    .font(.luminaMono(10))
                    .tracking(1)
                    .foregroundStyle(Color.luminaInkMuted)
            }
        }
    }
}

#Preview {
    ZStack {
        AmbientBackground()
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(titre: "Restantes", valeur: "2 332", unite: "kcal",
                     icone: "flame.fill", couleur: Color.luminaEmber)
            StatCard(titre: "Brûlées", valeur: "—", unite: "kcal",
                     icone: "bolt.fill", couleur: .orange)
            StatCard(titre: "Poids", valeur: "81.5", unite: "kg",
                     icone: "scalemass.fill", couleur: .blue)
            StatCard(titre: "Masse grasse", valeur: "14.2", unite: "%",
                     icone: "drop.fill", couleur: Color.nutriGreen,
                     tendance: "↓ –0.3% cette semaine")
        }
        .padding(32)
    }
    .frame(width: 480, height: 380)
}
