import SwiftUI

// MARK: - NutriSlider
// Slider 1-10 pour scores Wellness.

struct NutriSlider: View {
    let title: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...10
    var invertColors: Bool = false
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                }
                Text(title)
                    .font(.nutriBody)
                    .foregroundStyle(Color.nutriTextPrimary)
                Spacer()
                Text("\(value)")
                    .font(.nutriHeadline)
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text("/\(range.upperBound)")
                    .font(.nutriCaption)
                    .foregroundStyle(Color.nutriTextSecondary)
            }

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0.rounded()) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(color)
        }
    }

    private var color: Color {
        let normalized = Double(value - range.lowerBound) / Double(range.upperBound - range.lowerBound)
        let effective = invertColors ? (1 - normalized) : normalized
        return Color(
            red: 1 - effective * 0.8,
            green: effective,
            blue: 0.2
        )
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        NutriSlider(title: "Énergie", value: .constant(7), icon: "bolt.fill")
        NutriSlider(title: "Humeur", value: .constant(8), icon: "face.smiling.fill")
        NutriSlider(title: "Sommeil", value: .constant(6), icon: "moon.zzz.fill")
        NutriSlider(title: "Courbatures", value: .constant(4), invertColors: true, icon: "figure.walk")
    }
    .padding(Spacing.lg)
    .frame(width: 400)
}
