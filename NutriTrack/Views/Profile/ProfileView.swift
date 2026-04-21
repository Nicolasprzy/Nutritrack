import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.activeProfileID) private var activeProfileID
    @Query private var profiles: [UserProfile]

    var onDeconnexion: () -> Void = {}
    var onNouveauProfil: () -> Void = {}

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
    @State private var healthKitActif: Bool = false

    // MARK: - Champs v2
    @State private var silhouetteActuelle: String = ""
    @State private var silhouetteObjectif: String = ""
    @State private var dateObjectif: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var frequenceReevaluation: Int = 14
    @State private var approcheTransformation: String = "normale"

    // Sport
    @State private var niveauSport: String = "debutant"
    @State private var equipementSport: String = "salle"
    @State private var frequenceEntrainement: Int = 3
    @State private var dureeSeance: Int = 60
    @State private var sportsAprecies: [String] = []

    // Nutrition
    @State private var regimeAlimentaire: String = "omnivore"
    @State private var allergies: [String] = []
    @State private var nbRepasJour: Int = 3
    @State private var alimentsAimes: String = ""
    @State private var alimentsDetestes: String = ""

    // Vie
    @State private var qualiteSommeil: Int = 3
    @State private var dureeSommeil: Double = 7.0
    @State private var niveauStress: Int = 3
    @State private var alcool: String = "jamais"
    @State private var tabac: Bool = false
    @State private var hydratation: Double = 1.5

    @State private var isSaved = false

    @Query(sort: \BodyMetric.date, order: .reverse) private var metrics: [BodyMetric]
    @Query private var entries: [FoodEntry]
    @Query private var activites: [ActivityEntry]

    private var profilActif: UserProfile? {
        profiles.first(where: { $0.profileID.uuidString == activeProfileID })
    }

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
                LuminaSectionHeader(
                    eyebrow: "Acte VI · Identité",
                    title: "Profil",
                    emphasis: "& paramètres."
                )
                .padding(.top, Spacing.sm)

                // 1. Qui suis-je
                ProfileHeaderSection(
                    prenom: $prenom,
                    dateNaissance: $dateNaissance,
                    sexe: $sexe,
                    taille: $taille,
                    objectifPoids: $objectifPoids
                )
                // 2. Corps & silhouette (actuelle → objectif + date + réévaluation)
                ProfileGoalsSection(
                    sexe: $sexe,
                    silhouetteActuelle: $silhouetteActuelle,
                    silhouetteObjectif: $silhouetteObjectif,
                    dateObjectif: $dateObjectif,
                    frequenceReevaluation: $frequenceReevaluation,
                    approcheTransformation: $approcheTransformation
                )
                // 3. Objectifs & macros (TDEE + macros)
                objectifsSection
                macrosSection
                // 4. Mode de vie (sport → nutrition → vie)
                sportSection
                nutritionSection
                vieSection
                // 5. Outils
                ProfileHealthKitSection(healthKitActif: $healthKitActif)
                ProfileExportSection()
                // 6. Compte
                statsSection

                // Sprint 3 — Objectifs physiques + cibles macro + actions plan nutrition
                if let profil = profilActif {
                    ObjectifsPhysiquesSection(profil: profil)
                    CiblesMacroSection(profileID: activeProfileID)
                    PlanNutritionActionsSection(profil: profil)
                }

                ProfileDangerSection(
                    prenomProfil: profilActif?.prenom ?? "",
                    onDeconnexion: onDeconnexion,
                    onNouveauProfil: onNouveauProfil,
                    onReinitialiser: reinitialiserProfil,
                    onSupprimer: supprimerCeProfil
                )
            }
            .padding(Spacing.lg)
        }
        .navigationTitle("")
        .background(Color.fondPrincipal.opacity(0.70))
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
        .onChange(of: activeProfileID)         { _, _ in chargerProfil() }
        // Recalcul instantané des macros quand l'approche ou la cible changent
        .onChange(of: approcheTransformation)  { _, _ in recalculerMacros() }
        .onChange(of: silhouetteObjectif)      { _, _ in recalculerMacros() }
        .onChange(of: silhouetteActuelle)      { _, _ in recalculerMacros() }
        .onChange(of: dateObjectif)            { _, _ in recalculerMacros() }
        .onChange(of: niveauActivite)          { _, _ in recalculerMacros() }
    }

    // MARK: - Sport (v2)

    private var sportSection: some View {
        profileSection(titre: "Sport & entraînement", icone: "dumbbell.fill", couleur: .orange) {
            profileRow("Niveau") {
                Picker("", selection: $niveauSport) {
                    ForEach(NiveauSport.allCases, id: \.self) { n in
                        Text(n.label).tag(n.rawValue)
                    }
                }
                .labelsHidden().frame(width: 160)
            }
            Divider()
            profileRow("Équipement") {
                Picker("", selection: $equipementSport) {
                    ForEach(EquipementSport.allCases, id: \.self) { e in
                        Text(e.label).tag(e.rawValue)
                    }
                }
                .labelsHidden().frame(width: 160)
            }
            Divider()
            profileRow("Séances / semaine") {
                Stepper("\(frequenceEntrainement)×", value: $frequenceEntrainement, in: 1...7)
            }
            Divider()
            profileRow("Durée séance") {
                Stepper("\(dureeSeance) min", value: $dureeSeance, in: 20...180, step: 10)
            }
        }
    }

    // MARK: - Nutrition (v2)

    private var nutritionSection: some View {
        profileSection(titre: "Alimentation", icone: "fork.knife", couleur: .nutriGreen) {
            profileRow("Régime") {
                Picker("", selection: $regimeAlimentaire) {
                    ForEach(RegimeAlimentaire.allCases, id: \.self) { r in
                        Text(r.label).tag(r.rawValue)
                    }
                }
                .labelsHidden().frame(width: 160)
            }
            Divider()
            profileRow("Repas / jour") {
                Stepper("\(nbRepasJour)", value: $nbRepasJour, in: 2...6)
            }
            Divider()
            profileRow("Aliments aimés") {
                TextField("Ex: poulet, riz…", text: $alimentsAimes)
                    .multilineTextAlignment(.trailing).frame(maxWidth: 200)
            }
            Divider()
            profileRow("Aliments évités") {
                TextField("Ex: poissons…", text: $alimentsDetestes)
                    .multilineTextAlignment(.trailing).frame(maxWidth: 200)
            }
        }
    }

    // MARK: - Vie (v2)

    private var vieSection: some View {
        profileSection(titre: "Habitudes de vie", icone: "moon.fill", couleur: .indigo) {
            profileRow("Qualité du sommeil") {
                starPicker(value: $qualiteSommeil, color: .indigo)
            }
            Divider()
            profileRow("Durée sommeil") {
                Stepper("\(dureeSommeil.arrondi(1)) h", value: $dureeSommeil, in: 4...12, step: 0.5)
            }
            Divider()
            profileRow("Niveau de stress") {
                starPicker(value: $niveauStress, color: .red)
            }
            Divider()
            profileRow("Alcool") {
                Picker("", selection: $alcool) {
                    ForEach(AlcoolHabitude.allCases, id: \.self) { a in
                        Text(a.label).tag(a.rawValue)
                    }
                }
                .labelsHidden().frame(width: 160)
            }
            Divider()
            profileRow("Tabac") {
                Toggle("", isOn: $tabac).labelsHidden()
            }
            Divider()
            profileRow("Hydratation habituelle") {
                Stepper("\(hydratation.arrondi(1)) L", value: $hydratation, in: 0.5...5.0, step: 0.25)
            }
        }
    }

    private func starPicker(value: Binding<Int>, color: Color) -> some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= value.wrappedValue ? "star.fill" : "star")
                    .foregroundStyle(i <= value.wrappedValue ? color : .secondary)
                    .font(.caption)
                    .onTapGesture { value.wrappedValue = i }
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
        HStack(alignment: .center) {
            Text(label)
                .font(.nutriBody)
                .foregroundStyle(.primary)
            Spacer()
            trailing()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    /// Recalcule calories + macros à partir des @State courants, sans sauvegarder.
    /// Appelé instantanément à chaque changement d'approche, silhouette ou date.
    private func recalculerMacros() {
        guard !silhouetteObjectif.isEmpty, taille > 0 else { return }
        let poids = dernierPoids > 0 ? dernierPoids : objectifPoids
        guard poids > 0 else { return }

        let temp = UserProfile(
            prenom: "", dateNaissance: dateNaissance,
            sexe: sexe, taille: taille, niveauActivite: niveauActivite
        )
        temp.poidsActuel            = poids
        temp.silhouetteActuelle     = silhouetteActuelle
        temp.silhouetteObjectif     = silhouetteObjectif
        temp.dateObjectif           = dateObjectif
        temp.approcheTransformation = approcheTransformation

        let obj = NutritionCalculator.objectifsCaloriques(profil: temp)
        let mac = NutritionCalculator.macrosCiblesTransformation(
            calories:   obj.objectifTransformation,
            poidsKg:    poids,
            ajustement: obj.ajustement,
            approche:   temp.approcheEnum
        )
        withAnimation(.easeInOut(duration: 0.25)) {
            objectifCalorique = obj.objectifTransformation
            objectifProteines = mac.proteines
            objectifGlucides  = mac.glucides
            objectifLipides   = mac.lipides
        }
    }

    private func appliquerTDEE() {
        objectifCalorique = tdeeCalcule
        let macros = NutritionCalculator.macrosCibles(calories: tdeeCalcule)
        objectifProteines = macros.proteines
        objectifGlucides  = macros.glucides
        objectifLipides   = macros.lipides
    }

    private func reinitialiserProfil() {
        if let p = profilActif {
            modelContext.delete(p)
            try? modelContext.save()
        }
    }

    /// Supprime uniquement le profil actif — les autres profils ne sont pas affectés.
    private func supprimerCeProfil() {
        guard let p = profilActif else { return }
        modelContext.delete(p)
        try? modelContext.save()
        onDeconnexion()
    }

    private func chargerProfil() {
        guard let p = profilActif else { return }
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
        healthKitActif    = p.healthKitActif

        // v2
        silhouetteActuelle    = p.silhouetteActuelle
        silhouetteObjectif    = p.silhouetteObjectif
        dateObjectif          = p.dateObjectif
        frequenceReevaluation = p.frequenceReevaluation
        approcheTransformation = p.approcheTransformation
        niveauSport          = p.niveauSport
        equipementSport      = p.equipementSport
        frequenceEntrainement = p.frequenceEntrainementJours
        dureeSeance          = p.dureeSeanceMinutes
        sportsAprecies       = p.sportsAprecies
        regimeAlimentaire    = p.regimeAlimentaire
        allergies            = p.allergies
        nbRepasJour          = p.nbRepasJour
        alimentsAimes        = p.alimentsAimes
        alimentsDetestes     = p.alimentsDetestes
        qualiteSommeil       = p.qualiteSommeil
        dureeSommeil         = p.dureeSommeilHeures
        niveauStress         = p.niveauStress
        alcool               = p.alcool
        tabac                = p.tabac
        hydratation          = p.hydratationHabituelleLitres
    }

    private func sauvegarder() {
        let p = profilActif ?? {
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
        p.healthKitActif    = healthKitActif

        // v2
        p.silhouetteActuelle        = silhouetteActuelle
        p.silhouetteObjectif        = silhouetteObjectif
        p.dateObjectif              = dateObjectif
        p.frequenceReevaluation     = frequenceReevaluation
        p.approcheTransformation    = approcheTransformation
        p.niveauSport                = niveauSport
        p.equipementSport            = equipementSport
        p.frequenceEntrainementJours = frequenceEntrainement
        p.dureeSeanceMinutes         = dureeSeance
        p.sportsAprecies             = sportsAprecies
        p.regimeAlimentaire          = regimeAlimentaire
        p.allergies                  = allergies
        p.nbRepasJour                = nbRepasJour
        p.alimentsAimes              = alimentsAimes
        p.alimentsDetestes           = alimentsDetestes
        p.qualiteSommeil             = qualiteSommeil
        p.dureeSommeilHeures         = dureeSommeil
        p.niveauStress               = niveauStress
        p.alcool                     = alcool
        p.tabac                      = tabac
        p.hydratationHabituelleLitres = hydratation

        // Recalcule automatiquement les objectifs si un objectif silhouette est défini
        if !p.silhouetteObjectif.isEmpty {
            let objectifs = NutritionCalculator.objectifsCaloriques(profil: p)
            let macros = NutritionCalculator.macrosCiblesTransformation(
                calories:   objectifs.objectifTransformation,
                poidsKg:    p.poidsActuel,
                ajustement: objectifs.ajustement,
                approche:   p.approcheEnum
            )
            p.objectifCalorique = objectifs.objectifTransformation
            p.objectifProteines = macros.proteines
            p.objectifGlucides  = macros.glucides
            p.objectifLipides   = macros.lipides
        }

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
