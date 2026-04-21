import SwiftUI
import SwiftData

struct PlanNutritionActionsSection: View {
    @Bindable var profil: UserProfile
    @Environment(\.modelContext) private var modelContext
    @State private var showResetConfirm = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Plan nutrition", systemImage: "leaf.circle.fill")
                    .font(.nutriHeadline)
                    .foregroundStyle(.cyan)

                HStack {
                    Text("Statut")
                        .font(.nutriBody)
                    Spacer()
                    Text(profil.planSeeded ? "Initialisé" : "Non initialisé")
                        .font(.nutriCaption)
                        .foregroundStyle(profil.planSeeded ? Color.nutriGreen : .secondary)
                }

                if !profil.planSeeded {
                    NutriButton(
                        "Initialiser le plan nutrition",
                        icon: "square.and.arrow.down.fill",
                        style: .primary
                    ) {
                        NutritionPlanSeeder.seedMinimalPlan(for: profil, context: modelContext)
                    }
                } else {
                    NutriButton(
                        "Réinitialiser le plan",
                        icon: "arrow.counterclockwise.circle.fill",
                        style: .destructive
                    ) {
                        showResetConfirm = true
                    }
                }
            }
        }
        .nutriConfirm(
            title: "Réinitialiser le plan ?",
            message: "Cette action supprime toutes tes cibles macro et templates de repas. Tu pourras recommencer depuis zéro.",
            destructive: true,
            confirmLabel: "Réinitialiser",
            isPresented: $showResetConfirm
        ) {
            NutritionPlanSeeder.resetPlan(for: profil, context: modelContext)
        }
    }
}
