import SwiftUI
import SwiftData

struct AddWellnessScoreView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.activeProfileID) private var activeProfileID
    @Environment(\.dismiss) private var dismiss

    let existant: WellnessScore?

    @State private var energy: Int = 5
    @State private var mood: Int = 5
    @State private var sleep: Int = 5
    @State private var soreness: Int = 5
    @State private var sleepHours: Double = 7
    @State private var restingHR: Int = 0
    @State private var hrvMs: Int = 0
    @State private var notes: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {

            // ── Scores du jour ───────────────────────────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                NutriSectionHeader("Scores du jour (1-10)")

                NutriSlider(title: "Énergie", value: $energy, icon: "bolt.fill")
                NutriSlider(title: "Humeur", value: $mood, icon: "face.smiling.fill")
                NutriSlider(title: "Qualité du sommeil", value: $sleep, icon: "bed.double.fill")
                NutriSlider(title: "Courbatures", value: $soreness, invertColors: true,
                            icon: "figure.strengthtraining.traditional")

                Text("Courbatures : 1 = aucune, 10 = très courbaturé")
                    .font(.nutriCaption2)
                    .foregroundStyle(Color.nutriTextSecondary)
            }

            // ── Données quantitatives ────────────────────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                NutriSectionHeader("Données quantitatives (optionnel)", icon: "chart.bar.fill")

                NutriStepper(
                    title: "Sommeil",
                    value: $sleepHours,
                    step: 0.5,
                    range: 0...14,
                    suffix: "h",
                    format: "%.1f"
                )
                NutriStepper(
                    title: "FC repos",
                    value: $restingHR,
                    step: 1,
                    range: 0...120,
                    suffix: "bpm"
                )
                NutriStepper(
                    title: "HRV",
                    value: $hrvMs,
                    step: 1,
                    range: 0...200,
                    suffix: "ms"
                )
            }

            // ── Notes ────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: Spacing.sm) {
                NutriSectionHeader("Notes", icon: "note.text")
                NutriField("", text: $notes, variant: .multiline(minLines: 3, maxLines: 6),
                           placeholder: "Ressenti, anecdote du jour…")
            }

            // ── Bouton d'action ──────────────────────────────────────────
            NutriButton("Enregistrer",
                        icon: "checkmark.circle.fill",
                        style: .primary) {
                enregistrer()
            }
            .padding(.top, Spacing.sm)
        }
        .onAppear(perform: charger)
    }

    // MARK: - Chargement

    private func charger() {
        guard let e = existant else { return }
        energy = e.energyScore
        mood = e.moodScore
        sleep = e.sleepScore
        soreness = e.sorenessScore
        sleepHours = e.sleepHours
        restingHR = e.restingHR
        hrvMs = e.hrvMs
        notes = e.notes
    }

    private func enregistrer() {
        if let e = existant {
            e.energyScore = energy
            e.moodScore = mood
            e.sleepScore = sleep
            e.sorenessScore = soreness
            e.sleepHours = sleepHours
            e.restingHR = restingHR
            e.hrvMs = hrvMs
            e.notes = notes
        } else {
            let nouveau = WellnessScore(
                profileID: activeProfileID,
                date: Date(),
                energyScore: energy,
                moodScore: mood,
                sleepScore: sleep,
                sorenessScore: soreness,
                sleepHours: sleepHours,
                restingHR: restingHR,
                hrvMs: hrvMs,
                notes: notes
            )
            modelContext.insert(nouveau)
        }
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddWellnessScoreView(existant: nil)
        .modelContainer(for: WellnessScore.self, inMemory: true)
}
