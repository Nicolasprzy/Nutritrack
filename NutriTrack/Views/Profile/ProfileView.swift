import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var prenom: String = ""
    @State private var dateNaissance: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var sexe: String = "homme"
    @State private var taille: Double = 175.0
    @State private var objectifPoids: Double = 75.0
    @State private var niveauActivite: String = "modere"
    @State private var objectifCalorique: Double = 2000.0
    @State private var objectifProteines: Double = 150.0
    @State private var objectifGlucides: Double = 200.0
    @State private var objectifLipides: Double = 65.0
    @State private var claudeAPIKey: String = ""
    @State private var healthKitActif: Bool = false

    @State private var healthKitService = HealthKitService()
    @State private var showAPIKeyHelp = false
    @State private var isSaved = false
    @State private var showResetConfirm = false
    @State private var showDeleteConfirm = false

    @Query(sort: \BodyMetric.date, order: .reverse) private var metrics: [BodyMetric]
    @Query private var entries: [FoodEntry]
    @Query private var activites: [ActivityEntry]

    private var dernierPoids: Double { metrics.first?.weight ?? 0 }

    private var tdeeCalcule: Double {
        guard taille > 0 else { return 0 }
        return NutritionCalculator.tdee(
            poids: dernierPoids > 0 ? dernierPoids : objectifPoids,
            taille: taille,
            age: dateNaissance.age,
            sexe: sexe,
            niveauActivite: niveauActivite
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                informationsSection
                objectifsSection
                macrosSection
                coachIASection
                healthKitSection
                statsSection
                compteSection
            }
            .padding(Spacing.lg)
        }
        .navigationTitle("Profil")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: sauvegarder) {
                    if isSaved {
                        Label("Sauvegardé", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Color.nutriGreen)
                    } else {
                        Text("Sauvegarder")
                            .bold()
                    }
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
        .onAppear { chargerProfil() }
        .onChange(of: profiles.count) { _, _ in chargerProfil() }
    }

    // MARK: - Informations personnelles

    private var informationsSection: some View {
        profileSection(titre: "Informations personnelles", icone: "person.fill", couleur: .blue) {
            profileRow("Prénom") {
                TextField("Votre prénom", text: $prenom)
                    .multilineTextAlignment(.trailing)
            }
            Divider()
            profileRow("Date de naissance") {
                DatePicker("", selection: $dateNaissance, displayedComponents: .date)
                    .labelsHidden()
            }
            Divider()
            profileRow("Sexe") {
                Picker("", selection: $sexe) {
                    ForEach(Sexe.allCases, id: \.self) { s in
                        Text(s.label).tag(s.rawValue)
                    }
                }
                .labelsHidden()
                .frame(width: 120)
            }
            Divider()
            profileRow("Taille") {
                Stepper("\(taille.arrondi(0)) cm", value: $taille, in: 100...250, step: 0.5)
            }
            Divider()
            profileRow("Objectif poids") {
                HStack(spacing: 4) {
                    TextField("75", value: $objectifPoids, format: .number.precision(.fractionLength(1)))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("kg").foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Objectifs

    private var objectifsSection: some View {
        profileSection(titre: "Objectifs", icone: "target", couleur: .orange) {
            profileRow("Niveau d'activité") {
                Picker("", selection: $niveauActivite) {
                    ForEach(NiveauActivite.allCases, id: \.self) { n in
                        Text(n.label).tag(n.rawValue)
                    }
                }
                .labelsHidden()
                .frame(width: 180)
            }

            if tdeeCalcule > 0 {
                Divider()
                GlassCard(padding: Spacing.sm, cornerRadius: Radius.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TDEE calculé")
                                .font(.nutriHeadline)
                            Text("Dépense énergétique journalière")
                                .font(.nutriCaption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(tdeeCalcule.arrondi(0)) kcal")
                                .font(.nutriTitle2)
                                .foregroundStyle(Color.nutriGreen)
                            Button("Appliquer") {
                                appliquerTDEE()
                            }
                            .font(.nutriCaption)
                            .foregroundStyle(Color.nutriGreen)
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Macros

    private var macrosSection: some View {
        profileSection(titre: "Macros journaliers", icone: "chart.bar.fill", couleur: .nutriGreen) {
            macroLigne(label: "Calories", valeur: $objectifCalorique, unite: "kcal", couleur: .orange)
            Divider()
            macroLigne(label: "Protéines", valeur: $objectifProteines, unite: "g", couleur: .proteineColor)
            Divider()
            macroLigne(label: "Glucides", valeur: $objectifGlucides, unite: "g", couleur: .glucideColor)
            Divider()
            macroLigne(label: "Lipides", valeur: $objectifLipides, unite: "g", couleur: .lipideColor)
        }
    }

    private func macroLigne(label: String, valeur: Binding<Double>, unite: String, couleur: Color) -> some View {
        profileRow(label) {
            HStack(spacing: 4) {
                TextField("0", value: valeur, format: .number.precision(.fractionLength(0)))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                Text(unite).foregroundStyle(couleur)
            }
        }
    }

    // MARK: - Coach IA

    private var coachIASection: some View {
        profileSection(titre: "Coach IA", icone: "brain.head.profile", couleur: .cyan) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clé API Claude")
                            .font(.nutriHeadline)
                        Text("Depuis console.anthropic.com")
                            .font(.nutriCaption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: { showAPIKeyHelp.toggle() }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.cyan)
                    }
                    .buttonStyle(.plain)
                }

                SecureField("sk-ant-api...", text: $claudeAPIKey)
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.roundedBorder)

                if !claudeAPIKey.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.nutriGreen)
                        Text("Clé configurée")
                            .font(.nutriCaption)
                            .foregroundStyle(Color.nutriGreen)
                    }
                }
            }
        }
        .alert("Clé API Claude", isPresented: $showAPIKeyHelp) {
            Button("OK") {}
        } message: {
            Text("Créez un compte sur console.anthropic.com, puis générez une clé API dans la section \"API Keys\".")
        }
    }

    // MARK: - HealthKit

    private var healthKitSection: some View {
        profileSection(titre: "Santé", icone: "heart.fill", couleur: .red) {
            profileRow("Synchroniser avec HealthKit") {
                Toggle("", isOn: $healthKitActif)
                    .labelsHidden()
                    .onChange(of: healthKitActif) { _, actif in
                        if actif { Task { await healthKitService.demanderAutorisation() } }
                    }
            }

            if healthKitActif && healthKitService.isAuthorized {
                Divider()
                Button(action: {
                    Task { await healthKitService.importerPoidsDansSwiftData(context: modelContext) }
                }) {
                    Label("Importer mes données de poids", systemImage: "arrow.down.circle")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }

            if !healthKitService.isAvailable {
                Divider()
                Text("HealthKit non disponible sur cet appareil")
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        profileSection(titre: "Statistiques", icone: "chart.line.uptrend.xyaxis", couleur: .purple) {
            statLigne("Jours suivis", valeur: "\(joursFollowes)")
            Divider()
            statLigne("Aliments enregistrés", valeur: "\(entries.count)")
            Divider()
            statLigne("Activités enregistrées", valeur: "\(activites.count)")
            if dernierPoids > 0 && objectifPoids > 0 {
                let diff = dernierPoids - objectifPoids
                Divider()
                statLigne(
                    "Distance objectif poids",
                    valeur: diff > 0 ? "+\(diff.arrondi(1)) kg" : "\(diff.arrondi(1)) kg"
                )
            }
        }
    }

    private var joursFollowes: Int {
        Set(entries.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    private func statLigne(_ label: String, valeur: String) -> some View {
        HStack {
            Text(label).font(.nutriBody)
            Spacer()
            Text(valeur).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Compte

    private var compteSection: some View {
        profileSection(titre: "Compte", icone: "person.crop.circle", couleur: .gray) {
            Button(role: .destructive, action: { showResetConfirm = true }) {
                Label("Réinitialiser le profil", systemImage: "person.crop.circle.badge.minus")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
            .confirmationDialog("Réinitialiser le profil ?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Réinitialiser", role: .destructive) { reinitialiserProfil() }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Votre profil sera supprimé et l'onboarding s'affichera à nouveau. Vos données alimentaires et corporelles seront conservées.")
            }

            Divider()

            Button(role: .destructive, action: { showDeleteConfirm = true }) {
                Label("Supprimer toutes les données", systemImage: "trash.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
            .confirmationDialog("Supprimer toutes les données ?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Tout supprimer", role: .destructive) { supprimerToutesLesDonnees() }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Toutes vos données seront définitivement supprimées.")
            }
        }
    }

    // MARK: - Composants

    private func profileSection<Content: View>(
        titre: String, icone: String, couleur: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label(titre, systemImage: icone)
                    .font(.nutriHeadline)
                    .foregroundStyle(couleur)
                Divider()
                content()
            }
        }
    }

    private func profileRow<Content: View>(_ label: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.nutriBody)
            Spacer()
            trailing()
        }
        .padding(.vertical, 2)
    }

    // MARK: - Actions

    private func appliquerTDEE() {
        objectifCalorique = tdeeCalcule
        let macros = NutritionCalculator.macrosCibles(calories: tdeeCalcule)
        objectifProteines = macros.proteines
        objectifGlucides  = macros.glucides
        objectifLipides   = macros.lipides
    }

    private func reinitialiserProfil() {
        if let p = profiles.first {
            modelContext.delete(p)
            try? modelContext.save()
        }
    }

    private func supprimerToutesLesDonnees() {
        try? modelContext.delete(model: FoodEntry.self)
        try? modelContext.delete(model: BodyMetric.self)
        try? modelContext.delete(model: ActivityEntry.self)
        try? modelContext.delete(model: MealPlan.self)
        try? modelContext.delete(model: FoodItem.self)
        try? modelContext.delete(model: UserProfile.self)
        try? modelContext.save()
    }

    private func chargerProfil() {
        guard let p = profiles.first else { return }
        prenom            = p.prenom
        dateNaissance     = p.dateNaissance
        sexe              = p.sexe
        taille            = p.taille
        objectifPoids     = p.objectifPoids
        niveauActivite    = p.niveauActivite
        objectifCalorique = p.objectifCalorique
        objectifProteines = p.objectifProteines
        objectifGlucides  = p.objectifGlucides
        objectifLipides   = p.objectifLipides
        claudeAPIKey      = p.claudeAPIKey
        healthKitActif    = p.healthKitActif
    }

    private func sauvegarder() {
        let p = profiles.first ?? {
            let nouveau = UserProfile()
            modelContext.insert(nouveau)
            return nouveau
        }()
        p.prenom            = prenom
        p.dateNaissance     = dateNaissance
        p.sexe              = sexe
        p.taille            = taille
        p.objectifPoids     = objectifPoids
        p.niveauActivite    = niveauActivite
        p.objectifCalorique = objectifCalorique
        p.objectifProteines = objectifProteines
        p.objectifGlucides  = objectifGlucides
        p.objectifLipides   = objectifLipides
        p.claudeAPIKey      = claudeAPIKey
        p.healthKitActif    = healthKitActif
        try? modelContext.save()
        withAnimation { isSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { isSaved = false }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .modelContainer(for: [
                UserProfile.self, BodyMetric.self, FoodEntry.self, ActivityEntry.self
            ], inMemory: true)
    }
    .frame(width: 700, height: 700)
}
