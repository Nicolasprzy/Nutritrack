import SwiftUI
import SwiftData

struct MacroTargetEditView: View {
    @Bindable var target: MacroTarget
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var kcalStr: String = ""
    @State private var proteinStr: String = ""
    @State private var carbsStr: String = ""
    @State private var fatStr: String = ""

    private var dayTypeEnum: DayType? {
        DayType(rawValue: target.dayType)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Label(dayTypeEnum?.displayName ?? target.dayType, systemImage: "target")
                .font(.nutriHeadline)
                .foregroundStyle(Color.nutriGreen)

            VStack(spacing: Spacing.md) {
                NutriField("Calories cible", text: $kcalStr, variant: .number, suffix: "kcal")
                NutriField("Protéines cible", text: $proteinStr, variant: .number, suffix: "g")
                NutriField("Glucides cible", text: $carbsStr, variant: .number, suffix: "g")
                NutriField("Lipides cible", text: $fatStr, variant: .number, suffix: "g")
            }

            Spacer()

            NutriButton("Enregistrer", icon: "checkmark.circle.fill", style: .primary) {
                sauvegarder()
            }
        }
        .padding(Spacing.lg)
        .onAppear { chargerValeurs() }
    }

    private func chargerValeurs() {
        kcalStr = "\(target.targetKcal)"
        proteinStr = "\(target.targetProteinG)"
        carbsStr = "\(target.targetCarbsG)"
        fatStr = "\(target.targetFatG)"
    }

    private func sauvegarder() {
        target.targetKcal = Int(kcalStr) ?? target.targetKcal
        target.targetProteinG = Int(proteinStr) ?? target.targetProteinG
        target.targetCarbsG = Int(carbsStr) ?? target.targetCarbsG
        target.targetFatG = Int(fatStr) ?? target.targetFatG
        try? modelContext.save()
        dismiss()
    }
}
