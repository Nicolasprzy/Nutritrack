import SwiftUI

struct PlanNutritionCompletSheet: View {
    let plan: UserPlan
    let profil: UserProfile?
    @Environment(\.dismiss) private var dismiss

    // Valeurs calculées dynamiquement selon l'approche actuelle
    private var objCalc: (cal: Double, prot: Double, gluc: Double, lip: Double)? {
        guard let p = profil else { return nil }
        let obj = NutritionCalculator.objectifsCaloriques(profil: p)
        let mac = NutritionCalculator.macrosCiblesTransformation(
            calories:   obj.objectifTransformation,
            poidsKg:    p.poidsActuel,
            ajustement: obj.ajustement,
            approche:   p.approcheEnum
        )
        return (obj.objectifTransformation, mac.proteines, mac.glucides, mac.lipides)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {

                    // Note si l'approche a changé depuis la génération
                    if let p = profil {
                        let approche = p.approcheEnum
                        GlassCard {
                            HStack(spacing: 8) {
                                Text(approche.emoji)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Approche actuelle : \(approche.label)")
                                        .font(.nutriHeadline).foregroundStyle(approche.couleur)
                                    Text("Les objectifs ci-dessous reflètent votre approche actuelle. Les suggestions alimentaires proviennent du plan généré.")
                                        .font(.system(size: 10)).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    if let nutrition = plan.planNutrition {

                        // Objectifs macros — valeurs calculées si profil disponible, sinon plan stocké
                        let cal  = objCalc?.cal  ?? nutrition.caloriesJournalieres
                        let prot = objCalc?.prot ?? nutrition.proteinesG
                        let gluc = objCalc?.gluc ?? nutrition.glucidesG
                        let lip  = objCalc?.lip  ?? nutrition.lipidesG

                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                Label("Objectifs journaliers", systemImage: "chart.pie.fill")
                                    .font(.nutriHeadline).foregroundStyle(.orange)

                                HStack(spacing: 0) {
                                    macroBlock(label: "Calories",  valeur: cal.arrondi(0),  unite: "kcal", couleur: .orange)
                                    Divider().frame(height: 50)
                                    macroBlock(label: "Protéines", valeur: prot.arrondi(0), unite: "g",    couleur: .proteineColor)
                                    Divider().frame(height: 50)
                                    macroBlock(label: "Glucides",  valeur: gluc.arrondi(0), unite: "g",    couleur: .glucideColor)
                                    Divider().frame(height: 50)
                                    macroBlock(label: "Lipides",   valeur: lip.arrondi(0),  unite: "g",    couleur: .lipideColor)
                                }
                            }
                        }

                        // Répartition par repas — calories ajustées proportionnellement
                        let ratio = nutrition.caloriesJournalieres > 0
                            ? cal / nutrition.caloriesJournalieres
                            : 1.0

                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Label("Répartition des repas", systemImage: "clock.fill")
                                    .font(.nutriHeadline).foregroundStyle(.orange)

                                ForEach(nutrition.repasTypes) { repas in
                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        HStack {
                                            Text(repas.nom).font(.nutriBody)
                                            Spacer()
                                            Text("\((repas.caloriesCibles * ratio).arrondi(0)) kcal")
                                                .font(.nutriCaption)
                                                .foregroundStyle(.orange)
                                        }
                                        ForEach(repas.suggestions, id: \.self) { suggestion in
                                            HStack(alignment: .top, spacing: 6) {
                                                Text("→").font(.nutriCaption).foregroundStyle(.secondary)
                                                Text(suggestion).font(.nutriCaption).foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    if repas.id != nutrition.repasTypes.last?.id { Divider() }
                                }
                            }
                        }

                        // Conseils nutrition
                        if !nutrition.recommandations.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Label("Conseils nutritionnels", systemImage: "lightbulb.fill")
                                        .font(.nutriHeadline).foregroundStyle(.orange)
                                    ForEach(nutrition.recommandations, id: \.self) { conseil in
                                        HStack(alignment: .top, spacing: 6) {
                                            Text("•").foregroundStyle(.orange)
                                            Text(conseil).font(.nutriCaption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Recommandations vie
                    if !plan.recommandationsVie.isEmpty {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Label("Habitudes de vie", systemImage: "moon.stars.fill")
                                    .font(.nutriHeadline).foregroundStyle(.indigo)
                                Text(plan.recommandationsVie)
                                    .font(.nutriCaption).foregroundStyle(.secondary)
                            }
                        }
                    }

                    Text("Plan généré le \(plan.dateCreation.formatMedium)")
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                        .padding(.bottom, Spacing.md)
                }
                .padding(Spacing.md)
            }
            .navigationTitle("Mon plan nutritionnel")
            .background(Color.fondPrincipal)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 580)
        #endif
    }

    private func macroBlock(label: String, valeur: String, unite: String, couleur: Color) -> some View {
        VStack(spacing: 3) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(valeur).font(.nutriTitle2).foregroundStyle(couleur)
                Text(unite).font(.nutriCaption).foregroundStyle(.secondary)
            }
            Text(label).font(.nutriCaption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
