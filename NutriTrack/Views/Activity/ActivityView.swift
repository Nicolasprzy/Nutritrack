import SwiftUI
import SwiftData
import Charts

struct ActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.activeProfileID) private var activeProfileID
    @Query(sort: \ActivityEntry.date, order: .reverse) private var toutesActivites: [ActivityEntry]
    @Query private var profiles: [UserProfile]

    @State private var showAddActivity = false
    @State private var chartProgress: Double = 0

    private var profil: UserProfile? { profiles.first(where: { $0.profileID.uuidString == activeProfileID }) }

    // Filtrage des activités par profil actif
    private var activites: [ActivityEntry] {
        toutesActivites.filter { $0.profileID == activeProfileID }
    }

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
                LuminaSectionHeader(
                    eyebrow: "Acte V · Mouvement",
                    title: "Entraînement",
                    emphasis: "& activité."
                )
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)

                resumeAujourdhui
                if let p = profil { approcheEntrainementCard(profil: p) }
                graphique7Jours
                listeActivites
            }
            .padding(Spacing.md)
        }
        .navigationTitle("")
        .background(Color.fondPrincipal.opacity(0.70))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddActivity = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.red)
                }
                .accessibilityLabel("Ajouter une activité")
            }
        }
        .nutriSheet(title: "Ajouter une activité", size: .standard, isPresented: $showAddActivity) {
            AddActivityView()
        }
    }

    // MARK: - Approche entraînement

    private func approcheEntrainementCard(profil: UserProfile) -> some View {
        let approche = profil.approcheEnum
        let obj = NutritionCalculator.objectifsCaloriques(profil: profil)
        return GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.run.circle.fill")
                        .foregroundStyle(approche.couleur)
                    Text("Recommandations d'entraînement")
                        .font(.nutriHeadline).foregroundStyle(approche.couleur)
                }

                Divider()

                HStack(spacing: Spacing.md) {
                    // Séances recommandées
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.caption2).foregroundStyle(approche.couleur)
                            Text(approche.seancesConseillees)
                                .font(.nutriCaption)
                                .fontWeight(.semibold)
                                .foregroundStyle(approche.couleur)
                        }
                        Text("fréquence").font(.system(size: 9)).foregroundStyle(.secondary) // micro-label <11pt
                    }

                    Divider().frame(height: 30)

                    // Intensité
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "gauge.with.needle.fill")
                                .font(.caption2).foregroundStyle(approche.couleur)
                            Text(approche.intensiteEntrainement)
                                .font(.nutriCaption)
                                .fontWeight(.semibold)
                                .foregroundStyle(approche.couleur)
                        }
                        Text("intensité").font(.system(size: 9)).foregroundStyle(.secondary) // micro-label <11pt
                    }

                    Divider().frame(height: 30)

                    // Rythme de progression
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: obj.estDeficit
                                  ? "chart.line.downtrend.xyaxis"
                                  : "chart.line.uptrend.xyaxis")
                                .font(.caption2).foregroundStyle(approche.couleur)
                            Text(obj.perteSemaineEstimee > 0
                                 ? (obj.estDeficit
                                    ? "~\(String(format: "%.2f", obj.perteSemaineEstimee)) kg/sem."
                                    : "+\(String(format: "%.2f", obj.perteSemaineEstimee)) kg/sem.")
                                 : "Maintenance")
                                .font(.nutriCaption)
                                .fontWeight(.semibold)
                                .foregroundStyle(approche.couleur)
                        }
                        Text(obj.estDeficit ? "perte estimée" : "gain estimé")
                            .font(.system(size: 9)).foregroundStyle(.secondary) // micro-label <11pt
                    }

                    Spacer()
                }

                // Badge approche
                HStack(spacing: 6) {
                    Text(approche.emoji)
                    Text("Approche \(approche.label.lowercased())")
                        .font(.system(size: 10, weight: .medium)) // badge compact <11pt
                        .foregroundStyle(approche.couleur)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(approche.descriptionCourte)
                        .font(.system(size: 10)) // badge compact <11pt
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background { RoundedRectangle(cornerRadius: Radius.sm).fill(approche.couleur.opacity(0.08)) }
            }
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
                        y: .value("Calories", point.calories * chartProgress)
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
                .onAppear {
                    chartProgress = 0
                    withAnimation(.easeOut(duration: 0.8).delay(0.15)) { chartProgress = 1.0 }
                }
                .onChange(of: donnees7Jours.map(\.calories)) {
                    chartProgress = 0
                    withAnimation(.easeOut(duration: 0.8).delay(0.1)) { chartProgress = 1.0 }
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
