import SwiftUI

/// En-tête de section cinématographique — style Lumina.
///
/// - `eyebrow`  : label monospace majuscule corail (ex: "Acte I · Tableau de bord")
/// - `title`    : première ligne display serif
/// - `emphasis` : deuxième ligne italique en dégradé corail (optionnel)
/// - `subtitle` : paragraphe secondaire (optionnel)
struct LuminaSectionHeader: View {
    let eyebrow:  String
    let title:    String
    var emphasis: String? = nil
    var subtitle: String? = nil

    @State private var appeared = false

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {

                // ── Eyebrow ──────────────────────────────────────────────────
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.luminaEmber)
                        .frame(width: 32, height: 1)
                    Text(eyebrow.uppercased())
                        .font(.luminaEyebrow)
                        .tracking(4)
                        .foregroundStyle(Color.luminaEmber)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.easeOut(duration: 0.8).delay(0.15), value: appeared)
                .padding(.bottom, 16)

                // ── Titre ────────────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.luminaDisplay(56))
                        .foregroundStyle(Color.luminaInkPrimary)
                        .lineLimit(2)

                    if let emphasis {
                        Text(emphasis)
                            .font(.luminaDisplay(56))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.luminaEmberHot, Color.luminaEmberSoft],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .lineLimit(1)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.easeOut(duration: 1.0).delay(0.25), value: appeared)

                // ── Sous-titre ───────────────────────────────────────────────
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.luminaInkMuted)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 18)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.easeOut(duration: 0.9).delay(0.45), value: appeared)
                }
            }

            Spacer()

            // ── Date / heure ─────────────────────────────────────────────────
            VStack(alignment: .trailing, spacing: 4) {
                Text(Date().formatted(.dateTime.hour().minute()))
                    .font(.luminaMono(12))
                    .foregroundStyle(Color.luminaInkMuted)
                    .tracking(3)
                Text(Date().formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                    .font(.luminaDisplay(18))
                    .foregroundStyle(Color.luminaInkPrimary)
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.8).delay(0.5), value: appeared)
        }
        .padding(.bottom, 48)
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
    }
}

#Preview {
    ZStack {
        AmbientBackground()
        LuminaSectionHeader(
            eyebrow: "Acte I · Tableau de bord",
            title: "Bonsoir,",
            emphasis: "Nicolas.",
            subtitle: "Vous êtes à 4.5 kg de votre objectif. La discipline de cette semaine est remarquable."
        )
        .padding(48)
    }
    .frame(width: 900, height: 280)
}
