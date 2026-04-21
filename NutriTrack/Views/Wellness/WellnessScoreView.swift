import SwiftUI
import SwiftData
import Charts

struct WellnessScoreView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.activeProfileID) private var activeProfileID
    @Query(sort: \WellnessScore.date, order: .reverse) private var tousScores: [WellnessScore]

    @State private var showAdd = false

    private var scoresProfile: [WellnessScore] {
        tousScores.filter { $0.profileID == activeProfileID }
    }

    private var scoreAujourdhui: WellnessScore? {
        scoresProfile.first(where: { Calendar.current.isDateInToday($0.date) })
    }

    private var derniers14Jours: [WellnessScore] {
        guard let debut = Calendar.current.date(byAdding: .day, value: -13, to: Date().debutDeJour) else {
            return []
        }
        return scoresProfile
            .filter { $0.date >= debut }
            .sorted(by: { $0.date < $1.date })
    }

    private var moyenne7Jours: Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -6, to: Date().debutDeJour) ?? Date()
        let recents = scoresProfile.filter { $0.date >= cutoff }
        guard !recents.isEmpty else { return 0 }
        let total = recents.reduce(0.0) { $0 + $1.scoreGlobal }
        return total / Double(recents.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Label("Wellness", systemImage: "heart.text.square.fill")
                    .font(.nutriHeadline)
                    .foregroundStyle(.pink)
                Spacer()
                Button(action: { showAdd = true }) {
                    Label(
                        scoreAujourdhui == nil ? "Saisir score" : "Modifier",
                        systemImage: scoreAujourdhui == nil ? "plus.circle.fill" : "pencil.circle.fill"
                    )
                    .font(.nutriCaption)
                    .foregroundStyle(.pink)
                }
                .buttonStyle(.plain)
            }

            if scoresProfile.isEmpty {
                Text("Aucun score enregistré. Saisissez votre premier score du jour.")
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, Spacing.xs)
            } else {
                resumeAujourdhui
                Divider()
                graphique14Jours
            }
        }
        .nutriSheet(title: scoreAujourdhui == nil ? "Score du jour" : "Modifier le score",
                    size: .standard,
                    isPresented: $showAdd) {
            AddWellnessScoreView(existant: scoreAujourdhui)
        }
    }

    // MARK: - Résumé

    private var resumeAujourdhui: some View {
        HStack(spacing: Spacing.md) {
            scoreBadge("Aujourd'hui", score: scoreAujourdhui?.scoreGlobal, couleur: .pink)
            Divider().frame(height: 42)
            scoreBadge("7 jours (moy.)", score: moyenne7Jours > 0 ? moyenne7Jours : nil, couleur: .purple)
            Divider().frame(height: 42)
            VStack(spacing: Spacing.xxs) {
                Text("\(scoresProfile.count)")
                    .font(.nutriTitle2)
                    .monospacedDigit()
                Text("saisies")
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func scoreBadge(_ label: String, score: Double?, couleur: Color) -> some View {
        VStack(spacing: 2) {
            if let s = score {
                Text(String(format: "%.1f", s))
                    .font(.nutriTitle2)
                    .foregroundStyle(couleur)
                    .monospacedDigit()
            } else {
                Text("—")
                    .font(.nutriTitle2)
                    .foregroundStyle(.secondary)
            }
            Text(label)
                .font(.nutriCaption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Graphique

    private var graphique14Jours: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Score global — 14 derniers jours")
                .font(.nutriCaption)
                .foregroundStyle(.secondary)

            if derniers14Jours.isEmpty {
                Text("Pas de données sur 14 jours")
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
                    .frame(height: 80)
            } else {
                Chart(derniers14Jours, id: \.date) { score in
                    LineMark(
                        x: .value("Jour", score.date, unit: .day),
                        y: .value("Score", score.scoreGlobal)
                    )
                    .foregroundStyle(Color.pink.gradient)
                    .symbol(Circle().strokeBorder(lineWidth: 2))

                    AreaMark(
                        x: .value("Jour", score.date, unit: .day),
                        y: .value("Score", score.scoreGlobal)
                    )
                    .foregroundStyle(Color.pink.opacity(0.12).gradient)
                }
                .chartYScale(domain: 0...10)
                .frame(height: 100)
            }
        }
    }
}

#Preview {
    GlassCard {
        WellnessScoreView()
    }
    .padding()
    .modelContainer(for: [WellnessScore.self, UserProfile.self], inMemory: true)
}
