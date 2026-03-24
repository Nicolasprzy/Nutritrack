import SwiftUI

/// Sélecteur d'approche de transformation + aperçu **réactif instantané** :
/// calories/jour, macros, rythme hebdomadaire, intensité sport, jalons de progression.
///
/// Tous les chiffres se mettent à jour dès qu'on change d'approche — aucun recalcul
/// manuel nécessaire. Peut être placé dans n'importe quelle vue (GlassCard, profileSection…).
struct ApprochePreviewCard: View {

    // Données profil nécessaires au calcul
    let poids: Double           // kg
    let taille: Double          // cm
    let age: Int
    let sexe: String
    let niveauActivite: String
    let silhouetteActuelle: String
    let silhouetteObjectif: String
    let dateObjectif: Date

    @Binding var approcheTransformation: String

    // MARK: - Calculs réactifs

    private var approche: ApprocheTransformation {
        ApprocheTransformation(rawValue: approcheTransformation) ?? .normale
    }

    /// Crée un profil temporaire (jamais inséré dans SwiftData) pour le calcul.
    private var calculPreview: (obj: NutritionCalculator.ObjectifsCaloriques,
                                 mac: NutritionCalculator.MacrosCibles) {
        let temp = UserProfile(
            prenom: "",
            dateNaissance: Calendar.current.date(byAdding: .year, value: -age, to: Date()) ?? Date(),
            sexe: sexe,
            taille: taille,
            niveauActivite: niveauActivite
        )
        temp.poidsActuel           = max(poids, 1)
        temp.silhouetteActuelle    = silhouetteActuelle
        temp.silhouetteObjectif    = silhouetteObjectif
        temp.dateObjectif          = dateObjectif
        temp.approcheTransformation = approcheTransformation

        let obj = NutritionCalculator.objectifsCaloriques(profil: temp)
        let mac = NutritionCalculator.macrosCiblesTransformation(
            calories:   obj.objectifTransformation,
            poidsKg:    max(poids, 1),
            ajustement: obj.ajustement,
            approche:   approche
        )
        return (obj, mac)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {

            // ── En-tête ──────────────────────────────────────────────────
            HStack(spacing: 6) {
                Image(systemName: "gauge.with.needle.fill")
                    .foregroundStyle(approche.couleur)
                Text("Intensité de transformation")
                    .font(.nutriHeadline).foregroundStyle(approche.couleur)
            }

            // ── Sélecteur 2 × 2 ─────────────────────────────────────────
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(ApprocheTransformation.allCases, id: \.self) { a in
                    approcheBouton(a)
                }
            }

            Divider()

            // ── Contenu réactif ──────────────────────────────────────────
            let (obj, mac) = calculPreview

            if !silhouetteObjectif.isEmpty {
                caloriesRow(obj: obj)
                macrosRow(obj: obj, mac: mac)
                Divider()
                rythmeRow(obj: obj)
                if !obj.jalons.isEmpty {
                    Divider()
                    jalonsSection(jalons: obj.jalons)
                }
            } else {
                descriptionBlock
            }
        }
    }

    // MARK: - Sélecteur

    private func approcheBouton(_ a: ApprocheTransformation) -> some View {
        let selected = approcheTransformation == a.rawValue
        return Button {
            withAnimation(.spring(response: 0.25)) { approcheTransformation = a.rawValue }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: a.icone).font(.caption)
                Text(a.label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(selected ? a.couleur.opacity(0.15) : Color.clear,
                        in: RoundedRectangle(cornerRadius: Radius.sm))
            .overlay(RoundedRectangle(cornerRadius: Radius.sm)
                .stroke(selected ? a.couleur : Color.secondary.opacity(0.2), lineWidth: 1))
            .foregroundStyle(selected ? a.couleur : .secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Calories / delta

    private func caloriesRow(obj: NutritionCalculator.ObjectifsCaloriques) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            // Valeur principale
            Text("\(Int(obj.objectifTransformation))")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(approche.couleur)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.25), value: approcheTransformation)
            Text("kcal / jour")
                .font(.nutriCaption).foregroundStyle(.secondary)

            Spacer()

            // Badge delta
            if abs(obj.ajustement) > 10 {
                HStack(spacing: 4) {
                    Image(systemName: obj.iconeAjustement).font(.caption2)
                    Text("\(obj.estDeficit ? "−" : "+")\(Int(abs(obj.ajustement))) kcal/j")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(obj.couleurAjustement)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(obj.couleurAjustement.opacity(0.10), in: Capsule())
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.25), value: approcheTransformation)
            }
        }
    }

    // MARK: - Macros (3 blocs)

    private func macrosRow(obj: NutritionCalculator.ObjectifsCaloriques,
                           mac: NutritionCalculator.MacrosCibles) -> some View {
        let cal = max(1, obj.objectifTransformation)
        return HStack(spacing: 8) {
            macroBloc(label: "Protéines", g: mac.proteines,
                      pct: (mac.proteines * 4 / cal) * 100, couleur: .proteineColor)
            macroBloc(label: "Glucides",  g: mac.glucides,
                      pct: (mac.glucides  * 4 / cal) * 100, couleur: .glucideColor)
            macroBloc(label: "Lipides",   g: mac.lipides,
                      pct: (mac.lipides   * 9 / cal) * 100, couleur: .lipideColor)
        }
        .animation(.easeInOut(duration: 0.25), value: approcheTransformation)
    }

    private func macroBloc(label: String, g: Double, pct: Double, couleur: Color) -> some View {
        VStack(spacing: 3) {
            Text("\(Int(g)) g")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(couleur)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
            Text("\(Int(pct))%")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(couleur.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(couleur.opacity(0.08), in: RoundedRectangle(cornerRadius: Radius.sm))
    }

    // MARK: - Rythme + intensité sport

    private func rythmeRow(obj: NutritionCalculator.ObjectifsCaloriques) -> some View {
        HStack(spacing: Spacing.md) {

            // Perte / gain hebdo
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: obj.estDeficit
                          ? "chart.line.downtrend.xyaxis"
                          : "chart.line.uptrend.xyaxis")
                        .font(.caption2).foregroundStyle(approche.couleur)
                    Text(obj.perteSemaineEstimee > 0
                         ? (obj.estDeficit
                            ? "~\(String(format: "%.2f", obj.perteSemaineEstimee)) kg/sem."
                            : "+\(String(format: "%.2f", obj.perteSemaineEstimee)) kg/sem.")
                         : "Maintenance")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(approche.couleur)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.25), value: approcheTransformation)
                }
                Text(obj.estDeficit ? "perte estimée / sem." : "gain estimé / sem.")
                    .font(.system(size: 9)).foregroundStyle(.secondary)
            }

            Divider().frame(height: 30)

            // Séances recommandées
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.run")
                        .font(.caption2).foregroundStyle(approche.couleur)
                    Text(approche.seancesConseillees)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(approche.couleur)
                }
                Text("intensité \(approche.intensiteEntrainement.lowercased())")
                    .font(.system(size: 9)).foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Jalons de progression

    private func jalonsSection(jalons: [NutritionCalculator.JalonTransformation]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Jalons de progression estimés")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            ForEach(jalons) { jalon in
                HStack(spacing: 10) {
                    // Icône
                    ZStack {
                        Circle()
                            .fill(jalon.couleur.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: jalon.icone)
                            .font(.system(size: 11))
                            .foregroundStyle(jalon.couleur)
                    }
                    // Texte
                    VStack(alignment: .leading, spacing: 1) {
                        Text(jalon.titre)
                            .font(.system(size: 11, weight: .medium))
                        Text(jalon.detail)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    // Date estimée
                    Text(jalon.dateEstimee, format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(jalon.couleur)
                        .monospacedDigit()
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: approcheTransformation)
    }

    // MARK: - Description simple (pas de silhouette objectif)

    private var descriptionBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(approche.emoji).font(.title3)
                Text(approche.label).font(.nutriHeadline).foregroundStyle(approche.couleur)
                Spacer()
                Text(approche.descriptionCourte)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(approche.couleur)
            }
            Text(approche.descriptionLongue)
                .font(.nutriCaption).foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.caption2).foregroundStyle(approche.couleur)
                Text("~\(String(format: "%.2f", approche.perteSemaineKg)) kg/semaine")
                    .font(.system(size: 11)).foregroundStyle(approche.couleur)
            }
        }
        .padding(Spacing.sm)
        .background(approche.couleur.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: Radius.sm))
    }
}

// MARK: - Preview

#Preview {
    let profil = UserProfile(
        prenom: "Test", sexe: "homme", taille: 178, objectifPoids: 72, niveauActivite: "modere"
    )
    profil.poidsActuel = 85

    return ScrollView {
        GlassCard {
            ApprochePreviewCard(
                poids: 85, taille: 178, age: 30, sexe: "homme",
                niveauActivite: "modere",
                silhouetteActuelle: "surpoids", silhouetteObjectif: "normal",
                dateObjectif: Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date(),
                approcheTransformation: .constant("normale")
            )
        }
        .padding()
    }
    .background(Color.fondPrincipal)
    .frame(width: 520)
}
