import SwiftUI

struct StatCard: View {
    let titre: String
    let valeur: String
    let unite: String
    let icone: String
    let couleur: Color
    var tendance: String? = nil

    var body: some View {
        GlassCard(padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: 10) {
                // Icône + titre
                HStack(spacing: 6) {
                    Image(systemName: icone)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(couleur)
                    Text(titre)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                }

                // Valeur + unité sur la même ligne
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(valeur)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text(unite)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .accessibilityLabel("\(titre) : \(valeur) \(unite)")
    }
}

struct StatCardLarge: View {
    let titre: String
    let valeur: String
    let sousTitre: String
    let icone: String
    let couleur: Color
    var progressionValue: Double? = nil

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label(titre, systemImage: icone)
                    .font(.nutriHeadline)
                    .foregroundStyle(couleur)
                Text(valeur)
                    .font(.nutriLargeTitle)
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                if let progression = progressionValue {
                    ProgressView(value: progression).tint(couleur)
                }
                Text(sousTitre)
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        StatCard(titre: "Restantes", valeur: "2332", unite: "kcal", icone: "flame.fill", couleur: .orange)
        StatCard(titre: "Brûlées", valeur: "—", unite: "kcal", icone: "bolt.fill", couleur: .red)
        StatCard(titre: "Pas", valeur: "8 234", unite: "pas", icone: "figure.walk", couleur: .nutriGreen)
        StatCard(titre: "Eau", valeur: "—", unite: "L", icone: "drop.fill", couleur: .blue)
    }
    .padding()
    .frame(width: 400)
}
