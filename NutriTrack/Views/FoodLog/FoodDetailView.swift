import SwiftUI
import SwiftData

struct FoodDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    let foodItem: FoodItem
    let mealType: String
    let dateSelectionnee: Date
    var onAjoute: (() -> Void)? = nil

    @State private var quantite: Double = 100.0
    @State private var uniteSelectionnee: String = "g"
    @State private var viewModel = FoodLogViewModel()

    private let unites = ["g", "ml", "portion"]

    private var macrosPourQuantite: (cal: Double, prot: Double, gluc: Double, lip: Double) {
        let ratio = quantite / 100.0
        return (
            cal:  foodItem.calories      * ratio,
            prot: foodItem.proteins      * ratio,
            gluc: foodItem.carbohydrates * ratio,
            lip:  foodItem.fats          * ratio
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    aliment_header
                    quantiteSection
                    nutritionSection
                    nutritionComplete
                }
                .padding(Spacing.md)
            }
            .navigationTitle("Ajouter au journal")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        ajouterAuJournal()
                    }
                    .bold()
                    .foregroundStyle(Color.nutriGreen)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, idealWidth: 500, maxWidth: 700, minHeight: 520)
        #endif
    }

    // MARK: - En-tête aliment

    private var aliment_header: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(foodItem.name)
                    .font(.nutriTitle2)
                if !foodItem.brand.isEmpty {
                    Text(foodItem.brand)
                        .font(.nutriBody)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text(MealType(rawValue: mealType)?.label ?? mealType)
                        .font(.nutriCaption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                    Text(dateSelectionnee.formatMedium)
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Saisie quantité

    private var quantiteSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Quantité", systemImage: "scalemass.fill")
                    .font(.nutriHeadline)

                HStack(spacing: Spacing.md) {
                    // Stepper
                    HStack {
                        Button(action: { quantite = max(1, quantite - 10) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)

                        TextField("Quantité", value: $quantite, format: .number)
                            .font(.nutriTitle2)
                            .multilineTextAlignment(.center)
                            .frame(width: 80)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif

                        Button(action: { quantite += 10 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.nutriGreen)
                        }
                        .buttonStyle(.plain)
                    }

                    // Unité
                    Picker("Unité", selection: $uniteSelectionnee) {
                        ForEach(unites, id: \.self) { unite in
                            Text(unite).tag(unite)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Slider
                Slider(value: $quantite, in: 1...500, step: 5)
                    .tint(.nutriGreen)
            }
        }
    }

    // MARK: - Résumé nutritionnel calculé

    private var nutritionSection: some View {
        let macros = macrosPourQuantite
        return GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Pour \(quantite.arrondi(0)) \(uniteSelectionnee)")
                    .font(.nutriHeadline)

                HStack(spacing: Spacing.lg) {
                    nutriChiffre(valeur: macros.cal.arrondi(0), label: "kcal", couleur: .orange)
                    nutriChiffre(valeur: macros.prot.arrondi(1), label: "Prot.", couleur: .proteineColor)
                    nutriChiffre(valeur: macros.gluc.arrondi(1), label: "Gluc.", couleur: .glucideColor)
                    nutriChiffre(valeur: macros.lip.arrondi(1), label: "Lip.", couleur: .lipideColor)
                }
                .animation(.easeInOut(duration: 0.2), value: quantite)
            }
        }
    }

    private func nutriChiffre(valeur: String, label: String, couleur: Color) -> some View {
        VStack(spacing: 2) {
            Text(valeur)
                .font(.nutriTitle2)
                .foregroundStyle(couleur)
                .monospacedDigit()
            Text(label)
                .font(.nutriCaption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Valeurs nutritionnelles complètes (pour 100g)

    private var nutritionComplete: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Pour 100 \(foodItem.servingUnit)")
                    .font(.nutriHeadline)
                    .foregroundStyle(.secondary)

                Divider()

                ligneNutrition(label: "Calories",    valeur: "\(foodItem.calories.arrondi(0)) kcal")
                ligneNutrition(label: "Protéines",   valeur: foodItem.proteins.grammes)
                ligneNutrition(label: "Glucides",    valeur: foodItem.carbohydrates.grammes)
                ligneNutrition(label: "dont sucres", valeur: foodItem.sugar.grammes, indent: true)
                ligneNutrition(label: "Lipides",     valeur: foodItem.fats.grammes)
                ligneNutrition(label: "Fibres",      valeur: foodItem.fiber.grammes)
                if foodItem.sodium > 0 {
                    ligneNutrition(label: "Sodium", valeur: "\(foodItem.sodium.arrondi(2)) g")
                }
            }
        }
    }

    private func ligneNutrition(label: String, valeur: String, indent: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.nutriBody)
                .foregroundStyle(indent ? .secondary : .primary)
                .padding(.leading, indent ? Spacing.md : 0)
            Spacer()
            Text(valeur)
                .font(.nutriBody)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    // MARK: - Actions

    private func ajouterAuJournal() {
        viewModel.ajouterEntree(
            foodItem: foodItem,
            quantite: quantite,
            mealType: mealType,
            context: modelContext
        )
        onAjoute?()
        dismiss()
    }
}

#Preview {
    let item = FoodItem(
        name: "Poulet grillé",
        brand: "Marque fraîche",
        calories: 165,
        proteins: 31,
        carbohydrates: 0,
        fats: 3.6
    )
    return FoodDetailView(
        foodItem: item,
        mealType: "dejeuner",
        dateSelectionnee: Date()
    )
    .modelContainer(for: [FoodItem.self, FoodEntry.self, UserProfile.self], inMemory: true)
}
