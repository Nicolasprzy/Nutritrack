import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.activeProfileID) private var activeProfileID
    @Query private var profiles: [UserProfile]
    @Query(filter: #Predicate<UserPlan> { $0.estActif == true })
    private var plansActifs: [UserPlan]

    @State private var viewModel = DashboardViewModel()
    @State private var planViewModel = UserPlanViewModel()
    @State private var showAddFood = false
    @State private var showAddMetric = false
    @State private var healthKitService = HealthKitService()
    @State private var claudeService = ClaudeAIService()
    @State private var chartProgress: Double = 0

    var profil: UserProfile? { profiles.first(where: { $0.profileID.uuidString == activeProfileID }) }
    var planActif: UserPlan? { plansActifs.first(where: { $0.profileID == activeProfileID }) }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                enteteSection
                    .padding(.horizontal, Spacing.lg)

                if let plan = planActif, let p = profil, Date() >= plan.prochainReevaluation {
                    reevaluationBanner(plan: plan, profil: p)
                        .padding(.horizontal, Spacing.lg)
                }

                #if os(macOS)
                layoutMacOS
                #else
                layoutIOS
                #endif
            }
            .padding(.vertical, Spacing.md)
        }
        .navigationTitle("Tableau de bord")
        .background(Color.fondPrincipal)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: Spacing.sm) {
                    Button(action: { showAddMetric = true }) {
                        Image(systemName: "scalemass.fill")
                            .font(.title2)
                            .foregroundStyle(.purple)
                    }
                    .accessibilityLabel("Ajouter une mesure corporelle")
                    .help("Ajouter une mesure")

                    Button(action: { showAddFood = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.nutriGreen)
                    }
                    .accessibilityLabel("Ajouter un aliment")
                    .keyboardShortcut("n", modifiers: .command)
                }
            }
        }
        .sheet(isPresented: $showAddFood) {
            AddFoodView(mealType: "dejeuner", dateSelectionnee: Date())
        }
        .sheet(isPresented: $showAddMetric, onDismiss: {
            viewModel.charger(context: modelContext, profil: profil)
        }) {
            AddMetricView()
        }
        .onAppear {
            viewModel.charger(context: modelContext, profil: profil)
            Task {
                await viewModel.chargerDonneesHealthKit(service: healthKitService)
                if let p = profil {
                    await viewModel.chargerConseilIA(service: claudeService, profil: p, context: modelContext)
                }
            }
        }
        .onChange(of: activeProfileID) {
            viewModel.charger(context: modelContext, profil: profil)
        }
    }

    // MARK: - En-tête

    private var enteteSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatLong)
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
                Text("Bonjour, \(profil?.prenomAffiche ?? "toi") 👋")
                    .font(.nutriTitle)
            }
            Spacer()
            Image(systemName: "leaf.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.nutriGreen)
        }
    }

    // MARK: - Layout macOS (2 colonnes)

    private var layoutMacOS: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // Colonne gauche
            VStack(spacing: Spacing.lg) {
                anneauSection
                statsGrid
            }
            .frame(maxWidth: 360)

            // Colonne droite
            VStack(spacing: Spacing.lg) {
                if let p = profil, p.aUnObjectifSilhouette {
                    bilanCaloriqueCard(profil: p)
                    jalonsCard(profil: p)
                }
                resumeMacros
                graphique7Jours
                conseilIA
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Layout iOS (colonne unique)

    private var layoutIOS: some View {
        VStack(spacing: Spacing.lg) {
            if let p = profil, p.aUnObjectifSilhouette {
                bilanCaloriqueCard(profil: p)
                jalonsCard(profil: p)
            }
            anneauSection
            statsGrid
            resumeMacros
            graphique7Jours
            conseilIA
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Bilan calorique (TDEE vs objectif transformation)

    private func bilanCaloriqueCard(profil: UserProfile) -> some View {
        let objectifs = NutritionCalculator.objectifsCaloriques(profil: profil)
        let bilan = viewModel.bilan
        let consomme = bilan?.caloriesConsommees ?? 0
        let progression = min(1.0, consomme / max(1, objectifs.objectifTransformation))
        let approche = objectifs.approche

        return GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {

                // Titre + badge approche
                HStack(spacing: 6) {
                    Image(systemName: objectifs.iconeAjustement)
                        .foregroundStyle(objectifs.couleurAjustement)
                    Text("Objectif de transformation")
                        .font(.nutriHeadline)
                        .foregroundStyle(objectifs.couleurAjustement)
                    Spacer()
                    // Badge approche
                    HStack(spacing: 4) {
                        Text(approche.emoji)
                        Text(approche.label)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(approche.couleur)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(approche.couleur.opacity(0.12), in: Capsule())
                    if objectifs.semainesRestantes > 0 {
                        Text("\(objectifs.semainesRestantes) sem.")
                            .font(.nutriCaption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.secondary.opacity(0.12), in: Capsule())
                    }
                }

                // Ligne principale : cibles
                HStack(spacing: Spacing.lg) {
                    // Calories entretien
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Entretien")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                        Text("\(Int(objectifs.tdee.rounded())) kcal")
                            .font(.nutriHeadline).foregroundStyle(.secondary)
                    }

                    // Flèche + ajustement
                    VStack(spacing: 0) {
                        Image(systemName: objectifs.estDeficit ? "arrow.down" : objectifs.estSurplus ? "arrow.up" : "equal")
                            .font(.caption2)
                            .foregroundStyle(objectifs.couleurAjustement)
                        Text(objectifs.ajustement == 0 ? "=" : "\(objectifs.ajustement > 0 ? "+" : "")\(Int(objectifs.ajustement.rounded())) kcal")
                            .font(.system(size: 9))
                            .foregroundStyle(objectifs.couleurAjustement)
                    }

                    // Objectif transformation
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Objectif")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                        Text("\(Int(objectifs.objectifTransformation.rounded())) kcal")
                            .font(.nutriHeadline)
                            .foregroundStyle(objectifs.couleurAjustement)
                    }

                    Spacer()

                    // Kg estimés + rythme
                    if objectifs.kgEstimes > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("~\(String(format: "%.1f", objectifs.kgEstimes)) kg")
                                .font(.nutriHeadline)
                                .foregroundStyle(.primary)
                            Text(objectifs.typeTransformation)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            if objectifs.perteSemaineEstimee > 0 {
                                Text("~\(String(format: "%.2f", objectifs.perteSemaineEstimee)) kg/sem.")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(approche.couleur)
                            }
                        }
                    }
                }

                // Barre de progression du jour
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Aujourd'hui : \(Int(consomme.rounded())) kcal")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int((progression * 100).rounded()))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(objectifs.couleurAjustement)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.secondary.opacity(0.15))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(objectifs.couleurAjustement)
                                .frame(width: geo.size.width * progression, height: 6)
                                .animation(.easeInOut(duration: 0.5), value: progression)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
    }

    // MARK: - Card Jalons de transformation

    private func jalonsCard(profil: UserProfile) -> some View {
        let objectifs = NutritionCalculator.objectifsCaloriques(profil: profil)
        guard !objectifs.jalons.isEmpty else { return AnyView(EmptyView()) }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "fr_FR")
        fmt.dateFormat = "d MMM"

        return AnyView(GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Jalons de progression", systemImage: "flag.checkered")
                    .font(.nutriHeadline).foregroundStyle(.indigo)
                Divider()

                ForEach(Array(objectifs.jalons.enumerated()), id: \.element.id) { idx, jalon in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        // Indicateur visuel
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(jalon.couleur.opacity(0.15))
                                    .frame(width: 28, height: 28)
                                Image(systemName: jalon.icone)
                                    .font(.system(size: 11))
                                    .foregroundStyle(jalon.couleur)
                            }
                            if idx < objectifs.jalons.count - 1 {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 2, height: 18)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(jalon.titre)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(jalon.couleur)
                                Spacer()
                                Text(fmt.string(from: jalon.dateEstimee))
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            Text(jalon.detail)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.bottom, idx < objectifs.jalons.count - 1 ? Spacing.xs : 0)
                    }
                }
            }
        })
    }

    // MARK: - Anneau calories

    private var anneauSection: some View {
        GlassCard {
            VStack(spacing: Spacing.md) {
                if let bilan = viewModel.bilan {
                    MacroRingView(
                        caloriesConsommees: bilan.caloriesConsommees,
                        caloriesObjectif:   bilan.caloriesObjectif,
                        proteines:          bilan.proteinesConsommees,
                        objectifProteines:  bilan.proteinesObjectif,
                        glucides:           bilan.glucidesConsommes,
                        objectifGlucides:   bilan.glucidesObjectif,
                        lipides:            bilan.lipidesConsommes,
                        objectifLipides:    bilan.lipidesObjectif
                    )
                    .frame(height: 280)
                    .padding(.vertical, 8)

                    MacroRingLegende(
                        proteines: bilan.proteinesConsommees,
                        glucides:  bilan.glucidesConsommes,
                        lipides:   bilan.lipidesConsommes
                    )
                } else {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.nutriGreen.opacity(0.5))
                        Text("Aucun repas enregistré aujourd'hui")
                            .font(.nutriBody)
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 200)
                }
            }
        }
    }

    // MARK: - Stats 2x2

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(minimum: 140), spacing: 20), GridItem(.flexible(minimum: 140))], spacing: 20) {
            StatCard(
                titre: "Restantes",
                valeur: viewModel.bilan.map { $0.caloriesRestantes.arrondi(0) } ?? "—",
                unite: "kcal",
                icone: "flame.fill",
                couleur: .orange
            )
            StatCard(
                titre: "Brûlées",
                valeur: viewModel.totalCaloriesBrulees > 0 ?
                    viewModel.totalCaloriesBrulees.arrondi(0) : "—",
                unite: "kcal",
                icone: "bolt.fill",
                couleur: .red
            )
            StatCard(
                titre: "Poids",
                valeur: viewModel.dernierPoids > 0 ? viewModel.dernierPoids.arrondi(1) : "—",
                unite: "kg",
                icone: "scalemass.fill",
                couleur: .blue
            )
            masseGrasseCard
        }
    }

    private var masseGrasseCard: some View {
        let mg = viewModel.derniereMasseGrasse
        let couleur: Color = {
            guard mg > 0, let p = profil else { return .purple }
            let estHomme = p.sexe == "homme"
            if estHomme {
                return mg < 6 ? .blue : mg < 20 ? .nutriGreen : mg < 25 ? .orange : .red
            } else {
                return mg < 14 ? .blue : mg < 28 ? .nutriGreen : mg < 33 ? .orange : .red
            }
        }()
        return StatCard(
            titre: "Masse grasse",
            valeur: mg > 0 ? String(format: "%.1f", mg) : "—",
            unite: "%",
            icone: "drop.fill",
            couleur: couleur
        )
    }

    // MARK: - Résumé macros

    @ViewBuilder
    private var resumeMacros: some View {
        if let bilan = viewModel.bilan {
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Macronutriments", systemImage: "chart.bar.fill")
                        .font(.nutriHeadline)
                        .foregroundStyle(Color.nutriGreen)

                    MacrosProgressGroup(
                        proteines:         bilan.proteinesConsommees,
                        objectifProteines: bilan.proteinesObjectif,
                        glucides:          bilan.glucidesConsommes,
                        objectifGlucides:  bilan.glucidesObjectif,
                        lipides:           bilan.lipidesConsommes,
                        objectifLipides:   bilan.lipidesObjectif
                    )
                }
            }
        }
    }

    // MARK: - Graphique 7 jours

    private var graphique7Jours: some View {
        ChartCard(titre: "7 derniers jours", icone: "calendar", couleur: .blue) {
            if viewModel.calories7Jours.isEmpty {
                ContentUnavailableView(
                    "Aucune donnée",
                    systemImage: "chart.bar",
                    description: Text("Enregistrez vos repas pour voir votre évolution")
                )
                .frame(height: 140)
            } else {
                let objectif = profil.map { NutritionCalculator.objectifsCaloriques(profil: $0).objectifTransformation } ?? 2000
                Chart(viewModel.calories7Jours, id: \.date) { point in
                    BarMark(
                        x: .value("Jour", point.date, unit: .day),
                        y: .value("Calories", point.calories * chartProgress)
                    )
                    .foregroundStyle(
                        point.calories >= objectif * 0.9 && point.calories <= objectif * 1.1
                            ? Color.nutriGreen : Color.alerteOrange
                    )
                    .cornerRadius(6)

                    RuleMark(y: .value("Objectif", objectif))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                }
                .frame(height: 140)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                            .font(.system(size: 11))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { _ in
                        AxisValueLabel()
                            .font(.system(size: 11))
                    }
                }
                .onAppear {
                    chartProgress = 0
                    withAnimation(.easeOut(duration: 0.8).delay(0.15)) { chartProgress = 1.0 }
                }
                .onChange(of: viewModel.calories7Jours.map(\.calories)) {
                    chartProgress = 0
                    withAnimation(.easeOut(duration: 0.8).delay(0.1)) { chartProgress = 1.0 }
                }
            }
        }
    }

    // MARK: - Banner réévaluation

    private func reevaluationBanner(plan: UserPlan, profil: UserProfile) -> some View {
        GlassCard {
            HStack(spacing: Spacing.md) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Réévaluation du plan recommandée")
                        .font(.nutriHeadline)
                    Text("Votre programme a \(Calendar.current.dateComponents([.day], from: plan.prochainReevaluation, to: Date()).day ?? 0) jour(s) de retard.")
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    Task { await planViewModel.reevaluerPlan(profil: profil, context: modelContext) }
                } label: {
                    if planViewModel.isGenerating {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Réévaluer")
                            .font(.nutriHeadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xs)
                            .background(.orange, in: RoundedRectangle(cornerRadius: Radius.sm))
                    }
                }
                .buttonStyle(.plain)
                .disabled(planViewModel.isGenerating)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .strokeBorder(.orange.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Conseil IA

    @ViewBuilder
    private var conseilIA: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Label("Conseil du jour", systemImage: "brain.head.profile")
                        .font(.nutriHeadline)
                        .foregroundStyle(.cyan)
                    Spacer()
                    if let p = profil, p.aUneCleAPI {
                        Button(action: {
                            Task { await viewModel.rafraichirConseilIA(service: claudeService, profil: p, context: modelContext) }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .foregroundStyle(.cyan.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .help("Obtenir un nouveau conseil (1 appel API)")
                    }
                }

                if viewModel.isLoadingConseil {
                    HStack(spacing: Spacing.sm) {
                        ProgressView().controlSize(.small)
                        Text("NutriCoach réfléchit…")
                            .font(.nutriCaption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                } else if viewModel.conseilIA.isEmpty {
                    Text(profil?.aUneCleAPI == true
                         ? "Chargement du conseil…"
                         : "Ajoutez votre clé API Claude dans le profil pour recevoir des conseils personnalisés.")
                        .font(.nutriBody)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(viewModel.conseilIA)
                        .font(.nutriBody)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .modelContainer(for: [
                FoodItem.self, FoodEntry.self, BodyMetric.self,
                ActivityEntry.self, MealPlan.self, UserProfile.self
            ], inMemory: true)
    }
    .frame(width: 900, height: 700)
}
