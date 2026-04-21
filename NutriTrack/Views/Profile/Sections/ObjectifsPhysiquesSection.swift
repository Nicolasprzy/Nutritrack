import SwiftUI
import SwiftData

struct ObjectifsPhysiquesSection: View {
    @Bindable var profil: UserProfile
    @Environment(\.modelContext) private var modelContext

    @State private var poidsStr: String = ""
    @State private var bfStr: String = ""
    @State private var dateCible: Date = Date()
    @State private var messageSauvegarde: String?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Objectifs physiques", systemImage: "figure.arms.open")
                    .font(.nutriHeadline)
                    .foregroundStyle(.blue)

                NutriField("Poids cible", text: $poidsStr, variant: .decimal, suffix: "kg")
                NutriField("% masse grasse cible", text: $bfStr, variant: .decimal, suffix: "%")
                NutriDatePicker(title: "Date cible", date: $dateCible, style: .inline)

                NutriButton("Enregistrer objectifs", icon: "checkmark.circle.fill", style: .primary) {
                    sauvegarder()
                }

                if let msg = messageSauvegarde {
                    Text(msg)
                        .font(.nutriCaption)
                        .foregroundStyle(Color.nutriSuccess)
                }
            }
        }
        .onAppear { chargerValeurs() }
    }

    private func chargerValeurs() {
        if let p = profil.targetWeightKg { poidsStr = String(format: "%.1f", p) }
        if let bf = profil.targetBodyFatPct { bfStr = String(format: "%.1f", bf) }
        if let d = profil.targetDate { dateCible = d }
    }

    private func sauvegarder() {
        profil.targetWeightKg = Double(poidsStr.replacingOccurrences(of: ",", with: "."))
        profil.targetBodyFatPct = Double(bfStr.replacingOccurrences(of: ",", with: "."))
        profil.targetDate = dateCible
        try? modelContext.save()
        messageSauvegarde = "✓ Objectifs sauvegardés"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if messageSauvegarde == "✓ Objectifs sauvegardés" { messageSauvegarde = nil }
        }
    }
}
