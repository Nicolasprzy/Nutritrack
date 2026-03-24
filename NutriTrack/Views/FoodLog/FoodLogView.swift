import SwiftUI
import SwiftData

struct FoodLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.activeProfileID) private var activeProfileID
    @Query private var profiles: [UserProfile]
    @Query(filter: #Predicate<UserPlan> { $0.estActif == true },
           sort: \UserPlan.dateCreation, order: .reverse) private var tousPlans: [UserPlan]

    @State private var viewModel = FoodLogViewModel()
    @State private var showPlanNutritionComplet = false

    private var planActif: UserPlan? { tousPlans.first(where: { $0.profileID == activeProfileID }) }

    var profil: UserProfile? { profiles.first(where: { $0.profileID.uuidString == activeProfileID }) }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                dateNavigateur
                if let p = profil { planNutritionAdaptatif(profil: p) }
                totauxJour
                sections
            }
            .padding(Spacing.md)
        }
        .navigationTitle("Nutrition")
        .sheet(isPresented: $showPlanNutritionComplet) {
            if let plan = planActif { PlanNutritionCompletSheet(plan: plan, profil: profil) }
        }
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

    // MARK: - Plan nutritionnel adaptatif (4 états)

    @ViewBuilder
    private func planNutritionAdaptatif(profil: UserProfile) -> some View {
        switch profil.etatPlan(planActif: planActif) {
        case .planActif(let plan):
            planNutritionSection(plan: plan, profil: profil)
        case .aucunPlan:
            etatPlanCard(
                icone: "fork.knife.circle",
                couleur: .orange,
                titre: "Aucun plan nutritionnel",
                message: "Votre profil est configuré. Générez votre plan depuis l'onglet Entraînement."
            )
        case .cleAPIManquante:
            etatPlanCard(
                icone: "key.fill",
                couleur: .orange,
                titre: "Clé API Claude manquante",
                message: "Ajoutez votre clé Claude dans Profil → Coach IA pour générer votre plan nutritionnel personnalisé."
            )
        case .profilIncomplet:
            etatPlanCard(
                icone: "person.crop.circle.badge.exclamationmark",
                couleur: .secondary,
                titre: "Complétez votre profil",
                message: "Définissez votre silhouette objectif et une date cible pour obtenir un plan nutritionnel adapté."
            )
        }
    }

    private func etatPlanCard(icone: String, couleur: Color, titre: String, message: String) -> some View {
        GlassCard {
            HStack(spacing: Spacing.md) {
                Image(systemName: icone)
                    .font(.title2)
                    .foregroundStyle(couleur.opacity(0.7))
                VStack(alignment: .leading, spacing: 3) {
                    Text(titre)
                        .font(.nutriHeadline)
                    Text(message)
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Plan nutritionnel (affiché quand plan actif)

    private func planNutritionSection(plan: UserPlan, profil: UserProfile) -> some View {
        // Toujours calculer dynamiquement — les valeurs stockées dans le plan IA sont obsolètes
        // si l'approche de transformation a changé depuis la génération du plan.
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
                    // Badge approche
                    HStack(spacing: 4) {
                        Text(approche.emoji)
                        Text(approche.label)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(approche.couleur)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(approche.couleur.opacity(0.12), in: Capsule())

                    Button(action: { showPlanNutritionComplet = true }) {
                        Text("Voir tout").font(.nutriCaption).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Macros calculées dynamiquement
                HStack(spacing: Spacing.lg) {
                    macroTarget(label: "Calories",  valeur: obj.objectifTransformation.arrondi(0), unite: "kcal", couleur: .orange)
                    macroTarget(label: "Protéines", valeur: mac.proteines.arrondi(0),               unite: "g",    couleur: .proteineColor)
                    macroTarget(label: "Glucides",  valeur: mac.glucides.arrondi(0),                unite: "g",    couleur: .glucideColor)
                    macroTarget(label: "Lipides",   valeur: mac.lipides.arrondi(0),                 unite: "g",    couleur: .lipideColor)
                }

                // Ligne contexte TDEE / ajustement
                if profil.aUnObjectifSilhouette && obj.ajustement != 0 {
                    Divider()
                    HStack(spacing: 6) {
                        Image(systemName: obj.iconeAjustement)
                            .font(.caption2).foregroundStyle(obj.couleurAjustement)
                        Text("Entretien : \(Int(obj.tdee.rounded())) kcal")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                        Text("·").foregroundStyle(.tertiary)
                        Text("\(obj.typeTransformation.capitalized) : \(obj.ajustement > 0 ? "+" : "")\(Int(obj.ajustement.rounded())) kcal/j")
                            .font(.system(size: 10, weight: .medium)).foregroundStyle(obj.couleurAjustement)
                        if obj.semainesRestantes > 0 {
                            Spacer()
                            Text("\(obj.semainesRestantes) sem. restantes")
                                .font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                    }
                }

                // Premier conseil IA (qualitatif — reste du plan)
                if let conseil = plan.planNutrition?.recommandations.first {
                    Divider()
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill").font(.caption).foregroundStyle(.orange)
                        Text(conseil).font(.nutriCaption).foregroundStyle(.secondary).lineLimit(2)
                    }
                }

                let joursRestants = max(0, Calendar.current.dateComponents([.day], from: Date(), to: plan.prochainReevaluation).day ?? 0)
                if joursRestants > 0 {
                    Text("Réévaluation dans \(joursRestants) jour(s)")
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func macroTarget(label: String, valeur: String, unite: String, couleur: Color) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(valeur).font(.nutriHeadline).foregroundStyle(couleur)
                Text(unite).font(.system(size: 9)).foregroundStyle(.secondary)
            }
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
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
