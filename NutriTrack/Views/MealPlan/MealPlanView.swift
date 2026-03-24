import SwiftUI
import SwiftData

struct MealPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.activeProfileID) private var activeProfileID
    @Query private var profiles: [UserProfile]

    @State private var viewModel = MealPlanViewModel()
    @State private var showAjouterPlan = false
    @State private var jourEnCours: Int = 0
    @State private var mealTypeEnCours: String = "dejeuner"
    @State private var titrePlan: String = ""
    @State private var affichageMode: AffichageMode = .liste

    var profil: UserProfile? { profiles.first(where: { $0.profileID.uuidString == activeProfileID }) }

    enum AffichageMode: String, CaseIterable {
        case liste   = "Liste"
        case semaine = "Semaine"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Navigateur de semaine
            navigateurSemaine

            Divider()

            Picker("Affichage", selection: $affichageMode) {
                ForEach(AffichageMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)

            ScrollView {
                VStack(spacing: Spacing.md) {
                    switch affichageMode {
                    case .liste:
                        vueListe
                    case .semaine:
                        vueSemaine
                    }
                }
                .padding(Spacing.md)
            }
        }
        .navigationTitle("Plan de repas")
        .background(Color.fondPrincipal)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if profil?.aUneCleAPI == true {
                    Button(action: { genererAvecIA() }) {
                        if viewModel.isGenerating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label("IA", systemImage: "brain.head.profile")
                                .foregroundStyle(.cyan)
                        }
                    }
                    .disabled(viewModel.isGenerating)
                    .accessibilityLabel("Générer avec l'IA")
                }
            }
        }
        .sheet(isPresented: $showAjouterPlan) {
            ajouterPlanSheet
        }
        .sheet(isPresented: $viewModel.showPlanIA) {
            planIASheet
        }
        .onAppear {
            viewModel.charger(context: modelContext)
        }
    }

    // MARK: - Navigateur semaine

    private var navigateurSemaine: some View {
        HStack(spacing: Spacing.md) {
            Button(action: { viewModel.semainePrecedente(context: modelContext) }) {
                Image(systemName: "chevron.left").foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(viewModel.labelSemaine)
                .font(.nutriHeadline)

            Spacer()

            Button(action: { viewModel.semaineSuivante(context: modelContext) }) {
                Image(systemName: "chevron.right").foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Vue liste

    private var vueListe: some View {
        ForEach(0..<7, id: \.self) { jour in
            MealPlanDayView(
                jour: jour,
                plans: viewModel.plans(pourJour: jour),
                semaineCourante: viewModel.semaineCourante,
                onAjouter: { jour, mealType in
                    jourEnCours = jour
                    mealTypeEnCours = mealType
                    showAjouterPlan = true
                },
                onSupprimer: { plan in
                    viewModel.supprimer(plan, context: modelContext)
                }
            )
        }
    }

    // MARK: - Vue semaine (grille)

    private var vueSemaine: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                ForEach(0..<7, id: \.self) { jour in
                    MealPlanDayView(
                        jour: jour,
                        plans: viewModel.plans(pourJour: jour),
                        semaineCourante: viewModel.semaineCourante,
                        onAjouter: { jour, mealType in
                            jourEnCours = jour
                            mealTypeEnCours = mealType
                            showAjouterPlan = true
                        },
                        onSupprimer: { plan in
                            viewModel.supprimer(plan, context: modelContext)
                        }
                    )
                    .frame(width: 160)
                }
            }
        }
    }

    // MARK: - Sheet ajout plan

    private var ajouterPlanSheet: some View {
        NavigationStack {
            Form {
                Section("Repas") {
                    Picker("Type de repas", selection: $mealTypeEnCours) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.label).tag(type.rawValue)
                        }
                    }
                }
                Section("Titre") {
                    TextField("Nom du repas prévu", text: $titrePlan)
                }
            }
            .navigationTitle("Planifier un repas")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { showAjouterPlan = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        viewModel.ajouterPlan(
                            jour: jourEnCours,
                            mealType: mealTypeEnCours,
                            titre: titrePlan,
                            notes: "",
                            context: modelContext
                        )
                        titrePlan = ""
                        showAjouterPlan = false
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Sheet plan IA

    private var planIASheet: some View {
        NavigationStack {
            ScrollView {
                Text(viewModel.planGenere)
                    .font(.nutriBody)
                    .padding(Spacing.md)
            }
            .navigationTitle("Plan IA — \(viewModel.labelSemaine)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { viewModel.showPlanIA = false }
                }
            }
        }
    }

    private func genererAvecIA() {
        guard let p = profil else { return }
        let service = ClaudeAIService()
        Task {
            await viewModel.genererAvecIA(service: service, profil: p, context: modelContext)
        }
    }
}

#Preview {
    NavigationStack {
        MealPlanView()
            .modelContainer(for: [MealPlan.self, FoodItem.self, UserProfile.self], inMemory: true)
    }
}
