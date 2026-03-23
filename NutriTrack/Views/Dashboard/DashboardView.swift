import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var viewModel = DashboardViewModel()
    @State private var showAddFood = false
    @State private var healthKitService = HealthKitService()
    @State private var claudeService = ClaudeAIService()

    var profil: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                enteteSection
                    .padding(.horizontal, Spacing.lg)

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
                Button(action: { showAddFood = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.nutriGreen)
                }
                .accessibilityLabel("Ajouter un aliment")
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showAddFood) {
            AddFoodView(mealType: "dejeuner", dateSelectionnee: Date())
        }
        .onAppear {
            viewModel.charger(context: modelContext)
            Task {
                await viewModel.chargerDonneesHealthKit(service: healthKitService)
                if let p = profil {
                    await viewModel.chargerConseilIA(service: claudeService, profil: p, context: modelContext)
                }
            }
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
            anneauSection
            statsGrid
            resumeMacros
            graphique7Jours
            conseilIA
        }
        .padding(.horizontal, Spacing.md)
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
                valeur: viewModel.caloriesBruleesAujourdhui > 0 ?
                    viewModel.caloriesBruleesAujourdhui.arrondi(0) : "—",
                unite: "kcal",
                icone: "bolt.fill",
                couleur: .red
            )
            StatCard(
                titre: "Pas",
                valeur: viewModel.pasAujourdhui > 0 ?
                    String(format: "%.0f", viewModel.pasAujourdhui) : "—",
                unite: "pas",
                icone: "figure.walk",
                couleur: .nutriGreen
            )
            StatCard(
                titre: "Eau",
                valeur: "—",
                unite: "L",
                icone: "drop.fill",
                couleur: .blue
            )
        }
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
                let objectif = profil?.objectifCalorique ?? 2000
                Chart(viewModel.calories7Jours, id: \.date) { point in
                    BarMark(
                        x: .value("Jour", point.date, unit: .day),
                        y: .value("Calories", point.calories)
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
            }
        }
    }

    // MARK: - Conseil IA

    @ViewBuilder
    private var conseilIA: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Conseil du jour", systemImage: "brain.head.profile")
                    .font(.nutriHeadline)
                    .foregroundStyle(.cyan)

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
