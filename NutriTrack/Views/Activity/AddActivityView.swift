import SwiftUI
import SwiftData

struct AddActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.activeProfileID) private var activeProfileID
    @Query(sort: \BodyMetric.date, order: .reverse) private var metrics: [BodyMetric]

    @State private var typeActivite: String = "Course à pied"
    @State private var dureeMinutes: Int = 30
    @State private var caloriesBrulees: Double = 0
    @State private var notes: String = ""
    @State private var calcul_auto: Bool = true

    let typesPredefinis = [
        "Course à pied", "Marche", "Musculation", "Vélo",
        "Natation", "Yoga", "HIIT", "Autre"
    ]

    private var dernierPoids: Double { metrics.first?.weight ?? 75.0 }

    private var caloriesCalculees: Double {
        guard calcul_auto else { return caloriesBrulees }
        return NutritionCalculator.caloriesBrulees(
            activite: typeActivite,
            dureeMin: dureeMinutes,
            poidsKg: dernierPoids
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Titre
            HStack {
                Text("Ajouter une activité")
                    .font(.nutriTitle2)
                    .padding(.leading, Spacing.lg)
                Spacer()
                Button("Annuler") { dismiss() }
                    .padding(.trailing, Spacing.lg)
            }
            .padding(.vertical, Spacing.md)
            .background(.ultraThinMaterial)

            Divider()

            ScrollView {
                VStack(spacing: Spacing.md) {

                    // Type
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Label("Type d'activité", systemImage: "figure.mixed.cardio")
                                .font(.nutriHeadline)
                                .foregroundStyle(.red)

                            Divider()

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                                ForEach(typesPredefinis, id: \.self) { type in
                                    Button(action: { typeActivite = type }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: iconeActivite(type))
                                                .font(.system(size: 14))
                                            Text(type)
                                                .font(.nutriCaption)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 6)
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
                    }

                    // Durée
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Label("Durée", systemImage: "timer")
                                .font(.nutriHeadline)
                                .foregroundStyle(.orange)

                            Divider()

                            HStack {
                                Text("Durée")
                                Spacer()
                                Stepper("\(dureeMinutes) min",
                                        value: $dureeMinutes, in: 1...300, step: 5)
                            }

                            Slider(value: Binding(
                                get: { Double(dureeMinutes) },
                                set: { dureeMinutes = Int($0) }
                            ), in: 5...180, step: 5)
                            .tint(.orange)
                        }
                    }

                    // Calories
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Label("Calories brûlées", systemImage: "flame.fill")
                                .font(.nutriHeadline)
                                .foregroundStyle(.orange)

                            Divider()

                            HStack {
                                Text("Calcul automatique")
                                Spacer()
                                Toggle("", isOn: $calcul_auto).labelsHidden()
                            }

                            if calcul_auto {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Estimation")
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
                                HStack {
                                    Text("Calories brûlées")
                                    Spacer()
                                    TextField("0", value: $caloriesBrulees,
                                              format: .number.precision(.fractionLength(0)))
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 80)
                                    Text("kcal").foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // Notes
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Label("Notes", systemImage: "note.text")
                                .font(.nutriHeadline)
                                .foregroundStyle(.gray)
                            Divider()
                            TextEditor(text: $notes)
                                .frame(minHeight: 50, maxHeight: 80)
                                .font(.nutriBody)
                        }
                    }
                }
                .padding(Spacing.lg)
            }

            Divider()

            HStack {
                Spacer()
                Button(action: enregistrer) {
                    Text("Enregistrer")
                        .font(.nutriHeadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.red, in: RoundedRectangle(cornerRadius: Radius.md))
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg)
            .background(.ultraThinMaterial)
        }
        .frame(minWidth: 460, idealWidth: 520, minHeight: 540)
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
            caloriesBurned:  calcul_auto ? caloriesCalculees : caloriesBrulees,
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
