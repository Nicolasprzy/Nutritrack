import SwiftUI
import SwiftData

struct FoodLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.activeProfileID) private var activeProfileID
    @Query private var profiles: [UserProfile]

    @State private var viewModel = FoodLogViewModel()

    var profil: UserProfile? { profiles.first(where: { $0.profileID.uuidString == activeProfileID }) }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                LuminaSectionHeader(
                    eyebrow: "Acte II · Journal",
                    title: "Nutrition",
                    emphasis: "du jour."
                )
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)

                dateNavigateur
                if let p = profil, p.aUnObjectifSilhouette { planNutritionSection(profil: p) }
                totauxJour
                sections
            }
            .padding(Spacing.md)
        }
        .navigationTitle("")
        .background(Color.fondPrincipal.opacity(0.70))
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
                onAjoute: { viewModel.charger(context: modelContext, profileID: activeProfileID) }
            )
        }
        .onAppear {
            viewModel.charger(context: modelContext, profileID: activeProfileID)
        }
        .onChange(of: activeProfileID) {
            viewModel.charger(context: modelContext, profileID: activeProfileID)
        }
    }

    // MARK: - Plan nutritionnel (affiché si objectif silhouette défini)

    private func planNutritionSection(profil: UserProfile) -> some View {
        let obj  = NutritionCalculator.objectifsCaloriques(profil: profil)
        let mac  = NutritionCalculator.macrosCiblesTransformation(
            calories:   obj.objectifTransformation,
            poidsKg:    profil.poidsActuel,
            ajustement: obj.ajustement,
            approche:   profil.approcheEnum
        )
        let approche = profil.approcheEnum

        return GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Label("Mon plan nutritionnel", systemImage: "fork.knife.circle.fill")
                        .font(.nutriHeadline).foregroundStyle(.orange)
                    Spacer()
                    HStack(spacing: Spacing.xs) {
                        Text(approche.emoji)
                        Text(approche.label)
                            .font(.nutriCaption2)
                    }
                    .foregroundStyle(approche.couleur)
                    .padding(.horizontal, Spacing.sm).padding(.vertical, Spacing.xxs)
                    .background { Capsule().fill(approche.couleur.opacity(0.12)) }
                }

                // Macros calculées dynamiquement
                HStack(spacing: Spacing.lg) {
                    macroTarget(label: "Calories",  valeur: obj.objectifTransformation.arrondi(0), unite: "kcal", couleur: .orange)
                    macroTarget(label: "Protéines", valeur: mac.proteines.arrondi(0),               unite: "g",    couleur: .proteineColor)
                    macroTarget(label: "Glucides",  valeur: mac.glucides.arrondi(0),                unite: "g",    couleur: .glucideColor)
                    macroTarget(label: "Lipides",   valeur: mac.lipides.arrondi(0),                 unite: "g",    couleur: .lipideColor)
                }

                // Ligne contexte TDEE / ajustement
                if obj.ajustement != 0 {
                    Divider()
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: obj.iconeAjustement)
                            .font(.caption2).foregroundStyle(obj.couleurAjustement)
                        Text("Entretien : \(Int(obj.tdee.rounded())) kcal")
                            .font(.nutriCaption2).foregroundStyle(.secondary)
                        Text("·").foregroundStyle(.tertiary)
                        Text("\(obj.typeTransformation.capitalized) : \(obj.ajustement > 0 ? "+" : "")\(Int(obj.ajustement.rounded())) kcal/j")
                            .font(.nutriCaption2).foregroundStyle(obj.couleurAjustement)
                        if obj.semainesRestantes > 0 {
                            Spacer()
                            Text("\(obj.semainesRestantes) sem. restantes")
                                .font(.nutriCaption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func macroTarget(label: String, valeur: String, unite: String, couleur: Color) -> some View {
        VStack(spacing: Spacing.xxs) {
            HStack(alignment: .lastTextBaseline, spacing: Spacing.xxs) {
                Text(valeur).font(Font.nutriHeadline).foregroundStyle(couleur)
                Text(unite).font(Font.nutriCaption2).foregroundStyle(Color.luminaInkMuted)
            }
            Text(label).font(Font.nutriCaption2).foregroundStyle(Color.luminaInkMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Navigateur de date

    private var dateNavigateur: some View {
        HStack(spacing: Spacing.md) {
            Button(action: { viewModel.jourPrecedent(context: modelContext, profileID: activeProfileID) }) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Jour précédent")

            Spacer()

            Button(action: {
                viewModel.dateSelectionnee = Date()
                viewModel.charger(context: modelContext, profileID: activeProfileID)
            }) {
                VStack(spacing: Spacing.xxs) {
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

            Button(action: { viewModel.jourSuivant(context: modelContext, profileID: activeProfileID) }) {
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
                        let objTransfo = NutritionCalculator.objectifsCaloriques(profil: p)
                        let macTransfo = NutritionCalculator.macrosCiblesTransformation(
                            calories:   objTransfo.objectifTransformation,
                            poidsKg:    p.poidsActuel,
                            ajustement: objTransfo.ajustement,
                            approche:   p.approcheEnum
                        )
                        NutrientProgressBar(
                            nom: "Calories",
                            consomme: total.calories,
                            objectif: objTransfo.objectifTransformation,
                            couleur: .orange,
                            unite: "kcal"
                        )

                        Divider()

                        MacrosProgressGroup(
                            proteines:         total.proteines,
                            objectifProteines: macTransfo.proteines,
                            glucides:          total.glucides,
                            objectifGlucides:  macTransfo.glucides,
                            lipides:           total.lipides,
                            objectifLipides:   macTransfo.lipides
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
        VStack(spacing: Spacing.xxs) {
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
                onSuppression: { viewModel.charger(context: modelContext, profileID: activeProfileID) },
                onAjoute: { viewModel.charger(context: modelContext, profileID: activeProfileID) }
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
