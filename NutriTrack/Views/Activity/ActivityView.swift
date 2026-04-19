import SwiftUI
import SwiftData
import Charts

struct ActivityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.activeProfileID) private var activeProfileID
    @Query(sort: \ActivityEntry.date, order: .reverse) private var toutesActivites: [ActivityEntry]
    @Query private var profiles: [UserProfile]
    @Query(filter: #Predicate<UserPlan> { $0.estActif == true },
           sort: \UserPlan.dateCreation, order: .reverse) private var tousPlans: [UserPlan]

    @State private var showAddActivity = false
    @State private var viewModel = UserPlanViewModel()
    @State private var showProgrammeComplet = false
    @State private var chartProgress: Double = 0

    private var profil: UserProfile? { profiles.first(where: { $0.profileID.uuidString == activeProfileID }) }
    private var planActif: UserPlan? { tousPlans.first(where: { $0.profileID == activeProfileID }) }

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
                // ── Programme du jour — état adaptatif ──
                if let p = profil {
                    switch p.etatPlan(planActif: planActif) {
                    case .planActif(let plan):
                        programmeDuJour(plan: plan)
                    case .aucunPlan:
                        genererPlanBanner(profil: p)
                    case .cleAPIManquante:
                        etatPlanCard(
                            icone: "key.fill", couleur: .orange,
                            titre: "Clé API Claude manquante",
                            message: "Ajoutez votre clé Claude dans Profil → Coach IA pour générer votre programme personnalisé.",
                            actionLabel: nil, action: nil
                        )
                    case .profilIncomplet:
                        etatPlanCard(
                            icone: "person.crop.circle.badge.exclamationmark", couleur: .secondary,
                            titre: "Profil incomplet",
                            message: "Définissez votre silhouette objectif et une date cible dans votre profil pour générer un programme.",
                            actionLabel: nil, action: nil
                        )
                    }
                }

                resumeAujourdhui
                if let p = profil { approcheEntrainementCard(profil: p) }
                graphique7Jours
                listeActivites
            }
            .padding(Spacing.md)
        }
        .navigationTitle("Entraînement")
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
        .sheet(isPresented: $showProgrammeComplet) {
            if let plan = planActif { ProgrammeCompletSheet(plan: plan) }
        }
    }

    // MARK: - Programme du jour

    private func programmeDuJour(plan: UserPlan) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Label("Mon programme", systemImage: "dumbbell.fill")
                        .font(.nutriHeadline).foregroundStyle(.red)
                    Spacer()
                    Button(action: { showProgrammeComplet = true }) {
                        Text("Voir tout")
                            .font(.nutriCaption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                if let seance = seanceDuJour(from: plan) {
                    if seance.estJourRepos {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "moon.fill").foregroundStyle(.indigo)
                            Text("Repos aujourd'hui — récupération active conseillée")
                                .font(.nutriCaption).foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(seance.jourLabel)
                                    .font(.nutriCaption).foregroundStyle(.secondary)
                                HStack(spacing: 6) {
                                    Image(systemName: seance.iconeSeance).foregroundStyle(.red)
                                    Text(seance.typeSeance).font(.nutriHeadline)
                                    Text("· \(seance.dureeMinutes) min")
                                        .font(.nutriCaption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if seance.seanceFaite {
                                Label("Faite", systemImage: "checkmark.circle.fill")
                                    .font(.nutriCaption).foregroundStyle(Color.nutriGreen)
                            } else {
                                Button(action: {
                                    viewModel.marquerSeanceFaite(plan: plan, jourId: seance.id, profileID: activeProfileID, context: modelContext)
                                }) {
                                    Text("Marquer faite")
                                        .font(.nutriCaption)
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(Color.red.opacity(0.15), in: Capsule())
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if !seance.exercices.isEmpty {
                            Divider()
                            ForEach(seance.exercices.prefix(3)) { ex in
                                HStack {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(ex.nom).font(.nutriCaption)
                                        Text(ex.musclesCibles.prefix(2).joined(separator: ", "))
                                            .font(.system(size: 10)).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(ex.series)× \(ex.repetitions)")
                                        .font(.nutriCaption).foregroundStyle(.secondary)
                                }
                            }
                            if seance.exercices.count > 3 {
                                Text("+ \(seance.exercices.count - 3) exercice(s)…")
                                    .font(.system(size: 10)).foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    Text("Aucune séance programmée aujourd'hui.")
                        .font(.nutriCaption).foregroundStyle(.secondary)
                }

                // Réévaluation
                if let p = profil, !p.claudeAPIKey.isEmpty {
                    let jours = joursAvantReevaluation(plan: plan)
                    if jours == 0 {
                        Button(action: {
                            if let p = profil {
                                Task { await viewModel.reevaluerPlan(profil: p, context: modelContext) }
                            }
                        }) {
                            Label("Réévaluer mon plan", systemImage: "arrow.clockwise")
                                .font(.nutriCaption)
                                .foregroundStyle(.orange)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("Réévaluation dans \(jours) jour(s)")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func genererPlanBanner(profil: UserProfile) -> some View {
        GlassCard {
            VStack(spacing: Spacing.sm) {
                Image(systemName: "dumbbell.fill")
                    .font(.title2).foregroundStyle(.red.opacity(0.7))
                Text("Aucun programme actif")
                    .font(.nutriHeadline)
                Text("Votre profil est prêt. Générez votre programme d'entraînement personnalisé par IA.")
                    .font(.nutriCaption).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: {
                    Task { await viewModel.genererPlan(profil: profil, context: modelContext) }
                }) {
                    if viewModel.isGenerating {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text("Génération en cours…").font(.nutriCaption)
                        }
                    } else {
                        Label("Générer mon programme IA", systemImage: "wand.and.stars")
                            .font(.nutriCaption)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(Color.red.opacity(0.15), in: Capsule())
                            .foregroundStyle(.red)
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isGenerating)

                if let err = viewModel.errorMessage {
                    Text(err).font(.nutriCaption).foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
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
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(approche.couleur)
                        }
                        Text("fréquence").font(.system(size: 9)).foregroundStyle(.secondary)
                    }

                    Divider().frame(height: 30)

                    // Intensité
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "gauge.with.needle.fill")
                                .font(.caption2).foregroundStyle(approche.couleur)
                            Text(approche.intensiteEntrainement)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(approche.couleur)
                        }
                        Text("intensité").font(.system(size: 9)).foregroundStyle(.secondary)
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
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(approche.couleur)
                        }
                        Text(obj.estDeficit ? "perte estimée" : "gain estimé")
                            .font(.system(size: 9)).foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                // Badge approche
                HStack(spacing: 6) {
                    Text(approche.emoji)
                    Text("Approche \(approche.label.lowercased())")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(approche.couleur)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(approche.descriptionCourte)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(approche.couleur.opacity(0.08), in: RoundedRectangle(cornerRadius: Radius.sm))
            }
        }
    }

    private func etatPlanCard(icone: String, couleur: Color, titre: String, message: String,
                               actionLabel: String?, action: (() -> Void)?) -> some View {
        GlassCard {
            VStack(spacing: Spacing.sm) {
                Image(systemName: icone)
                    .font(.title2).foregroundStyle(couleur.opacity(0.7))
                Text(titre)
                    .font(.nutriHeadline)
                Text(message)
                    .font(.nutriCaption).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if let label = actionLabel, let action {
                    Button(action: action) {
                        Text(label)
                            .font(.nutriCaption)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(couleur.opacity(0.12), in: Capsule())
                            .foregroundStyle(couleur)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
        }
    }

    private func seanceDuJour(from plan: UserPlan) -> JourEntrainement? {
        guard let e = plan.planEntrainement else { return nil }
        let wd = Calendar.current.component(.weekday, from: Date())
        let idx = (wd + 5) % 7
        let jours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
        let label = idx < jours.count ? jours[idx] : ""
        return e.semaineType.first { $0.jourLabel.lowercased().contains(label.lowercased()) }
            ?? (e.semaineType.indices.contains(idx) ? e.semaineType[idx] : nil)
    }

    private func joursAvantReevaluation(plan: UserPlan) -> Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: plan.prochainReevaluation).day ?? 0)
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
            .modelContainer(for: [ActivityEntry.self, UserProfile.self, UserPlan.self], inMemory: true)
    }
}
