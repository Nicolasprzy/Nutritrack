import SwiftUI
import SwiftData
import Charts

struct BodyTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var viewModel = BodyTrackingViewModel()
    @State private var healthKitService = HealthKitService()

    var profil: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                carteResume
                graphiquePoids
                grille2x2
                historique
            }
            .padding(Spacing.md)
        }
        .navigationTitle("Suivi corporel")
        .background(Color.fondPrincipal)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.showAddMetric = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
                .accessibilityLabel("Ajouter une mesure")
            }
        }
        .sheet(isPresented: $viewModel.showAddMetric, onDismiss: {
            viewModel.charger(context: modelContext)
        }) {
            AddMetricView()
        }
        .onAppear {
            viewModel.charger(context: modelContext)
        }
    }

    // MARK: - Carte résumé

    private var carteResume: some View {
        GlassCard {
            HStack(spacing: Spacing.lg) {
                resumeItem(
                    valeur: viewModel.dernierPoids > 0 ? viewModel.dernierPoids.kg : "—",
                    label: "Poids",
                    icone: "scalemass.fill",
                    couleur: .blue
                )

                Divider().frame(height: 50)

                resumeItem(
                    valeur: viewModel.dernierIMC > 0 ? viewModel.dernierIMC.arrondi(1) : "—",
                    label: "IMC",
                    icone: "figure.stand",
                    couleur: imcCouleur
                )

                Divider().frame(height: 50)

                VStack(spacing: 4) {
                    Text(viewModel.evolutionPoidsFormatee)
                        .font(.nutriTitle2)
                        .foregroundStyle(evolutionCouleur)
                    Text("vs début")
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                    Image(systemName: viewModel.evolutionPoids > 0 ? "arrow.up" : (viewModel.evolutionPoids < 0 ? "arrow.down" : "minus"))
                        .foregroundStyle(evolutionCouleur)
                }
            }
        }
    }

    private func resumeItem(valeur: String, label: String, icone: String, couleur: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icone)
                .foregroundStyle(couleur)
            Text(valeur)
                .font(.nutriTitle2)
                .foregroundStyle(.primary)
            Text(label)
                .font(.nutriCaption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var imcCouleur: Color {
        switch viewModel.dernierIMC {
        case ..<18.5: return .blue
        case 18.5..<25: return .nutriGreen
        case 25..<30: return .orange
        default: return .red
        }
    }

    private var evolutionCouleur: Color {
        if viewModel.evolutionPoids > 0.5 { return .orange }
        if viewModel.evolutionPoids < -0.5 { return .nutriGreen }
        return .primary
    }

    // MARK: - Graphique poids principal

    private var graphiquePoids: some View {
        ChartCard(titre: "Évolution du poids", icone: "chart.line.uptrend.xyaxis", couleur: .blue) {
            VStack(spacing: Spacing.sm) {
                // Sélecteur de période
                Picker("Période", selection: $viewModel.periode) {
                    ForEach(BodyTrackingViewModel.Periode.allCases, id: \.self) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.periode) { _, _ in
                    viewModel.charger(context: modelContext)
                }

                WeightChartView(donnees: viewModel.donneesPoids)
            }
        }
    }

    // MARK: - Grille 2x2 mini-charts

    private var grille2x2: some View {
        LazyVGrid(columns: [GridItem(.flexible(minimum: 160), spacing: 20), GridItem(.flexible(minimum: 160))], spacing: 20) {
            MiniChartView(
                titre: "Tour de taille",
                donnees: viewModel.donneesTourDeTaille,
                couleur: .orange,
                unite: "cm"
            )
            MiniChartView(
                titre: "Tour de hanches",
                donnees: viewModel.donneesTourDeHanches,
                couleur: .purple,
                unite: "cm"
            )
            MiniChartView(
                titre: "Masse grasse",
                donnees: viewModel.donneesMasseGrasse,
                couleur: .red,
                unite: "%"
            )
            MiniChartView(
                titre: "IMC",
                donnees: viewModel.donneesIMC,
                couleur: imcCouleur,
                unite: ""
            )
        }
    }

    // MARK: - Historique tableau

    @ViewBuilder
    private var historique: some View {
        if !viewModel.metrics.isEmpty {
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Historique", systemImage: "list.bullet")
                        .font(.nutriHeadline)

                    ForEach(viewModel.metrics.reversed().prefix(10)) { metric in
                        HStack {
                            Text(metric.date.formatCourt)
                                .font(.nutriCaption)
                                .foregroundStyle(.secondary)
                                .frame(width: 45, alignment: .leading)

                            if metric.weight > 0 {
                                Text(metric.weight.kg)
                                    .font(.nutriBody)
                            }

                            if metric.bmi > 0 {
                                Text("IMC \(metric.bmi.arrondi(1))")
                                    .font(.nutriCaption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if metric.weight > 0, let precedent = viewModel.metrics.reversed().first(where: { $0.date < metric.date && $0.weight > 0 }) {
                                let diff = metric.weight - precedent.weight
                                Text(diff > 0 ? "+\(diff.arrondi(1))" : diff.arrondi(1))
                                    .font(.nutriCaption)
                                    .foregroundStyle(diff > 0 ? .orange : .nutriGreen)
                            }
                        }
                        .padding(.vertical, 2)

                        if metric.id != viewModel.metrics.reversed().prefix(10).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BodyTrackingView()
            .modelContainer(for: [BodyMetric.self, UserProfile.self], inMemory: true)
    }
}
