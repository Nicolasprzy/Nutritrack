import SwiftUI
import SwiftData

// MARK: - Données statiques

private let sportsDisponibles = [
    "Musculation", "Course à pied", "Vélo", "Natation",
    "Yoga", "HIIT", "Boxe / MMA", "Football", "Tennis",
    "Randonnée", "Pilates", "Escalade", "Danse", "Autre"
]

private let allergiesCommunes = [
    "Gluten", "Lactose", "Arachides", "Fruits à coque",
    "Œufs", "Poissons", "Crustacés", "Soja"
]

// MARK: - Flux onboarding
// 0. Identité
// 1. Mensurations
// 2. Silhouette (actuelle + cible)
// 3. Sport
// 4. Nutrition
// 5. Habitudes de vie + Clé API
// 6. Objectif & Faisabilité complète

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("activeProfileID") private var activeProfileID: String = ""
    var onComplete: () -> Void

    @State private var etape: Int = 0
    private let totalEtapes = 7

    // Étape 0 — Identité
    @State private var prenom: String = ""
    @State private var dateNaissance: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var sexe: String = "homme"
    @State private var taille: Double = 175.0
    @State private var poidsActuel: Double = 75.0

    // Étape 1 — Mensurations
    @State private var mensurationTaille: Double = 0
    @State private var mensurationHanches: Double = 0
    @State private var mensurationPoitrine: Double = 0
    @State private var mensurationBras: Double = 0
    @State private var mensurationCuisse: Double = 0
    @State private var masseGraisseuse: Double = 0    // % (0 = non renseigné)

    // Étape 2 — Silhouette actuelle + cible
    @State private var silhouetteActuelle: String = ""
    @State private var silhouetteObjectif: String = ""

    // Étape 3 — Sport
    @State private var niveauSport: String = "debutant"
    @State private var equipementSport: String = "salle"
    @State private var sportsSelectionnes: [String] = []
    @State private var frequenceEntrainement: Int = 3
    @State private var dureeSeance: Int = 60

    // Étape 4 — Nutrition
    @State private var regimeAlimentaire: String = "omnivore"
    @State private var allergiesSelectionnees: [String] = []
    @State private var nbRepasJour: Int = 3
    @State private var alimentsAimes: String = ""
    @State private var alimentsDetestes: String = ""

    // Étape 5 — Vie + Clé API
    @State private var qualiteSommeil: Int = 3
    @State private var dureeSommeil: Double = 7.0
    @State private var niveauStress: Int = 3
    @State private var niveauActivite: String = "modere"
    @State private var alcool: String = "jamais"
    @State private var tabac: Bool = false
    @State private var hydratation: Double = 1.5
    @State private var claudeAPIKey: String = ""

    // Étape 6 — Objectif + faisabilité
    @State private var dateObjectif: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var frequenceReevaluation: Int = 14
    @State private var objectifForce: Bool = false
    @State private var approcheTransformation: String = "normale"

    // MARK: - Métadonnées visuelles

    private var couleurEtape: Color {
        switch etape {
        case 0: return .blue
        case 1: return Color(hue: 0.78, saturation: 0.55, brightness: 0.75)
        case 2: return .teal
        case 3: return .red
        case 4: return .orange
        case 5: return .indigo
        case 6: return Color.nutriGreen
        default: return Color.nutriGreen
        }
    }

    private var iconeEtape: String {
        switch etape {
        case 0: return "person.fill"
        case 1: return "ruler"
        case 2: return "figure.arms.open"
        case 3: return "dumbbell.fill"
        case 4: return "fork.knife"
        case 5: return "moon.stars.fill"
        case 6: return "checkmark.seal.fill"
        default: return "checkmark.circle.fill"
        }
    }

    private var titreEtape: String {
        switch etape {
        case 0: return "Parlez-nous de vous"
        case 1: return "Vos mesures actuelles"
        case 2: return "Votre transformation"
        case 3: return "Vos habitudes sportives"
        case 4: return "Vos préférences alimentaires"
        case 5: return "Votre mode de vie"
        case 6: return "Votre objectif"
        default: return ""
        }
    }

    private var couleurBouton: Color {
        if etape == 6 && evaluerFaisabilite() == .dangereux && !objectifForce { return .red }
        return couleurEtape
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [couleurEtape.opacity(0.13), Color.blue.opacity(0.05), Color.fondPrincipal],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .animation(.easeInOut(duration: 0.5), value: etape)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        stepHero
                        contenuEtape
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, 90)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(etape)
                }
            }

            bottomNavigation
        }
        .frame(maxWidth: 520)
    }

    // MARK: - Top bar

    private var topBar: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(Color.nutriGreen)
                    Text("NutriTrack")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                Spacer()
                Text("\(etape + 1) / \(totalEtapes)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            HStack(spacing: 0) {
                ForEach(0..<totalEtapes, id: \.self) { i in
                    stepDot(index: i)
                    if i < totalEtapes - 1 {
                        Rectangle()
                            .fill(i < etape ? Color.nutriGreen.opacity(0.5) : Color.secondary.opacity(0.15))
                            .frame(height: 2)
                            .animation(.easeInOut(duration: 0.4), value: etape)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.sm)
    }

    private func stepDot(index: Int) -> some View {
        let isDone = index < etape
        let isCurrent = index == etape
        return ZStack {
            Circle()
                .fill(isDone ? Color.nutriGreen : (isCurrent ? couleurEtape : Color.secondary.opacity(0.15)))
                .frame(width: 26, height: 26)
                .shadow(color: isCurrent ? couleurEtape.opacity(0.45) : .clear, radius: 8)
            Group {
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isCurrent ? .white : Color.secondary)
                }
            }
        }
        .scaleEffect(isCurrent ? 1.2 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: etape)
    }

    // MARK: - Step hero

    private var stepHero: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [couleurEtape, couleurEtape.opacity(0.72)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 78, height: 78)
                    .shadow(color: couleurEtape.opacity(0.36), radius: 16, x: 0, y: 8)
                Image(systemName: iconeEtape)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.white)
            }
            Text(titreEtape)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Bottom navigation

    private var bottomNavigation: some View {
        HStack(spacing: Spacing.md) {
            if etape > 0 {
                Button(action: { withAnimation(.spring(response: 0.35)) { etape -= 1 } }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 50, height: 50)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.secondary.opacity(0.18), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }

            Button(action: avancer) {
                HStack(spacing: 8) {
                    Text(labelBoutonSuivant)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    if etape < totalEtapes - 1 {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    boutonSuivantActif
                        ? LinearGradient(colors: [couleurBouton, couleurBouton.opacity(0.82)],
                                         startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.secondary.opacity(0.22), Color.secondary.opacity(0.18)],
                                         startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .foregroundStyle(boutonSuivantActif ? .white : Color.secondary)
                .shadow(color: boutonSuivantActif ? couleurBouton.opacity(0.28) : .clear, radius: 8, x: 0, y: 4)
                .animation(.easeInOut(duration: 0.2), value: boutonSuivantActif)
            }
            .buttonStyle(.plain)
            .disabled(!boutonSuivantActif)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .background(.ultraThinMaterial)
    }

    // MARK: - Contenu par étape

    @ViewBuilder
    private var contenuEtape: some View {
        switch etape {
        case 0: etape0Identite
        case 1: etape1Mensurations
        case 2: etape2Silhouette
        case 3: etape3Sport
        case 4: etape4Nutrition
        case 5: etape5Vie
        case 6: etape6Bilan
        default: EmptyView()
        }
    }

    // MARK: — Étape 0 : Identité (redesignée)

    private var etape0Identite: some View {
        VStack(spacing: Spacing.lg) {
            // Avatar animé
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .blue.opacity(0.6)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 96, height: 96)
                    .shadow(color: .blue.opacity(0.3), radius: 18, x: 0, y: 8)

                let initiales = prenom.trimmingCharacters(in: .whitespaces)
                    .split(separator: " ").prefix(2)
                    .compactMap { $0.first }
                    .map { String($0) }.joined().uppercased()

                if initiales.isEmpty {
                    Image(systemName: "person.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(.white.opacity(0.6))
                } else {
                    Text(initiales)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: prenom)

            GlassCard {
                VStack(spacing: 0) {
                    // Prénom
                    identiteRow(icon: "person.fill", label: "Prénom", color: .blue) {
                        TextField("Jean", text: $prenom)
                            .multilineTextAlignment(.trailing)
                            .font(.nutriBody)
                    }

                    Divider().padding(.vertical, 2)

                    // Date de naissance
                    identiteRow(icon: "calendar", label: "Né(e) le", color: .blue) {
                        DatePicker("", selection: $dateNaissance, displayedComponents: .date)
                            .labelsHidden()
                    }

                    Divider().padding(.vertical, 2)

                    // Genre — deux boutons visuels
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.2.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 22)
                            Text("Je suis")
                                .font(.nutriBody)
                        }
                        HStack(spacing: Spacing.sm) {
                            ForEach(Sexe.allCases, id: \.self) { s in
                                genreButton(s)
                            }
                        }
                    }
                    .padding(.vertical, Spacing.sm)

                    Divider().padding(.vertical, 2)

                    // Taille
                    identiteRow(icon: "arrow.up.and.down", label: "Taille", color: .blue) {
                        HStack(spacing: 4) {
                            TextField("175", value: $taille, format: .number.precision(.fractionLength(0)))
                                .multilineTextAlignment(.trailing)
                                .frame(width: 52)
                            Text("cm").foregroundStyle(.secondary).font(.callout)
                        }
                    }

                    Divider().padding(.vertical, 2)

                    // Poids
                    identiteRow(icon: "scalemass.fill", label: "Poids actuel", color: .blue) {
                        HStack(spacing: 4) {
                            TextField("75", value: $poidsActuel, format: .number.precision(.fractionLength(1)))
                                .multilineTextAlignment(.trailing)
                                .frame(width: 52)
                            Text("kg").foregroundStyle(.secondary).font(.callout)
                        }
                    }
                }
            }
        }
    }

    private func identiteRow<Content: View>(icon: String, label: String, color: Color, @ViewBuilder trailing: () -> Content) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(color.opacity(0.8))
                .frame(width: 22)
                .font(.callout)
            Text(label).font(.nutriBody)
            Spacer()
            trailing()
        }
        .padding(.vertical, Spacing.sm)
    }

    private func genreButton(_ s: Sexe) -> some View {
        let selected = sexe == s.rawValue
        return Button(action: { withAnimation(.spring(response: 0.25)) { sexe = s.rawValue } }) {
            HStack(spacing: 8) {
                Image(systemName: s.rawValue == "homme" ? "figure.stand" : "figure.stand.dress")
                    .font(.system(size: 18))
                Text(s.label)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(selected ? Color.blue.opacity(0.14) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(selected ? Color.blue : Color.secondary.opacity(0.22), lineWidth: 1))
            .foregroundStyle(selected ? .blue : .secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: — Étape 1 : Mensurations (saisie directe)

    private var etape1Mensurations: some View {
        VStack(spacing: Spacing.md) {
            GlassCard {
                VStack(spacing: 0) {
                    mensurationField("Tour de taille", icon: "circle.dotted.and.circle",
                                     couleur: couleurEtape, value: $mensurationTaille)
                    Divider().padding(.vertical, 2)
                    mensurationField("Hanches", icon: "figure.arms.open",
                                     couleur: couleurEtape, value: $mensurationHanches)
                    Divider().padding(.vertical, 2)
                    mensurationField("Poitrine", icon: "heart.circle",
                                     couleur: couleurEtape, value: $mensurationPoitrine)
                    Divider().padding(.vertical, 2)
                    mensurationField("Bras (droit)", icon: "dumbbell",
                                     couleur: couleurEtape, value: $mensurationBras)
                    Divider().padding(.vertical, 2)
                    mensurationField("Cuisse", icon: "figure.walk",
                                     couleur: couleurEtape, value: $mensurationCuisse)
                }
            }

            // Masse graisseuse — champ dédié
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: 6) {
                        Image(systemName: "percent")
                            .foregroundStyle(couleurEtape.opacity(0.7))
                            .frame(width: 22)
                        Text("Masse graisseuse").font(.nutriBody)
                        Spacer()
                        if masseGraisseuse > 0 {
                            TextField("0", value: $masseGraisseuse,
                                      format: .number.precision(.fractionLength(1)))
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                                .textFieldStyle(.plain)
                            Text("%").foregroundStyle(.secondary)
                        } else {
                            Button("Ajouter") {
                                masseGraisseuse = 20.0
                            }
                            .font(.nutriCaption)
                            .foregroundStyle(couleurEtape)
                            .buttonStyle(.plain)
                        }
                    }
                    if masseGraisseuse > 0 {
                        let sexeEnum: Sexe = Sexe(rawValue: sexe) ?? .homme
                        // Trouver la silhouette correspondante
                        let silLabel = SilhouetteObjectif.allCases
                            .filter { s in
                                let range = s.rangeMasseGraisseuse(sexe: sexeEnum)
                                return !range.isEmpty
                            }
                            .first(where: { s in
                                masseGraisseuseDansRange(mg: masseGraisseuse, range: s.rangeMasseGraisseuse(sexe: sexeEnum))
                            })
                            .map { $0.label(sexe: sexeEnum) } ?? ""
                        if !silLabel.isEmpty {
                            Text("→ Correspond à : \(silLabel)")
                                .font(.caption)
                                .foregroundStyle(couleurEtape.opacity(0.8))
                                .padding(.leading, 28)
                        }
                    } else {
                        Text("Optionnel — affine les calculs de transformation (valeur mesurée par impédancemètre ou pince).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 28)
                    }
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Ces données permettent de suivre votre transformation avec précision. Vous pouvez les renseigner plus tard.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Spacing.sm)
        }
    }

    private func masseGraisseuseDansRange(mg: Double, range: String) -> Bool {
        // Parse "15–20 %" ou "< 15 %" ou "> 38 %"
        let r = range.replacingOccurrences(of: " %", with: "")
                     .replacingOccurrences(of: " ", with: "")
        if r.hasPrefix("<"), let max = Double(r.dropFirst()) { return mg < max }
        if r.hasPrefix(">"), let min = Double(r.dropFirst()) { return mg > min }
        let parts = r.components(separatedBy: "–")
        if parts.count == 2, let lo = Double(parts[0]), let hi = Double(parts[1]) {
            return mg >= lo && mg <= hi
        }
        return false
    }

    private func mensurationField(_ label: String, icon: String, couleur: Color, value: Binding<Double>) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(couleur.opacity(0.7))
                .frame(width: 22)
                .font(.callout)
            Text(label).font(.nutriBody)
            Spacer()
            HStack(spacing: 4) {
                TextField("0", value: value, format: .number.precision(.fractionLength(1)))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("cm").foregroundStyle(.secondary).font(.callout)
            }
        }
        .padding(.vertical, Spacing.sm)
    }

    // MARK: — Étape 2 : Silhouette actuelle + objectif

    private var etape2Silhouette: some View {
        VStack(spacing: Spacing.md) {
            // Silhouette actuelle
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.secondary)
                        Text("Ma silhouette actuelle")
                            .font(.nutriHeadline)
                            .foregroundStyle(.secondary)
                    }

                    SilhouettePicker(
                        sexe: Sexe(rawValue: sexe) ?? .homme,
                        selection: $silhouetteActuelle
                    )
                    .padding(.vertical, 4)

                    if !silhouetteActuelle.isEmpty,
                       let s = SilhouetteObjectif(rawValue: silhouetteActuelle) {
                        Label("Sélectionné : **\(s.label(sexe: Sexe(rawValue: sexe) ?? .homme))**",
                              systemImage: "checkmark.circle.fill")
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }

            // Flèche de transition
            HStack {
                Spacer()
                VStack(spacing: 3) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.nutriGreen.opacity(0.75))
                    Text("Transformation visée")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Silhouette objectif
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .foregroundStyle(Color.nutriGreen)
                        Text("Ma silhouette objectif")
                            .font(.nutriHeadline)
                            .foregroundStyle(Color.nutriGreen)
                    }

                    SilhouettePicker(
                        sexe: Sexe(rawValue: sexe) ?? .homme,
                        selection: $silhouetteObjectif
                    )
                    .padding(.vertical, 4)

                    if !silhouetteObjectif.isEmpty,
                       let s = SilhouetteObjectif(rawValue: silhouetteObjectif) {
                        Label("Objectif : **\(s.label(sexe: Sexe(rawValue: sexe) ?? .homme))**",
                              systemImage: "checkmark.circle.fill")
                        .font(.nutriCaption)
                        .foregroundStyle(Color.nutriGreen)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
    }

    // MARK: — Étape 3 : Sport

    private var etape3Sport: some View {
        VStack(spacing: Spacing.md) {
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Niveau actuel").font(.nutriBody)
                        HStack(spacing: Spacing.sm) {
                            ForEach(NiveauSport.allCases, id: \.self) { n in
                                niveauSportButton(n)
                            }
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Équipement disponible").font(.nutriBody)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(EquipementSport.allCases, id: \.self) { eq in
                                equipementButton(eq: eq)
                            }
                        }
                    }

                    Divider()

                    HStack {
                        Text("Séances par semaine").font(.nutriBody)
                        Spacer()
                        Stepper("\(frequenceEntrainement)×", value: $frequenceEntrainement, in: 1...7)
                    }
                    HStack {
                        Text("Durée par séance").font(.nutriBody)
                        Spacer()
                        Stepper("\(dureeSeance) min", value: $dureeSeance, in: 20...180, step: 10)
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Sports appréciés (optionnel)").font(.nutriBody)
                    FlowTags(items: sportsDisponibles, selection: $sportsSelectionnes, color: .red)
                }
            }
        }
    }

    private func niveauSportButton(_ n: NiveauSport) -> some View {
        let selected = niveauSport == n.rawValue
        return Button(action: { niveauSport = n.rawValue }) {
            HStack(spacing: 4) {
                Image(systemName: n.icon).font(.caption)
                Text(n.label).font(.nutriCaption)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(selected ? Color.red.opacity(0.18) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(selected ? Color.red : Color.secondary.opacity(0.3)))
            .foregroundStyle(selected ? .red : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func equipementButton(eq: EquipementSport) -> some View {
        let selected = equipementSport == eq.rawValue
        return Button(action: { equipementSport = eq.rawValue }) {
            HStack(spacing: 6) {
                Image(systemName: eq.icon).font(.caption)
                Text(eq.label).font(.system(size: 11, design: .rounded))
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selected ? Color.red.opacity(0.15) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(selected ? Color.red : Color.secondary.opacity(0.3)))
            .foregroundStyle(selected ? .red : .secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: — Étape 4 : Nutrition

    private var etape4Nutrition: some View {
        VStack(spacing: Spacing.md) {
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Régime alimentaire").font(.nutriBody)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(RegimeAlimentaire.allCases, id: \.self) { r in
                                let selected = regimeAlimentaire == r.rawValue
                                Button(action: { regimeAlimentaire = r.rawValue }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: r.icon).font(.caption)
                                        Text(r.label).font(.system(size: 12, design: .rounded))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(selected ? Color.orange.opacity(0.15) : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(selected ? Color.orange : Color.secondary.opacity(0.3)))
                                    .foregroundStyle(selected ? .orange : .secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider()

                    HStack {
                        Text("Repas par jour").font(.nutriBody)
                        Spacer()
                        Stepper("\(nbRepasJour)", value: $nbRepasJour, in: 1...8)
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Allergies / intolérances").font(.nutriBody)
                    FlowTags(items: allergiesCommunes, selection: $allergiesSelectionnees, color: .orange)
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Aliments appréciés").font(.nutriCaption).foregroundStyle(.secondary)
                    TextField("Ex: poulet, riz, légumes…", text: $alimentsAimes, axis: .vertical)
                        .font(.nutriBody).lineLimit(2...3)
                    Divider()
                    Text("Aliments à éviter").font(.nutriCaption).foregroundStyle(.secondary)
                    TextField("Ex: foie, betterave…", text: $alimentsDetestes, axis: .vertical)
                        .font(.nutriBody).lineLimit(2...3)
                }
            }
        }
    }

    // MARK: — Étape 5 : Vie + Clé API

    private var etape5Vie: some View {
        VStack(spacing: Spacing.md) {
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    starRow(label: "Qualité du sommeil", value: $qualiteSommeil, color: .indigo)
                    Divider()
                    HStack {
                        Text("Durée moyenne de sommeil").font(.nutriBody)
                        Spacer()
                        Stepper("\(dureeSommeil.arrondi(1)) h", value: $dureeSommeil, in: 3...12, step: 0.5)
                    }
                    Divider()
                    starRow(label: "Niveau de stress habituel", value: $niveauStress, color: .red)
                    Divider()
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Type de journée").font(.nutriBody)
                        Picker("Journée", selection: $niveauActivite) {
                            ForEach(NiveauActivite.allCases, id: \.self) { n in
                                Text(n.label).tag(n.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Consommation d'alcool").font(.nutriBody)
                        Picker("Alcool", selection: $alcool) {
                            ForEach(AlcoolHabitude.allCases, id: \.self) { a in
                                Text(a.label).tag(a.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Divider()
                    Toggle("Tabac", isOn: $tabac)
                    Divider()
                    HStack {
                        Text("Hydratation habituelle").font(.nutriBody)
                        Spacer()
                        Stepper("\(hydratation.arrondi(1)) L/j", value: $hydratation, in: 0.5...5, step: 0.25)
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label("Coach IA (optionnel)", systemImage: "brain.head.profile")
                        .font(.nutriTitle2).foregroundStyle(.cyan)
                    Text("Ajoutez votre clé Claude pour générer votre plan personnalisé immédiatement.")
                        .font(.nutriCaption).foregroundStyle(.secondary)
                    SecureField("Clé API Claude (sk-ant-…)", text: $claudeAPIKey)
                        .font(.system(.body, design: .monospaced))
                        .padding(Spacing.sm)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.md))
                    if !claudeAPIKey.isEmpty {
                        Label("Clé configurée", systemImage: "checkmark.circle.fill")
                            .font(.nutriCaption).foregroundStyle(Color.nutriGreen)
                    }
                }
            }
        }
    }

    // MARK: — Étape 6 : Bilan & Faisabilité complète

    private var etape6Bilan: some View {
        VStack(spacing: Spacing.md) {
            // Date + fréquence
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    DatePicker("Date cible", selection: $dateObjectif, in: Date()..., displayedComponents: .date)
                        .font(.nutriBody)
                    Divider()
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Réévaluation du plan").font(.nutriBody)
                        Picker("Fréquence", selection: $frequenceReevaluation) {
                            Text("7 jours").tag(7)
                            Text("14 jours").tag(14)
                            Text("30 jours").tag(30)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }

            // Approche de transformation
            approcheTransformationCard

            // Chiffres clés de l'analyse
            let analyse = analyseFaisabilite
            if analyse.kgEstimes > 0 {
                HStack(spacing: Spacing.sm) {
                    analyseMinicarte(label: "Objectif", value: "\(analyse.kgEstimes.arrondi(1)) kg",
                                     icon: "scalemass.fill", color: .blue)
                    analyseMinicarte(label: "Déficit/j", value: "\(Int(analyse.kcalParJour)) kcal",
                                     icon: "bolt.fill", color: .orange)
                    analyseMinicarte(label: "Durée min.", value: "\(analyse.semainesMin) sem.",
                                     icon: "calendar.badge.clock", color: Color.nutriGreen)
                }
            }

            // Badge faisabilité
            faisabiliteView

            // Résumé profil
            resumeProfilCard
        }
    }

    // MARK: — Approche de transformation (étape 6)

    private var approcheTransformationCard: some View {
        GlassCard {
            ApprochePreviewCard(
                poids:                  poidsActuel,
                taille:                 taille,
                age:                    dateNaissance.age,
                sexe:                   sexe,
                niveauActivite:         niveauActivite,
                silhouetteActuelle:     silhouetteActuelle,
                silhouetteObjectif:     silhouetteObjectif,
                dateObjectif:           dateObjectif,
                approcheTransformation: $approcheTransformation
            )
        }
    }

    private func analyseMinicarte(label: String, value: String, icon: String, color: Color) -> some View {
        GlassCard(padding: Spacing.sm) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var faisabiliteView: some View {
        let niveau = evaluerFaisabilite()
        return GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: niveau.icon).font(.title2).foregroundStyle(niveau.couleur)
                    Text(niveau.label).font(.nutriHeadline).foregroundStyle(niveau.couleur)
                }

                switch niveau {
                case .realiste:
                    Text("Excellent ! Cet objectif est tout à fait atteignable. Votre profil global est favorable.")
                        .font(.nutriCaption).foregroundStyle(.secondary)

                case .ambitieux:
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Objectif ambitieux mais réalisable avec une rigueur sans faille.")
                            .font(.nutriCaption).foregroundStyle(.secondary)
                        if let alt = alternativeSuggeree(niveau: niveau) {
                            Text(alt).font(.nutriCaption).foregroundStyle(.orange)
                        }
                    }

                case .dangereux:
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("⚠️ Ce rythme présente des risques : carences, perte musculaire, blessures. Plusieurs facteurs de votre profil (stress, sommeil, régime) renforcent ce risque.")
                            .font(.nutriCaption).foregroundStyle(.red)
                        if let alt = alternativeSuggeree(niveau: niveau) {
                            Text(alt).font(.nutriCaption).foregroundStyle(.secondary)
                        }
                        Toggle(isOn: $objectifForce) {
                            Text("Je comprends les risques et je souhaite continuer")
                                .font(.nutriCaption).foregroundStyle(.secondary)
                        }
                        .tint(.red)
                    }
                }
            }
        }
    }

    private var resumeProfilCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Récapitulatif")
                    .font(.nutriHeadline)
                    .padding(.bottom, 4)

                resumeLigne("Profil", value: "\(prenom), \(dateNaissance.age) ans · \(poidsActuel.arrondi(1)) kg · \(taille.arrondi(0)) cm")

                if !silhouetteActuelle.isEmpty, let sA = SilhouetteObjectif(rawValue: silhouetteActuelle),
                   !silhouetteObjectif.isEmpty, let sO = SilhouetteObjectif(rawValue: silhouetteObjectif) {
                    let sexeEnum = Sexe(rawValue: sexe) ?? .homme
                    resumeLigne("Transformation", value: "\(sA.label(sexe: sexeEnum)) → \(sO.label(sexe: sexeEnum))")
                }

                let appr = ApprocheTransformation(rawValue: approcheTransformation) ?? .normale
                resumeLigne("Approche", value: "\(appr.emoji) \(appr.label) · \(appr.descriptionCourte)")
                resumeLigne("Sport", value: "\(NiveauSport(rawValue: niveauSport)?.label ?? niveauSport) · \(frequenceEntrainement)×/sem")
                resumeLigne("Alimentation", value: RegimeAlimentaire(rawValue: regimeAlimentaire)?.label ?? regimeAlimentaire)
                resumeLigne("Sommeil / Stress", value: "\(dureeSommeil.arrondi(1)) h · stress \(niveauStress)/5")
            }
        }
    }

    private func resumeLigne(_ label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.nutriCaption)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(.nutriCaption)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.vertical, 1)
    }

    // MARK: - Logique navigation

    private var labelBoutonSuivant: String {
        if etape == totalEtapes - 1 {
            return claudeAPIKey.isEmpty ? "Commencer !" : "Créer mon plan IA"
        }
        if etape == 1 { return "Passer" }
        return "Suivant"
    }

    private var boutonSuivantActif: Bool {
        switch etape {
        case 0: return !prenom.trimmingCharacters(in: .whitespaces).isEmpty && taille > 0 && poidsActuel > 0
        case 2: return !silhouetteActuelle.isEmpty && !silhouetteObjectif.isEmpty
        case 6:
            return evaluerFaisabilite() != .dangereux || objectifForce
        default: return true
        }
    }

    private func avancer() {
        if etape < totalEtapes - 1 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) { etape += 1 }
        } else {
            creerProfil()
        }
    }

    // MARK: - Faisabilité complète

    /// Analyse multifactorielle basée sur l'ensemble des données collectées.
    private func evaluerFaisabilite() -> NiveauFaisabilite {
        guard !silhouetteObjectif.isEmpty else { return .realiste }

        let indexActuel = SilhouetteObjectif(rawValue: silhouetteActuelle)?.index ?? 2
        let indexCible  = SilhouetteObjectif(rawValue: silhouetteObjectif)?.index ?? 2
        let distance    = abs(indexActuel - indexCible)

        if distance == 0 { return .realiste }

        // Déficit effectif selon l'approche choisie (remplace le brut kg/semaines)
        let appr        = ApprocheTransformation(rawValue: approcheTransformation) ?? .normale
        let kcalParJour = appr.deficitMaxKcal

        // Score de base — l'approche choisie détermine le niveau de risque
        var score: Double
        switch kcalParJour {
        case ..<301:  score = 0.0
        case ..<501:  score = 1.0
        case ..<701:  score = 2.0
        case ..<1001: score = 3.5
        default:      score = 5.5
        }

        // Modificateurs — sport
        switch niveauSport {
        case "expert":        score -= 0.6
        case "avance":        score -= 0.4
        case "intermediaire": score -= 0.2
        case "debutant":      score += 0.5
        default: break
        }

        // Modificateurs — lifestyle
        if qualiteSommeil <= 2  { score += 0.5 }
        if niveauStress >= 4    { score += 0.5 }
        switch alcool {
        case "souvent", "tres_souvent": score += 0.6
        case "modere":                  score += 0.2
        default: break
        }
        if tabac { score += 0.3 }

        // Modificateurs — régime (restrictif = moins flexible)
        if regimeAlimentaire == "vegan" || regimeAlimentaire == "crudivore" { score += 0.3 }

        // Modificateurs — IMC extrême
        let imc = taille > 0 ? NutritionCalculator.imc(poids: poidsActuel, taille: taille) : 22.0
        if imc > 35 || imc < 17 { score += 0.5 }

        if score <= 1.0 { return .realiste }
        if score <= 3.0 { return .ambitieux }
        return .dangereux
    }

    /// Données chiffrées pour l'affichage de l'analyse — tenant compte de l'approche choisie.
    private var analyseFaisabilite: (kgEstimes: Double, kcalParJour: Double, semainesMin: Int) {
        let indexActuel = SilhouetteObjectif(rawValue: silhouetteActuelle)?.index ?? 2
        let indexCible  = SilhouetteObjectif(rawValue: silhouetteObjectif)?.index ?? 2
        let kgEstimes   = Double(abs(indexActuel - indexCible)) * 4.5

        // Utilise NutritionCalculator avec l'approche courante
        let temp = UserProfile(prenom: "", sexe: sexe, taille: taille, niveauActivite: niveauActivite)
        temp.poidsActuel            = max(poidsActuel, 1)
        temp.silhouetteActuelle     = silhouetteActuelle
        temp.silhouetteObjectif     = silhouetteObjectif
        temp.dateObjectif           = dateObjectif
        temp.approcheTransformation = approcheTransformation
        let obj = NutritionCalculator.objectifsCaloriques(profil: temp)

        let kcalParJour = kgEstimes > 0 ? abs(obj.ajustement) : 0
        let perteSem    = max(0.1, obj.perteSemaineEstimee)
        let semainesMin = kgEstimes > 0 ? max(8, Int(ceil(kgEstimes / perteSem))) : 0
        return (kgEstimes, kcalParJour, semainesMin)
    }

    private func alternativeSuggeree(niveau: NiveauFaisabilite) -> String? {
        let analyse = analyseFaisabilite
        guard analyse.kgEstimes > 0 else { return nil }
        guard let dateSuggestion = Calendar.current.date(
            byAdding: .weekOfYear, value: analyse.semainesMin, to: Date()
        ) else { return nil }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "fr_FR")
        fmt.dateFormat = "MMMM yyyy"
        if niveau == .dangereux {
            return "Pour votre sécurité, nous suggérons de viser \(fmt.string(from: dateSuggestion)) (~\(analyse.semainesMin) semaines)."
        } else {
            return "Viser \(fmt.string(from: dateSuggestion)) donnera de meilleurs résultats durables."
        }
    }

    // MARK: - Création du profil

    private func creerProfil() {
        let profil = UserProfile(
            prenom: prenom,
            dateNaissance: dateNaissance,
            sexe: sexe,
            taille: taille,
            niveauActivite: niveauActivite
        )

        profil.poidsActuel    = poidsActuel
        profil.objectifPoids  = poidsActuel

        profil.silhouetteActuelle     = silhouetteActuelle
        profil.silhouetteObjectif     = silhouetteObjectif
        profil.dateObjectif           = dateObjectif
        profil.frequenceReevaluation  = frequenceReevaluation

        profil.mensurationTailleCm   = mensurationTaille
        profil.mensurationHanchesCm  = mensurationHanches
        profil.mensurationPoitrineCm = mensurationPoitrine
        profil.mensurationBrasDroitCm = mensurationBras
        profil.mensurationCuisseCm   = mensurationCuisse
        profil.masseGraisseuse       = masseGraisseuse

        profil.niveauSport                = niveauSport
        profil.equipementSport            = equipementSport
        profil.sportsAprecies             = sportsSelectionnes
        profil.frequenceEntrainementJours = frequenceEntrainement
        profil.dureeSeanceMinutes         = dureeSeance

        profil.regimeAlimentaire = regimeAlimentaire
        profil.allergies         = allergiesSelectionnees
        profil.nbRepasJour       = nbRepasJour
        profil.alimentsAimes     = alimentsAimes
        profil.alimentsDetestes  = alimentsDetestes

        profil.qualiteSommeil             = qualiteSommeil
        profil.dureeSommeilHeures         = dureeSommeil
        profil.niveauStress               = niveauStress
        profil.alcool                     = alcool
        profil.tabac                      = tabac
        profil.hydratationHabituelleLitres = hydratation

        profil.claudeAPIKey           = claudeAPIKey
        profil.approcheTransformation = approcheTransformation
        profil.onboardingV2Complete   = true

        let objectifs = NutritionCalculator.objectifsCaloriques(profil: profil)
        let macros = NutritionCalculator.macrosCiblesTransformation(
            calories:   objectifs.objectifTransformation,
            poidsKg:    poidsActuel,
            ajustement: objectifs.ajustement,
            approche:   profil.approcheEnum
        )
        profil.objectifCalorique = objectifs.objectifTransformation
        profil.objectifProteines = macros.proteines
        profil.objectifGlucides  = macros.glucides
        profil.objectifLipides   = macros.lipides

        modelContext.insert(profil)
        activeProfileID = profil.profileID.uuidString

        if poidsActuel > 0 {
            let imc = NutritionCalculator.imc(poids: poidsActuel, taille: taille)
            let metric = BodyMetric(
                date: Date(), weight: poidsActuel, bmi: imc,
                waist: mensurationTaille, hips: mensurationHanches,
                chest: mensurationPoitrine, armRight: mensurationBras,
                thigh: mensurationCuisse,
                bodyFatPercentage: masseGraisseuse
            )
            metric.profileID = profil.profileID.uuidString
            modelContext.insert(metric)
        }

        try? modelContext.save()
        onComplete()
    }

    // MARK: - Helpers UI

    private func starRow(label: String, value: Binding<Int>, color: Color) -> some View {
        HStack {
            Text(label).font(.nutriBody)
            Spacer()
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= value.wrappedValue ? "star.fill" : "star")
                        .foregroundStyle(i <= value.wrappedValue ? color : Color.secondary.opacity(0.3))
                        .font(.title3)
                        .onTapGesture { value.wrappedValue = i }
                }
            }
        }
    }
}

// MARK: - FlowTags

struct FlowTags: View {
    let items: [String]
    @Binding var selection: [String]
    var color: Color = .nutriGreen

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(items, id: \.self) { item in
                let selected = selection.contains(item)
                Button(action: {
                    if selected { selection.removeAll { $0 == item } }
                    else { selection.append(item) }
                }) {
                    Text(item)
                        .font(.nutriCaption)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 5)
                        .background(selected ? color.opacity(0.2) : Color.clear, in: Capsule())
                        .overlay(Capsule().stroke(selected ? color : Color.secondary.opacity(0.3)))
                        .foregroundStyle(selected ? color : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0; var rowWidth: CGFloat = 0; var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowWidth + size.width + (rowWidth > 0 ? spacing : 0) > width, rowWidth > 0 {
                height += rowHeight + spacing; rowWidth = 0; rowHeight = 0
            }
            rowWidth += size.width + (rowWidth > 0 ? spacing : 0)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: height + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing; x = bounds.minX; rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: [UserProfile.self, BodyMetric.self], inMemory: true)
        .frame(width: 520, height: 760)
}
