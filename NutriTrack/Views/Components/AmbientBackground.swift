import SwiftUI

/// Fond ambiant Lumina — 3 blobs de lumière chaude animés en continu.
/// À placer en ZStack sous tout le contenu de l'app.
struct AmbientBackground: View {

    @State private var t: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.luminaBgDeep.ignoresSafeArea()

                // Blob 1 — corail pêche, haut-droite
                blob(
                    color: Color(red: 1.00, green: 0.71, blue: 0.60),
                    x:  geo.size.width * 0.65 + sin(t)         * 60,
                    y:  geo.size.height * 0.05 + cos(t * 0.7)  * 50,
                    size: min(geo.size.width, geo.size.height) * 0.75
                )

                // Blob 2 — pêche doux, bas-droite
                blob(
                    color: Color(red: 1.00, green: 0.79, blue: 0.70),
                    x:  geo.size.width * 0.80 + cos(t * 0.85)  * 50,
                    y:  geo.size.height * 0.75 + sin(t * 1.1)  * 40,
                    size: min(geo.size.width, geo.size.height) * 0.60
                )

                // Blob 3 — crème ambre, gauche
                blob(
                    color: Color(red: 1.00, green: 0.83, blue: 0.72),
                    x:  geo.size.width * 0.12 + sin(t * 1.3)  * 40,
                    y:  geo.size.height * 0.45 + cos(t * 0.9) * 55,
                    size: min(geo.size.width, geo.size.height) * 0.65
                )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 28).repeatForever(autoreverses: false)) {
                t = .pi * 2
            }
        }
    }

    private func blob(color: Color, x: CGFloat, y: CGFloat, size: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(0.60))
            .frame(width: size, height: size)
            .blur(radius: size * 0.22)
            .position(x: x, y: y)
    }
}

// Grain film très subtil — texture organique par-dessus tout
struct GrainOverlay: View {
    var body: some View {
        Canvas { ctx, size in
            // Petits pixels semi-transparents aléatoires
            var rng = SystemRandomNumberGenerator()
            for _ in 0..<Int(size.width * size.height / 600) {
                let x = CGFloat.random(in: 0..<size.width,  using: &rng)
                let y = CGFloat.random(in: 0..<size.height, using: &rng)
                let opacity = Double.random(in: 0.01...0.04, using: &rng)
                ctx.fill(
                    Path(CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(Color.luminaInkPrimary.opacity(opacity))
                )
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

#Preview {
    AmbientBackground()
        .frame(width: 900, height: 600)
}
