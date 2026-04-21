import SwiftUI
import SwiftData

struct MealPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.activeProfileID) private var activeProfileID

    @Query private var allTemplates: [MealTemplate]
    @Query private var profiles: [UserProfile]

    private var templates: [MealTemplate] {
        allTemplates.filter { $0.profileID == activeProfileID && $0.isActive }
    }

    private var profilActif: UserProfile? {
        profiles.first(where: { $0.profileID.uuidString == activeProfileID })
    }

    private func templatesFor(_ mealType: TemplateMealType) -> [MealTemplate] {
        templates
            .filter { $0.mealType == mealType.rawValue }
            .sorted { ($0.rotationTag ?? "") < ($1.rotationTag ?? "") }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                entete

                if templates.isEmpty {
                    emptyState
                } else {
                    ForEach(TemplateMealType.allCases) { mealType in
                        let tplsForMeal = templatesFor(mealType)
                        if !tplsForMeal.isEmpty {
                            sectionPourRepas(mealType, templates: tplsForMeal)
                        }
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .navigationTitle("Plan nutrition")
        .background(Color.fondPrincipal)
    }

    private var entete: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.nutriGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text("Plan semaine type")
                    .font(.nutriTitle2)
                Text("Templates de repas et rotations")
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: Spacing.md) {
                Image(systemName: "tray")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Aucun template de repas")
                    .font(.nutriHeadline)
                Text("Initialise le plan nutrition depuis ton profil pour commencer.")
                    .font(.nutriBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let profil = profilActif {
                    NutriButton(
                        "Initialiser le plan",
                        icon: "square.and.arrow.down.fill",
                        style: .primary
                    ) {
                        NutritionPlanSeeder.seedMinimalPlan(for: profil, context: modelContext)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.lg)
        }
    }

    private func sectionPourRepas(_ mealType: TemplateMealType, templates: [MealTemplate]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            NutriSectionHeader(mealType.displayName, icon: mealType.icon)
            ForEach(templates) { tpl in
                templateCard(tpl)
            }
        }
    }

    private func templateCard(_ tpl: MealTemplate) -> some View {
        let items = (tpl.items ?? []).sorted(by: { $0.orderIndex < $1.orderIndex })
        let totalP = items.reduce(0.0) { $0 + $1.proteinG }
        let totalG = items.reduce(0.0) { $0 + $1.carbsG }
        let totalL = items.reduce(0.0) { $0 + $1.fatG }
        let totalKcal = items.reduce(0) { $0 + $1.kcal }

        return GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text(tpl.name)
                        .font(.nutriHeadline)
                    Spacer()
                    if let hint = tpl.dayOfWeekHint {
                        Text(hint)
                            .font(.nutriCaption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, 3)
                            .background(Color.nutriSurface)
                            .clipShape(Capsule())
                    }
                }

                Divider()

                ForEach(items) { item in
                    HStack {
                        Text(item.foodName)
                            .font(.nutriBody)
                        Spacer()
                        Text("\(Int(item.quantityG.rounded())) g")
                            .font(.nutriCaption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                Divider()

                HStack(spacing: Spacing.md) {
                    macroBadge("P", value: totalP, color: Color.proteineColor)
                    macroBadge("G", value: totalG, color: Color.glucideColor)
                    macroBadge("L", value: totalL, color: Color.lipideColor)
                    Spacer()
                    Text("\(totalKcal) kcal")
                        .font(.nutriBodyBold)
                        .foregroundStyle(Color.nutriGreen)
                        .monospacedDigit()
                }
            }
        }
    }

    private func macroBadge(_ label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.nutriCaption2)
                .foregroundStyle(color)
                .fontWeight(.bold)
            Text("\(Int(value.rounded()))g")
                .font(.nutriCaption)
                .foregroundStyle(Color.nutriTextPrimary)
                .monospacedDigit()
        }
    }
}

#Preview {
    NavigationStack {
        MealPlanView()
    }
}
