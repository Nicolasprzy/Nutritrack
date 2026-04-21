import SwiftUI

/// Anneau central style Apple Fitness — calories + macros
struct MacroRingView: View {
    let caloriesConsommees: Double
    let caloriesObjectif: Double
    let proteines: Double
    let objectifProteines: Double
    let glucides: Double
    let objectifGlucides: Double
    let lipides: Double
    let objectifLipides: Double

    private var progressionCalories: Double {
        min(caloriesConsommees / max(caloriesObjectif, 1), 1.0)
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let outerRadius = size / 2 - 12
            let ringWidth = size * 0.09
            let macroWidth = size * 0.07
            let gap = size * 0.055

            ZStack {
                macroAnneau(
                    progression: lipides.progression(sur: objectifLipides),
                    couleur: .lipideColor,
                    rayon: outerRadius - ringWidth - gap * 2 - macroWidth * 2,
                    lineWidth: macroWidth
                )
                macroAnneau(
                    progression: glucides.progression(sur: objectifGlucides),
                    couleur: .glucideColor,
                    rayon: outerRadius - ringWidth - gap - macroWidth,
                    lineWidth: macroWidth
                )
                macroAnneau(
                    progression: proteines.progression(sur: objectifProteines),
                    couleur: .proteineColor,
                    rayon: outerRadius - ringWidth - gap / 2,
                    lineWidth: macroWidth
                )
                calorieRing(radius: outerRadius, lineWidth: ringWidth)
                texteCenter
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    private func calorieRing(radius: CGFloat, lineWidth: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.nutriGreen.opacity(0.15), lineWidth: lineWidth)
                .frame(width: radius * 2, height: radius * 2)
            Circle()
                .trim(from: 0, to: progressionCalories)
                .stroke(
                    AngularGradient(colors: [.nutriGreenDark, .nutriGreen], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progressionCalories)
        }
    }

    private func macroAnneau(progression: Double, couleur: Color, rayon: CGFloat, lineWidth: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(couleur.opacity(0.15), lineWidth: lineWidth)
                .frame(width: rayon * 2, height: rayon * 2)
            Circle()
                .trim(from: 0, to: max(progression, 0))
                .stroke(couleur, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: rayon * 2, height: rayon * 2)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progression)
        }
    }

    private var texteCenter: some View {
        VStack(spacing: 2) {
            Text(caloriesConsommees.arrondi(0))
                .font(.system(size: 26, weight: .bold, design: .rounded)) // calibrage visuel centre ring — justifié
                .monospacedDigit()
            Text("kcal")
                .font(.nutriCaption2)
                .foregroundStyle(.secondary)
            Text("/ \(caloriesObjectif.arrondi(0))")
                .font(.nutriCaption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

// MARK: - Légende macros

struct MacroRingLegende: View {
    let proteines: Double
    let glucides: Double
    let lipides: Double

    var body: some View {
        HStack(spacing: Spacing.lg) {
            legendeItem(couleur: .proteineColor, nom: "Protéines", valeur: proteines)
            legendeItem(couleur: .glucideColor,  nom: "Glucides",  valeur: glucides)
            legendeItem(couleur: .lipideColor,   nom: "Lipides",   valeur: lipides)
        }
    }

    private func legendeItem(couleur: Color, nom: String, valeur: Double) -> some View {
        HStack(spacing: 6) {
            Circle().fill(couleur).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(valeur.arrondi(0)) g")
                    .font(.nutriBodyBold)
                Text(nom)
                    .font(.nutriCaption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MacroRingView(
            caloriesConsommees: 1450, caloriesObjectif: 2000,
            proteines: 95, objectifProteines: 150,
            glucides: 155, objectifGlucides: 200,
            lipides: 52, objectifLipides: 65
        )
        .frame(width: 280, height: 280)
        MacroRingLegende(proteines: 95, glucides: 155, lipides: 52)
    }
    .padding()
}
