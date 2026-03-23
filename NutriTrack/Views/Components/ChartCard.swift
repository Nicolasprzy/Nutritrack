import SwiftUI
import Charts

/// Carte conteneur pour les graphiques Swift Charts
struct ChartCard<Content: View>: View {
    let titre: String
    var sousTitre: String = ""
    var icone: String = "chart.line.uptrend.xyaxis"
    var couleur: Color = .nutriGreen
    let content: Content

    init(
        titre: String,
        sousTitre: String = "",
        icone: String = "chart.line.uptrend.xyaxis",
        couleur: Color = .nutriGreen,
        @ViewBuilder content: () -> Content
    ) {
        self.titre = titre
        self.sousTitre = sousTitre
        self.icone = icone
        self.couleur = couleur
        self.content = content()
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Label(titre, systemImage: icone)
                        .font(.nutriHeadline)
                        .foregroundStyle(couleur)
                    Spacer()
                    if !sousTitre.isEmpty {
                        Text(sousTitre)
                            .font(.nutriCaption)
                            .foregroundStyle(.secondary)
                    }
                }
                content
            }
        }
    }
}
