import SwiftUI

// MARK: - NutriStepper

struct NutriStepper<Value: Numeric & Comparable>: View {
    let title: String
    @Binding var value: Value
    let step: Value
    let range: ClosedRange<Value>
    var suffix: String? = nil
    var format: String = "%.0f"

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if !title.isEmpty {
                Text(title)
                    .font(.nutriCaption)
                    .foregroundStyle(Color.nutriTextSecondary)
            }

            HStack(spacing: Spacing.md) {
                stepButton(icon: "minus", disabled: value <= range.lowerBound) {
                    decrement()
                }

                HStack(spacing: Spacing.xs) {
                    Text(formattedValue)
                        .font(.nutriHeadline)
                        .foregroundStyle(Color.nutriTextPrimary)
                        .monospacedDigit()
                        .frame(minWidth: 60)
                    if let suffix {
                        Text(suffix)
                            .font(.nutriCaption)
                            .foregroundStyle(Color.nutriTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity)

                stepButton(icon: "plus", disabled: value >= range.upperBound) {
                    increment()
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Color.nutriSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
        }
    }

    private var formattedValue: String {
        if let d = value as? Double { return String(format: format, d) }
        if let i = value as? Int { return "\(i)" }
        return "\(value)"
    }

    private func increment() {
        let newValue = value + step
        if newValue <= range.upperBound { value = newValue }
    }

    private func decrement() {
        let newValue = value - step
        if newValue >= range.lowerBound { value = newValue }
    }

    private func stepButton(icon: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 28, height: 28)
                .foregroundStyle(Color.nutriGreen)
                .background(Color.nutriGreen.opacity(0.15))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1.0)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        NutriStepper(
            title: "Heures de sommeil",
            value: .constant(7.5),
            step: 0.5,
            range: 0...14,
            suffix: "h",
            format: "%.1f"
        )
        NutriStepper(
            title: "FC repos",
            value: .constant(62),
            step: 1,
            range: 40...120,
            suffix: "bpm"
        )
    }
    .padding(Spacing.lg)
    .frame(width: 400)
}
