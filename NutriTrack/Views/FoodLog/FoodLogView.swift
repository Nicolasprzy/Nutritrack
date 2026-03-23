import SwiftUI
import SwiftData

struct FoodLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var viewModel = FoodLogViewModel()

    var profil: UserProfile? { profiles.first }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                dateNavigateur
                totauxJour
                sections
            }
            .padding(Spacing.md)
        }
        .navigationTitle("Journal alimentaire")
        .background(Color.fondPrincipal)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.showAddFood = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.nutriGreen)
                }
                .accessibilityLabel("Ajouter un aliment")
            }
        }
        .sheet(isPresented: $viewModel.showAddFood) {
            AddFoodView(
                mealType: viewModel.mealTypeEnCours,
                dateSelectionnee: viewModel.dateSelectionnee,
                onAjoute: { viewModel.charger(context: modelContext) }
            )
        }
        .onAppear {
            viewModel.charger(context: modelContext)
        }
    }

    // MARK: - Navigateur de date

    private var dateNavigateur: some View {
        HStack(spacing: Spacing.md) {
            Button(action: { viewModel.jourPrecedent(context: modelContext) }) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Jour précédent")

            Spacer()

            Button(action: {
                viewModel.dateSelectionnee = Date()
                viewModel.charger(context: modelContext)
            }) {
                VStack(spacing: 2) {
                    Text(viewModel.dateSelectionnee.formatLong)
                        .font(.nutriHeadline)
                    if viewModel.estAujourdhui {
                        Text("Aujourd'hui")
                            .font(.nutriCaption)
                            .foregroundStyle(Color.nutriGreen)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: { viewModel.jourSuivant(context: modelContext) }) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(viewModel.estAujourdhui ? .tertiary : .primary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.estAujourdhui)
            .accessibilityLabel("Jour suivant")
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Totaux du jour

    @ViewBuilder
    private var totauxJour: some View {
        let total = viewModel.totalJour()
        if total.calories > 0 || !viewModel.entriesParRepas.values.flatMap({ $0 }).isEmpty {
            GlassCard {
                VStack(spacing: Spacing.sm) {
                    HStack {
                        Text("Total du jour")
                            .font(.nutriHeadline)
                        Spacer()
                        Text("\(total.calories.arrondi(0)) kcal")
                            .font(.nutriTitle2)
                            .foregroundStyle(.orange)
                            .monospacedDigit()
                    }

                    if let p = profil {
                        NutrientProgressBar(
                            nom: "Calories",
                            consomme: total.calories,
                            objectif: p.objectifCalorique,
                            couleur: .orange,
                            unite: "kcal"
                        )

                        Divider()

                        MacrosProgressGroup(
                            proteines:         total.proteines,
                            objectifProteines: p.objectifProteines,
                            glucides:          total.glucides,
                            objectifGlucides:  p.objectifGlucides,
                            lipides:           total.lipides,
                            objectifLipides:   p.objectifLipides
                        )
                    } else {
                        HStack(spacing: Spacing.lg) {
                            macroLabel("P", valeur: total.proteines)
                            macroLabel("G", valeur: total.glucides)
                            macroLabel("L", valeur: total.lipides)
                        }
                    }
                }
            }
        }
    }

    private func macroLabel(_ label: String, valeur: Double) -> some View {
        VStack(spacing: 2) {
            Text(valeur.arrondi(0))
                .font(.nutriTitle2)
                .monospacedDigit()
            Text("\(label) (g)")
                .font(.nutriCaption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sections repas

    private var sections: some View {
        ForEach(MealType.allCases, id: \.self) { mealType in
            let entries = viewModel.entriesParRepas[mealType.rawValue] ?? []
            MealSectionView(
                mealType: mealType,
                entries: entries,
                dateSelectionnee: viewModel.dateSelectionnee,
                onSuppression: { viewModel.charger(context: modelContext) },
                onAjoute: { viewModel.charger(context: modelContext) }
            )
        }
    }
}

#Preview {
    NavigationStack {
        FoodLogView()
            .modelContainer(for: [
                FoodItem.self, FoodEntry.self, UserProfile.self
            ], inMemory: true)
    }
}
