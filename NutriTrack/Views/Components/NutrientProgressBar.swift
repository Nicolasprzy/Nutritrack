import SwiftUI

struct NutrientProgressBar: View {
    let nom: String
    let consomme: Double
    let objectif: Double
    let couleur: Color
    var unite: String = "g"

    private var progression: Double {
        consomme.progression(sur: objectif)
    }

    private var estDepasse: Bool {
        consomme > objectif * 1.05
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(nom)
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(consomme.arrondi(0)) / \(objectif.arrondi(0)) \(unite)")
                    .font(.nutriCaption)
                    .foregroundStyle(estDepasse ? .red : .secondary)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Fond
                    RoundedRectangle(cornerRadius: 4)
                        .fill(couleur.opacity(0.15))
                        .frame(height: 8)

                    // Progression
                    RoundedRectangle(cornerRadius: 4)
                        .fill(estDepasse ? Color.red : couleur)
                        .frame(width: geo.size.width * progression, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: progression)
                }
            }
            .frame(height: 8)
        }
        .accessibilityLabel("\(nom) : \(consomme.arrondi(0)) \(unite) sur \(objectif.arrondi(0)) \(unite)")
    }
}

// MARK: - Groupe de macros

struct MacrosProgressGroup: View {
    let proteines: Double
    let objectifProteines: Double
    let glucides: Double
    let objectifGlucides: Double
    let lipides: Double
    let objectifLipides: Double

    var body: some View {
        VStack(spacing: Spacing.sm) {
            NutrientProgressBar(
                nom: "Protéines",
                consomme: proteines,
                objectif: objectifProteines,
                couleur: .proteineColor
            )
            NutrientProgressBar(
                nom: "Glucides",
                consomme: glucides,
                objectif: objectifGlucides,
                couleur: .glucideColor
            )
            NutrientProgressBar(
                nom: "Lipides",
                consomme: lipides,
                objectif: objectifLipides,
                couleur: .lipideColor
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        NutrientProgressBar(
            nom: "Protéines",
            consomme: 95,
            objectif: 150,
            couleur: .proteineColor
        )
        NutrientProgressBar(
            nom: "Glucides",
            consomme: 210,
            objectif: 200,
            couleur: .glucideColor
        )
        NutrientProgressBar(
            nom: "Lipides",
            consomme: 45,
            objectif: 65,
            couleur: .lipideColor
        )
    }
    .padding()
}
