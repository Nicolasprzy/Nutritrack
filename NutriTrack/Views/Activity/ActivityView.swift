import SwiftUI
import SwiftData
import Charts

struct ActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivityEntry.date, order: .reverse) private var activites: [ActivityEntry]

    @State private var showAddActivity = false

    private var activitesAujourdhui: [ActivityEntry] {
        activites.filter { Calendar.current.isDateInToday($0.date) }
    }

    private var totalCaloriesToday: Double {
        activitesAujourdhui.reduce(0) { $0 + $1.caloriesBurned }
    }

    private var totalMinutesToday: Int {
        activitesAujourdhui.reduce(0) { $0 + $1.durationMinutes }
    }

    // Données pour le graphique 7 jours
    private var donnees7Jours: [(date: Date, calories: Double)] {
        (0..<7).compactMap { i -> (Date, Double)? in
            guard let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) else { return nil }
            let cal = activites
                .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.caloriesBurned }
            return (date, cal)
        }.reversed()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                resumeAujourdhui
                graphique7Jours
                listeActivites
            }
            .padding(Spacing.md)
        }
        .navigationTitle("Activité physique")
        .background(Color.fondPrincipal)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddActivity = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.red)
                }
                .accessibilityLabel("Ajouter une activité")
            }
        }
        .sheet(isPresented: $showAddActivity) {
            AddActivityView()
        }
    }

    // MARK: - Résumé aujourd'hui

    private var resumeAujourdhui: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Aujourd'hui", systemImage: "calendar.badge.checkmark")
                    .font(.nutriHeadline)
                    .foregroundStyle(.red)

                HStack(spacing: Spacing.lg) {
                    statItem(
                        valeur: "\(totalCaloriesToday.arrondi(0))",
                        label: "kcal brûlées",
                        icone: "flame.fill",
                        couleur: .orange
                    )
                    Divider().frame(height: 50)
                    statItem(
                        valeur: "\(activitesAujourdhui.count)",
                        label: "activité(s)",
                        icone: "figure.mixed.cardio",
                        couleur: .red
                    )
                    Divider().frame(height: 50)
                    statItem(
                        valeur: formatDuree(totalMinutesToday),
                        label: "de sport",
                        icone: "timer",
                        couleur: .blue
                    )
                }

                if activitesAujourdhui.isEmpty {
                    ContentUnavailableView(
                        "Aucune activité aujourd'hui",
                        systemImage: "figure.walk.circle",
                        description: Text("Ajoutez votre première séance.")
                    )
                    .frame(height: 80)
                }
            }
        }
    }

    private func statItem(valeur: String, label: String, icone: String, couleur: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icone).foregroundStyle(couleur)
            Text(valeur).font(.nutriTitle2)
            Text(label).font(.nutriCaption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Graphique 7 jours

    private var graphique7Jours: some View {
        ChartCard(titre: "Calories brûlées — 7 jours", icone: "flame.fill", couleur: .orange) {
            if donnees7Jours.allSatisfy({ $0.calories == 0 }) {
                Text("Aucune activité cette semaine")
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
                    .frame(height: 100)
            } else {
                Chart(donnees7Jours, id: \.date) { point in
                    BarMark(
                        x: .value("Jour", point.date, unit: .day),
                        y: .value("Calories", point.calories)
                    )
                    .foregroundStyle(point.calories > 0 ? Color.orange : Color.secondary.opacity(0.3))
                    .cornerRadius(6)
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                    }
                }
            }
        }
    }

    // MARK: - Liste des activités

    @ViewBuilder
    private var listeActivites: some View {
        if activites.isEmpty {
            ContentUnavailableView(
                "Aucune activité enregistrée",
                systemImage: "figure.run.circle",
                description: Text("Commencez à suivre votre activité physique !")
            )
            .padding(.top, Spacing.xl)
        } else {
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Historique", systemImage: "list.bullet")
                        .font(.nutriHeadline)

                    ForEach(activites.prefix(20)) { activite in
                        ligneActivite(activite)
                        if activite.id != activites.prefix(20).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func ligneActivite(_ activite: ActivityEntry) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: activite.icone)
                .foregroundStyle(.red)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(activite.activityType)
                    .font(.nutriBody)
                Text(activite.date.formatMedium)
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(activite.caloriesBurned.arrondi(0)) kcal")
                    .font(.nutriBody)
                    .foregroundStyle(.orange)
                Text(activite.durationFormatted)
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                modelContext.delete(activite)
                try? modelContext.save()
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }

    private func formatDuree(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 { return "\(h)h\(m > 0 ? "\(m)m" : "")" }
        return "\(m)m"
    }
}

#Preview {
    NavigationStack {
        ActivityView()
            .modelContainer(for: [ActivityEntry.self, UserProfile.self], inMemory: true)
    }
}
