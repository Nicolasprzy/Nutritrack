import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.activeProfileID) private var activeProfileID
    @Query private var profiles: [UserProfile]
    @Query(sort: \WellnessScore.date, order: .reverse) private var wellnessScores: [WellnessScore]
    @Query(sort: \ProgressPhoto.date, order: .reverse) private var progressPhotos: [ProgressPhoto]

    @State private var viewModel = DashboardViewModel()
    @State private var showAddFood = false
    @State private var showAddMetric = false
    @State private var healthKitService = HealthKitService()
    @State private var chartProgress: Double = 0

    var profil: UserProfile? { profiles.first(where: { $0.profileID.uuidString == activeProfileID }) }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                enteteSection
                    .padding(.horizontal, Spacing.lg)

                planNutritionSection
                    .padding(.horizontal, Spacing.lg)

                #if os(macOS)
                layoutMacOS
                #else
                layoutIOS
                #endif
            }
            .padding(.vertical, Spacing.md)
        }
        .navigationTitle("")
        .background(Color.fondPrincipal.opacity(0.70))
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
        .nutriSheet(title: "Nouvelle mesure", size: .standard, isPresented: $showAddMetric) {
            AddMetricView()
        }
        .onChange(of: showAddMetric) { _, nouveau in
            if !nouveau { viewModel.charger(context: modelContext, profil: profil) }
        }
        .onAppear {
            viewModel.charger(context: modelContext, profil: profil)
            viewModel.chargerPlanNutrition(context: modelContext, profileID: activeProfileID)
            Task {
                await viewModel.chargerDonneesHealthKit(service: healthKitService)
            }
        }
        .onChange(of: activeProfileID) {
            viewModel.charger(context: modelContext, profil: profil)
            viewModel.chargerPlanNutrition(context: modelContext, profileID: activeProfileID)
        }
    }

    // MARK: - Plan nutrition (Sprint 2)

    private var planNutritionSection: some View {
        VStack(spacing: Spacing.sm) {
            DayTypeSelector(
                selected: currentDayType,
                onSelect: { selectDayType($0) }
            )
            TargetsCard(
                dayContext: viewModel.currentDayContext,
                target: viewModel.currentTarget,
                consumedKcal: viewModel.consumedKcal,
                consumedProteinG: viewModel.consumedProteinG,
                onSelectCTA: {}
            )
            QuickLogSection(
                templates: viewModel.suggestedTemplates,
                onLog: { tpl in logTemplate(tpl) }
            )
        }
    }

    private var currentDayType: DayType? {
        guard let raw = viewModel.currentDayContext?.dayType else { return nil }
        return DayType(rawValue: raw)
    }

    private func selectDayType(_ type: DayType) {
        viewModel.selectDayType(type, context: modelContext, profileID: activeProfileID)
        viewModel.chargerPlanNutrition(context: modelContext, profileID: activeProfileID)
    }

    private func logTemplate(_ template: MealTemplate) {
        viewModel.logTemplate(template, context: modelContext, profileID: activeProfileID)
    }

    // MARK: - En-tête Lumina

    private var enteteSection: some View {
        let prenom = profil?.prenomAffiche ?? "toi"
        let semaineRestantes = profil.map {
            NutritionCalculator.objectifsCaloriques(profil: $0).semainesRestantes
        } ?? 0
        let subtitle: String? = semaineRestantes > 0
            ? "Il vous reste \(semaineRestantes) semaines pour atteindre votre objectif. Restez constant·e."
            : nil

        return LuminaSectionHeader(
            eyebrow: "Acte I · Tableau de bord",
            title: "Bonsoir,",
            emphasis: "\(prenom).",
            subtitle: subtitle
        )
    }

    // MARK: - Layout macOS (2 colonnes)

    private var layoutMacOS: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // Colonne gauche
            VStack(spacing: Spacing.lg) {
                anneauSection
                statsGrid
                HStack(alignment: .top, spacing: Spacing.md) {
                    wellnessCard
                    photoCard
                }
            }
            .frame(maxWidth: NutriLayout.dashboardLeftColumn)

            // Colonne droite
            VStack(spacing: Spacing.lg) {
                if let p = profil, p.aUnObjectifSilhouette {
                    bilanCaloriqueCard(profil: p)
                    jalonsCard(profil: p)
                }
                resumeMacros
                graphique7Jours
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
            HStack(alignment: .top, spacing: Spacing.md) {
                wellnessCard
                photoCard
            }
            resumeMacros
            graphique7Jours
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Wellness & Photo cards (résumé dashboard)

    private var wellnessProfilScores: [WellnessScore] {
        wellnessScores.filter { $0.profileID == activeProfileID }
    }

    private var photosProfil: [ProgressPhoto] {
        progressPhotos.filter { $0.profileID == activeProfileID }
    }

    private var wellnessCard: some View {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recent = wellnessProfilScores.filter { $0.date >= cutoff }
        let moyenne: Double = recent.isEmpty
            ? 0
            : recent.map(\.scoreGlobal).reduce(0, +) / Double(recent.count)
        let couleur: Color = moyenne >= 7 ? .nutriGreen : moyenne >= 5 ? .orange : .red

        return GlassCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label("Wellness", systemImage: "heart.fill")
                    .font(.nutriHeadline)
                    .foregroundStyle(.pink)
                if recent.isEmpty {
                    Text("—")
                        .font(.nutriTitle2)
                        .foregroundStyle(.secondary)
                    Text("Aucun score")
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                        Text(String(format: "%.1f", moyenne))
                            .font(.nutriTitle2)
                            .foregroundStyle(couleur)
                        Text("/10")
                            .font(.nutriCaption)
                            .foregroundStyle(.secondary)
                    }
                    Text("Moy. 7 jours (\(recent.count))")
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var photoCard: some View {
        let derniere = photosProfil.first
        return GlassCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label("Photo", systemImage: "photo.stack.fill")
                    .font(.nutriHeadline)
                    .foregroundStyle(.purple)
                if let photo = derniere {
                    PhotoImage(data: photo.imageData)
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                    Text(photo.dateFormatted)
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                } else {
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .fill(.secondary.opacity(0.1))
                        .frame(height: 80)
                        .overlay(
                            Image(systemName: "camera")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        )
                    Text("Aucune photo")
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
                HStack(spacing: Spacing.sm) {
                    Image(systemName: objectifs.iconeAjustement)
                        .foregroundStyle(objectifs.couleurAjustement)
                    Text("Objectif de transformation")
                        .font(.nutriHeadline)
                        .foregroundStyle(objectifs.couleurAjustement)
                    Spacer()
                    // Badge approche
                    HStack(spacing: Spacing.xs) {
                        Text(approche.emoji)
                        Text(approche.label)
                            .font(.nutriCaption2)
                    }
                    .foregroundStyle(approche.couleur)
                    .padding(.horizontal, Spacing.sm).padding(.vertical, Spacing.xxs)
                    .background { Capsule().fill(approche.couleur.opacity(0.12)) }
                    if objectifs.semainesRestantes > 0 {
                        Text("\(objectifs.semainesRestantes) sem.")
                            .font(.nutriCaption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background { Capsule().fill(Color.secondary.opacity(0.12)) }
                    }
                }

                // Ligne principale : cibles
                HStack(spacing: Spacing.lg) {
                    // Calories entretien
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Entretien")
                            .font(.nutriCaption2).foregroundStyle(.secondary)
                        Text("\(Int(objectifs.tdee.rounded())) kcal")
                            .font(.nutriHeadline).foregroundStyle(.secondary)
                    }

                    // Flèche + ajustement
                    VStack(spacing: 0) {
                        Image(systemName: objectifs.estDeficit ? "arrow.down" : objectifs.estSurplus ? "arrow.up" : "equal")
                            .font(.caption2)
                            .foregroundStyle(objectifs.couleurAjustement)
                        Text(objectifs.ajustement == 0 ? "=" : "\(objectifs.ajustement > 0 ? "+" : "")\(Int(objectifs.ajustement.rounded())) kcal")
                            .font(.nutriCaption2)
                            .foregroundStyle(objectifs.couleurAjustement)
                    }

                    // Objectif transformation
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Objectif")
                            .font(.nutriCaption2).foregroundStyle(.secondary)
                        Text("\(Int(objectifs.objectifTransformation.rounded())) kcal")
                            .font(.nutriHeadline)
                            .foregroundStyle(objectifs.couleurAjustement)
                    }

                    Spacer()

                    // Kg estimés + rythme
                    if objectifs.kgEstimes > 0 {
                        VStack(alignment: .trailing, spacing: Spacing.xxs) {
                            Text("~\(String(format: "%.1f", objectifs.kgEstimes)) kg")
                                .font(.nutriHeadline)
                                .foregroundStyle(.primary)
                            Text(objectifs.typeTransformation)
                                .font(.nutriCaption2)
                                .foregroundStyle(.secondary)
                            if objectifs.perteSemaineEstimee > 0 {
                                Text("~\(String(format: "%.2f", objectifs.perteSemaineEstimee)) kg/sem.")
                                    .font(.nutriCaption2)
                                    .foregroundStyle(approche.couleur)
                            }
                        }
                    }
                }

                // Barre de progression du jour
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text("Aujourd'hui : \(Int(consomme.rounded())) kcal")
                            .font(.nutriCaption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int((progression * 100).rounded()))%")
                            .font(.nutriCaption)
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
                                    .font(.nutriCaption)
                                    .foregroundStyle(jalon.couleur)
                            }
                            if idx < objectifs.jalons.count - 1 {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 2, height: 18)
                            }
                        }

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            HStack {
                                Text(jalon.titre)
                                    .font(.nutriCaption)
                                    .foregroundStyle(jalon.couleur)
                                Spacer()
                                Text(fmt.string(from: jalon.dateEstimee))
                                    .font(.nutriCaption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            Text(jalon.detail)
                                .font(.nutriCaption2)
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
                    .padding(.vertical, Spacing.sm)

                    MacroRingLegende(
                        proteines: bilan.proteinesConsommees,
                        glucides:  bilan.glucidesConsommes,
                        lipides:   bilan.lipidesConsommes
                    )
                } else {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 48)) // icône hero
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
                            .font(.nutriCaption)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { _ in
                        AxisValueLabel()
                            .font(.nutriCaption)
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

}

#Preview {
    NavigationStack {
        DashboardView()
            .modelContainer(for: [
                FoodItem.self, FoodEntry.self, BodyMetric.self,
                ActivityEntry.self, UserProfile.self,
                MacroTarget.self, DayContext.self,
                MealTemplate.self, MealTemplateItem.self
            ], inMemory: true)
    }
    .frame(width: 900, height: 700)
}
