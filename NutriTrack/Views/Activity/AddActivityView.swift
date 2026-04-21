import SwiftUI
import SwiftData

struct AddActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.activeProfileID) private var activeProfileID
    @Query(sort: \BodyMetric.date, order: .reverse) private var metrics: [BodyMetric]

    @State private var typeActivite: String = "Course à pied"
    @State private var dureeMinutes: Int = 30
    @State private var caloriesBrulees: Int = 0
    @State private var caloriesTexte: String = "0"
    @State private var notes: String = ""
    @State private var calcul_auto: Bool = true

    let typesPredefinis = [
        "Course à pied", "Marche", "Musculation", "Vélo",
        "Natation", "Yoga", "HIIT", "Autre"
    ]

    private var dernierPoids: Double { metrics.first?.weight ?? 75.0 }

    private var caloriesCalculees: Double {
        guard calcul_auto else { return Double(caloriesBrulees) }
        return NutritionCalculator.caloriesBrulees(
            activite: typeActivite,
            dureeMin: dureeMinutes,
            poidsKg: dernierPoids
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {

            // ── Type d'activité ──────────────────────────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                NutriSectionHeader("Type d'activité", icon: "figure.mixed.cardio")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                    ForEach(typesPredefinis, id: \.self) { type in
                        Button(action: { typeActivite = type }) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: iconeActivite(type))
                                    .font(.nutriBody)
                                Text(type)
                                    .font(.nutriCaption)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .padding(.horizontal, Spacing.sm)
                            .background(
                                typeActivite == type
                                    ? Color.red.opacity(0.15)
                                    : Color.secondary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: Radius.sm)
                            )
                            .foregroundStyle(typeActivite == type ? .red : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // ── Durée ────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                NutriSectionHeader("Durée", icon: "timer")

                NutriStepper(
                    title: "Durée",
                    value: $dureeMinutes,
                    step: 5,
                    range: 1...300,
                    suffix: "min"
                )
            }

            // ── Calories ─────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                NutriSectionHeader("Calories brûlées", icon: "flame.fill")

                HStack {
                    Text("Calcul automatique")
                        .font(.nutriBody)
                    Spacer()
                    Toggle("", isOn: $calcul_auto).labelsHidden()
                }

                if calcul_auto {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Estimation")
                                .font(.nutriBody)
                            Text("Basé sur votre poids (\(dernierPoids.arrondi(1)) kg)")
                                .font(.nutriCaption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(caloriesCalculees.arrondi(0)) kcal")
                            .font(.nutriTitle2)
                            .foregroundStyle(.orange)
                    }
                } else {
                    NutriField("Calories brûlées",
                               text: $caloriesTexte,
                               variant: .number,
                               placeholder: "0",
                               suffix: "kcal")
                        .onChange(of: caloriesTexte) { _, nouveau in
                            caloriesBrulees = Int(nouveau) ?? 0
                        }
                }
            }

            // ── Notes ────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                NutriSectionHeader("Notes", icon: "note.text")
                NutriField("", text: $notes, variant: .multiline(minLines: 2, maxLines: 4),
                           placeholder: "Ressenti, détails…")
            }

            // ── Bouton d'action ──────────────────────────────────────────
            NutriButton("Enregistrer",
                        icon: "checkmark.circle.fill",
                        style: .primary) {
                enregistrer()
            }
            .padding(.top, Spacing.sm)
        }
    }

    private func iconeActivite(_ type: String) -> String {
        switch type.lowercased() {
        case let s where s.contains("course"): return "figure.run"
        case let s where s.contains("marche"): return "figure.walk"
        case let s where s.contains("muscu"):  return "dumbbell.fill"
        case let s where s.contains("vélo"):   return "bicycle"
        case let s where s.contains("natation"): return "figure.pool.swim"
        case let s where s.contains("yoga"):   return "figure.mind.and.body"
        case let s where s.contains("hiit"):   return "flame.fill"
        default: return "figure.mixed.cardio"
        }
    }

    private func enregistrer() {
        let activite = ActivityEntry(
            date:            Date(),
            activityType:    typeActivite,
            durationMinutes: dureeMinutes,
            caloriesBurned:  calcul_auto ? caloriesCalculees : Double(caloriesBrulees),
            notes:           notes
        )
        activite.profileID = activeProfileID
        modelContext.insert(activite)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddActivityView()
        .modelContainer(for: [ActivityEntry.self, BodyMetric.self], inMemory: true)
}
