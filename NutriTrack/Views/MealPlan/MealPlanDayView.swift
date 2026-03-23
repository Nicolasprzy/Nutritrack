import SwiftUI
import SwiftData

struct MealPlanDayView: View {
    @Environment(\.modelContext) private var modelContext

    let jour: Int
    let plans: [MealPlan]
    let semaineCourante: Date
    var onAjouter: ((Int, String) -> Void)? = nil
    var onSupprimer: ((MealPlan) -> Void)? = nil

    private let joursLabels = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]

    var jourLabel: String {
        guard jour >= 0 && jour < joursLabels.count else { return "?" }
        return joursLabels[jour]
    }

    var jourDate: Date? {
        Calendar.current.date(byAdding: .day, value: jour, to: semaineCourante)
    }

    var totalCalories: Double {
        plans.reduce(0) { $0 + $1.caloriesEstimees }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // En-tête du jour
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(jourLabel)
                            .font(.nutriHeadline)
                        if let date = jourDate {
                            Text(date.formatCourt)
                                .font(.nutriCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if totalCalories > 0 {
                        Text("\(totalCalories.arrondi(0)) kcal")
                            .font(.nutriCaption)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Repas planifiés par type
                ForEach(MealType.allCases, id: \.self) { mealType in
                    let plansRepas = plans.filter { $0.mealType == mealType.rawValue }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Label(mealType.label, systemImage: mealType.icon)
                                .font(.nutriCaption)
                                .foregroundStyle(mealType.couleur)

                            Spacer()

                            Button(action: {
                                onAjouter?(jour, mealType.rawValue)
                            }) {
                                Image(systemName: "plus")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Ajouter \(mealType.label)")
                        }

                        if plansRepas.isEmpty {
                            Text("—")
                                .font(.nutriCaption)
                                .foregroundStyle(.tertiary)
                                .padding(.leading, Spacing.md)
                        } else {
                            ForEach(plansRepas) { plan in
                                HStack {
                                    Text(plan.title.isEmpty ? "Repas planifié" : plan.title)
                                        .font(.nutriCaption)
                                        .padding(.leading, Spacing.md)
                                        .lineLimit(1)
                                    Spacer()
                                    if plan.caloriesEstimees > 0 {
                                        Text("\(plan.caloriesEstimees.arrondi(0)) kcal")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        onSupprimer?(plan)
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
