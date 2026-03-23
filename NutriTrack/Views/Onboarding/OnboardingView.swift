import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    var onComplete: () -> Void

    @State private var etape: Int = 0
    @State private var prenom: String = ""
    @State private var dateNaissance: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var sexe: String = "homme"
    @State private var taille: Double = 175.0
    @State private var objectifPoids: Double = 75.0
    @State private var niveauActivite: String = "modere"
    @State private var claudeAPIKey: String = ""
    @State private var offsetX: CGFloat = 0

    private let totalEtapes = 3

    var body: some View {
        ZStack {
            // Fond dégradé
            LinearGradient(
                colors: [
                    Color.nutriGreen.opacity(0.3),
                    Color.blue.opacity(0.2),
                    Color.fondPrincipal
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                // En-tête
                entete

                // Contenu de l'étape
                contenuEtape
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(etape)

                // Navigation
                navigationBoutons
            }
            .padding(Spacing.xl)
            .frame(maxWidth: 480)
        }
    }

    // MARK: - En-tête

    private var entete: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.nutriGreen)

            Text("NutriTrack")
                .font(.system(size: 36, weight: .bold, design: .rounded))

            Text("Votre coach nutritionnel personnel")
                .font(.nutriBody)
                .foregroundStyle(.secondary)

            // Indicateur de progression
            HStack(spacing: Spacing.sm) {
                ForEach(0..<totalEtapes, id: \.self) { i in
                    Capsule()
                        .fill(i <= etape ? Color.nutriGreen : Color.secondary.opacity(0.3))
                        .frame(width: i == etape ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: etape)
                }
            }
        }
    }

    // MARK: - Contenu par étape

    @ViewBuilder
    private var contenuEtape: some View {
        switch etape {
        case 0: etape1Profil
        case 1: etape2Objectifs
        case 2: etape3CoachIA
        default: EmptyView()
        }
    }

    // Étape 1 — Profil
    private var etape1Profil: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Label("Votre profil", systemImage: "person.circle.fill")
                    .font(.nutriTitle2)
                    .foregroundStyle(Color.nutriGreen)

                VStack(spacing: Spacing.sm) {
                    champTexte(label: "Prénom", placeholder: "Jean", value: $prenom)

                    DatePicker("Date de naissance", selection: $dateNaissance, displayedComponents: .date)
                        .font(.nutriBody)

                    Picker("Sexe", selection: $sexe) {
                        ForEach(Sexe.allCases, id: \.self) { s in
                            Text(s.label).tag(s.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Taille")
                            .font(.nutriBody)
                        Spacer()
                        Stepper("\(taille.arrondi(0)) cm", value: $taille, in: 100...250, step: 1)
                    }
                }
            }
        }
    }

    // Étape 2 — Objectifs
    private var etape2Objectifs: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Label("Vos objectifs", systemImage: "target")
                    .font(.nutriTitle2)
                    .foregroundStyle(.blue)

                VStack(spacing: Spacing.sm) {
                    HStack {
                        Text("Poids cible (kg)")
                            .font(.nutriBody)
                        Spacer()
                        TextField("kg", value: $objectifPoids, format: .number.precision(.fractionLength(1)))
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Niveau d'activité physique")
                            .font(.nutriBody)

                        ForEach(NiveauActivite.allCases, id: \.self) { niveau in
                            Button(action: { niveauActivite = niveau.rawValue }) {
                                HStack {
                                    Image(systemName: niveauActivite == niveau.rawValue ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(niveauActivite == niveau.rawValue ? .nutriGreen : .secondary)
                                    Text(niveau.label)
                                        .font(.nutriBody)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Aperçu TDEE
                    if taille > 0 && objectifPoids > 0 {
                        let tdee = NutritionCalculator.tdee(
                            poids: objectifPoids,
                            taille: taille,
                            age: dateNaissance.age,
                            sexe: sexe,
                            niveauActivite: niveauActivite
                        )
                        HStack {
                            Text("TDEE estimé")
                            Spacer()
                            Text("\(tdee.arrondi(0)) kcal/jour")
                                .foregroundStyle(Color.nutriGreen)
                        }
                        .font(.nutriCaption)
                        .padding(.top, Spacing.xs)
                    }
                }
            }
        }
    }

    // Étape 3 — Coach IA
    private var etape3CoachIA: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Label("Coach IA (optionnel)", systemImage: "brain.head.profile")
                    .font(.nutriTitle2)
                    .foregroundStyle(.cyan)

                Text("NutriTrack utilise Claude (Anthropic) pour vous fournir des conseils nutritionnels personnalisés.")
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)

                SecureField("Clé API Claude (sk-ant-...)", text: $claudeAPIKey)
                    .font(.system(.body, design: .monospaced))
                    .padding(Spacing.sm)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.md))

                Text("Obtenez votre clé sur console.anthropic.com · Vous pourrez la configurer plus tard dans le Profil.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !claudeAPIKey.isEmpty {
                    Label("Clé configurée !", systemImage: "checkmark.circle.fill")
                        .font(.nutriCaption)
                        .foregroundStyle(Color.nutriGreen)
                }
            }
        }
    }

    // MARK: - Navigation

    private var navigationBoutons: some View {
        HStack(spacing: Spacing.md) {
            if etape > 0 {
                Button(action: { withAnimation { etape -= 1 } }) {
                    Label("Retour", systemImage: "chevron.left")
                        .font(.nutriBody)
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Button(action: { avancer() }) {
                HStack {
                    Text(etape == totalEtapes - 1 ? "Commencer !" : "Suivant")
                    if etape < totalEtapes - 1 {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.nutriHeadline)
                .padding(.horizontal, Spacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(.nutriGreen)
            .disabled(etape == 0 && prenom.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - Helpers

    private func champTexte(label: String, placeholder: String, value: Binding<String>) -> some View {
        HStack {
            Text(label).font(.nutriBody)
            Spacer()
            TextField(placeholder, text: value)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 200)
        }
    }

    private func avancer() {
        if etape < totalEtapes - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                etape += 1
            }
        } else {
            creerProfil()
        }
    }

    private func creerProfil() {
        let profil = UserProfile(
            prenom:         prenom,
            dateNaissance:  dateNaissance,
            sexe:           sexe,
            taille:         taille,
            objectifPoids:  objectifPoids,
            niveauActivite: niveauActivite
        )

        // Calculer les objectifs calorique et macros depuis le TDEE
        let tdee = NutritionCalculator.tdee(
            poids: objectifPoids,
            taille: taille,
            age: dateNaissance.age,
            sexe: sexe,
            niveauActivite: niveauActivite
        )
        let macros = NutritionCalculator.macrosCibles(calories: tdee)
        profil.objectifCalorique = tdee
        profil.objectifProteines = macros.proteines
        profil.objectifGlucides  = macros.glucides
        profil.objectifLipides   = macros.lipides
        profil.claudeAPIKey      = claudeAPIKey

        modelContext.insert(profil)
        try? modelContext.save()

        onComplete()
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: UserProfile.self, inMemory: true)
        .frame(width: 500, height: 700)
}
