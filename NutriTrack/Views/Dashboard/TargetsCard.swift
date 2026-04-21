import SwiftUI

struct TargetsCard: View {
    let dayContext: DayContext?
    let target: MacroTarget?
    let consumedKcal: Int
    let consumedProteinG: Int
    let onSelectCTA: () -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                header
                Divider()
                if let target, dayContext != nil {
                    progressLine(
                        label: "Calories",
                        consumed: consumedKcal,
                        target: target.targetKcal,
                        unit: "kcal"
                    )
                    progressLine(
                        label: "Protéines",
                        consumed: consumedProteinG,
                        target: target.targetProteinG,
                        unit: "g"
                    )
                } else {
                    emptyCTA
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "target")
                .foregroundStyle(Color.nutriGreen)
            Text(titleText)
                .font(.nutriHeadline)
        }
    }

    private var titleText: String {
        if let ctx = dayContext,
           let type = DayType(rawValue: ctx.dayType) {
            return "Aujourd'hui — \(type.displayName)"
        }
        return "Aujourd'hui"
    }

    private var emptyCTA: some View {
        Button(action: onSelectCTA) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "hand.tap.fill")
                Text("Sélectionne ton type de jour pour voir les cibles")
                    .font(.nutriCaption)
            }
            .foregroundStyle(.secondary)
            .padding(Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.nutriSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        }
        .buttonStyle(.plain)
    }

    private func progressLine(label: String, consumed: Int, target: Int, unit: String) -> some View {
        let ratio: Double = target > 0 ? Double(consumed) / Double(target) : 0
        let color = barColor(ratio: ratio)
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(consumed) / \(target) \(unit)")
                    .font(.nutriBodyBold)
                    .foregroundStyle(color)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.nutriSurface)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * min(1.0, ratio), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private func barColor(ratio: Double) -> Color {
        if ratio < 0.85 { return .blue }
        if ratio > 1.10 { return Color.alerteOrange }
        return Color.nutriGreen
    }
}
