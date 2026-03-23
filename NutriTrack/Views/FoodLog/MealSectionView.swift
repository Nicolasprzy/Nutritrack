import SwiftUI
import SwiftData

struct MealSectionView: View {
    @Environment(\.modelContext) private var modelContext

    let mealType: MealType
    let entries: [FoodEntry]
    let dateSelectionnee: Date
    var onSuppression: (() -> Void)? = nil
    var onAjoute: (() -> Void)? = nil

    @State private var isExpanded: Bool = true
    @State private var showAddFood = false

    var totalCalories: Double {
        entries.reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        GlassCard(padding: 0, cornerRadius: Radius.lg) {
            VStack(spacing: 0) {
                // En-tête section (accordéon)
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: mealType.icon)
                            .foregroundStyle(mealType.couleur)
                            .frame(width: 24)

                        Text(mealType.label)
                            .font(.nutriHeadline)

                        Spacer()

                        if totalCalories > 0 {
                            Text("\(totalCalories.arrondi(0)) kcal")
                                .font(.nutriCaption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Spacing.md)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(mealType.label), \(totalCalories.arrondi(0)) kcal, \(isExpanded ? "replier" : "développer")")

                if isExpanded {
                    Divider().padding(.horizontal, Spacing.sm)

                    // Liste des entrées
                    if entries.isEmpty {
                        Button(action: { showAddFood = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(mealType.couleur)
                                Text("Ajouter un aliment")
                                    .font(.nutriBody)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(Spacing.md)
                        }
                        .buttonStyle(.plain)
                    } else {
                        ForEach(entries) { entry in
                            entryRow(entry)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.xs)
                        }

                        Divider().padding(.horizontal, Spacing.sm)

                        // Bouton ajouter
                        Button(action: { showAddFood = true }) {
                            Label("Ajouter", systemImage: "plus")
                                .font(.nutriCaption)
                                .foregroundStyle(mealType.couleur)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Ajouter un aliment à \(mealType.label)")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddFood) {
            AddFoodView(
                mealType: mealType.rawValue,
                dateSelectionnee: dateSelectionnee,
                onAjoute: onAjoute
            )
        }
    }

    // MARK: - Ligne aliment

    private func entryRow(_ entry: FoodEntry) -> some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.foodItem?.name ?? "Aliment inconnu")
                    .font(.nutriBody)
                    .lineLimit(1)
                Text("\(entry.quantity.arrondi(0)) g · P:\(entry.proteins.arrondi(0))g G:\(entry.carbohydrates.arrondi(0))g L:\(entry.fats.arrondi(0))g")
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(entry.calories.arrondi(0)) kcal")
                .font(.nutriBody)
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                supprimerEntry(entry)
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
        .accessibilityLabel("\(entry.foodItem?.name ?? "Aliment"), \(entry.quantity.arrondi(0)) grammes, \(entry.calories.arrondi(0)) calories")
    }

    private func supprimerEntry(_ entry: FoodEntry) {
        withAnimation {
            modelContext.delete(entry)
            try? modelContext.save()
            onSuppression?()
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodItem.self, FoodEntry.self, configurations: config)

    let item = FoodItem(name: "Poulet grillé", calories: 165, proteins: 31, carbohydrates: 0, fats: 3.6)
    let entry = FoodEntry(date: Date(), mealType: "dejeuner", quantity: 150, foodItem: item)
    entry.calculerMacros()
    container.mainContext.insert(item)
    container.mainContext.insert(entry)

    return ScrollView {
        VStack(spacing: 8) {
            MealSectionView(
                mealType: .dejeuner,
                entries: [entry],
                dateSelectionnee: Date()
            )
            MealSectionView(
                mealType: .petitDejeuner,
                entries: [],
                dateSelectionnee: Date()
            )
        }
        .padding()
    }
    .modelContainer(container)
}
