import SwiftUI

/// Carte verre dépoli — design Lumina (Her × Apple Vision Pro).
/// Fond blanc translucide chaud, bordure blanche, shimmer en haut,
/// elevation subtile au survol (macOS).
struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = Spacing.md
    var cornerRadius: CGFloat = Radius.lg

    @State private var isHovered = false

    init(
        padding: CGFloat = Spacing.md,
        cornerRadius: CGFloat = Radius.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .padding(padding)
            .background {
                ZStack {
                    // Fond blanc translucide
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(isHovered ? 0.72 : 0.56))

                    // Material blur derrière
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.regularMaterial.opacity(0.5))

                    // Bordure blanche brillante
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.white.opacity(0.82), lineWidth: 1)

                    // Shimmer horizontal en haut de la carte
                    VStack {
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.9), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 1)
                        Spacer()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
            }
            // Ombre chaude multicouche
            .shadow(
                color: Color.luminaInkPrimary.opacity(0.03),
                radius: 1, x: 0, y: 1
            )
            .shadow(
                color: Color.luminaInkPrimary.opacity(isHovered ? 0.07 : 0.04),
                radius: isHovered ? 32 : 16,
                x: 0, y: isHovered ? 12 : 6
            )
            // Légère élévation au survol
            .scaleEffect(isHovered ? 1.003 : 1.0)
            .animation(.spring(response: 0.45, dampingFraction: 0.72), value: isHovered)
            #if os(macOS)
            .onHover { isHovered = $0 }
            #endif
    }
}

#Preview {
    ZStack {
        AmbientBackground()
        VStack(spacing: 16) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.luminaEmber)
                            .frame(width: 6, height: 6)
                            .shadow(color: .luminaEmber, radius: 4)
                        Text("POIDS ACTUEL")
                            .font(.luminaCardLabel)
                            .foregroundStyle(Color.luminaInkMuted)
                            .tracking(3)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("81.5")
                            .font(.luminaDisplay(64))
                            .foregroundStyle(Color.luminaInkPrimary)
                        Text("kg")
                            .font(.luminaMono(14))
                            .foregroundStyle(Color.luminaInkMuted)
                    }
                }
            }
            .frame(width: 240)
        }
        .padding(40)
    }
    .frame(width: 400, height: 300)
}
