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
    @State private var entryADeplacer: FoodEntry? = nil
    @State private var entrySelectionnee: FoodEntry? = nil

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
        .sheet(item: $entryADeplacer) { entry in
            DeplacerAlimentSheet(entry: entry, onDeplace: {
                entryADeplacer = nil
                onSuppression?()
            })
        }
        .sheet(item: $entrySelectionnee) { entry in
            EntryQuickActionSheet(entry: entry,
                onModifie: { onSuppression?() },
                onSupprime: { onSuppression?() }
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
        .contentShape(Rectangle())
        .onTapGesture { entrySelectionnee = entry }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                supprimerEntry(entry)
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
            Button {
                entryADeplacer = entry
            } label: {
                Label("Déplacer", systemImage: "calendar.badge.plus")
            }
            .tint(.blue)
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

// MARK: - Sheet actions rapides

struct EntryQuickActionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: FoodEntry
    var onModifie: (() -> Void)? = nil
    var onSupprime: (() -> Void)? = nil

    @State private var quantite: Double
    @State private var showDeplacer = false

    init(entry: FoodEntry, onModifie: (() -> Void)? = nil, onSupprime: (() -> Void)? = nil) {
        self.entry = entry
        self.onModifie = onModifie
        self.onSupprime = onSupprime
        _quantite = State(initialValue: entry.quantity)
    }

    private var macrosCourantes: (cal: Double, prot: Double, gluc: Double, lip: Double) {
        guard let food = entry.foodItem else {
            return (entry.calories, entry.proteins, entry.carbohydrates, entry.fats)
        }
        let ratio = quantite / 100.0
        return (
            cal:  food.calories      * ratio,
            prot: food.proteins      * ratio,
            gluc: food.carbohydrates * ratio,
            lip:  food.fats          * ratio
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {

                    // En-tête aliment
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(entry.foodItem?.name ?? "Aliment inconnu")
                                .font(.nutriTitle2)
                            if let brand = entry.foodItem?.brand, !brand.isEmpty {
                                Text(brand)
                                    .font(.nutriBody).foregroundStyle(.secondary)
                            }
                            Text("\(entry.mealTypeEnum.label) · \(entry.date.formatMedium)")
                                .font(.nutriCaption).foregroundStyle(.secondary)
                        }
                    }

                    // Saisie quantité
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            NutriSectionHeader("Quantité", icon: "scalemass.fill")

                            NutriStepper(
                                title: "",
                                value: $quantite,
                                step: 10,
                                range: 1...500,
                                suffix: "g",
                                format: "%.0f"
                            )

                            Slider(value: $quantite, in: 1...500, step: 5).tint(.nutriGreen)

                            // Macros mises à jour dynamiquement
                            let m = macrosCourantes
                            HStack(spacing: 0) {
                                macroChip(val: m.cal.arrondi(0), label: "kcal", couleur: .orange)
                                macroChip(val: m.prot.arrondi(1), label: "Prot.", couleur: .proteineColor)
                                macroChip(val: m.gluc.arrondi(1), label: "Gluc.", couleur: .glucideColor)
                                macroChip(val: m.lip.arrondi(1), label: "Lip.", couleur: .lipideColor)
                            }
                            .animation(.easeInOut(duration: 0.15), value: quantite)
                        }
                    }

                    // Boutons d'action
                    VStack(spacing: Spacing.sm) {
                        NutriButton("Déplacer vers un autre repas/date",
                                    icon: "calendar.badge.plus",
                                    style: .secondary) {
                            showDeplacer = true
                        }

                        NutriButton("Supprimer cette entrée",
                                    icon: "trash",
                                    style: .destructive) {
                            modelContext.delete(entry)
                            try? modelContext.save()
                            onSupprime?()
                            dismiss()
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .navigationTitle("Modifier l'entrée")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    NutriButton("Annuler", style: .secondary, size: .small) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    NutriButton("Enregistrer",
                                style: .primary,
                                size: .small,
                                isDisabled: abs(quantite - entry.quantity) < 0.5) {
                        entry.quantity = quantite
                        entry.calculerMacros()
                        try? modelContext.save()
                        onModifie?()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showDeplacer) {
                DeplacerAlimentSheet(entry: entry, onDeplace: {
                    showDeplacer = false
                    onModifie?()
                    dismiss()
                })
            }
        }
        #if os(macOS)
        .frame(minWidth: NutriLayout.sheetCompactWidth,
               idealWidth: NutriLayout.sheetCompactWidth,
               maxWidth: NutriLayout.sheetStandardWidth,
               minHeight: NutriLayout.sheetCompactHeight)
        #endif
        #if os(iOS)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        #endif
    }

    private func macroChip(val: String, label: String, couleur: Color) -> some View {
        VStack(spacing: 2) {
            Text(val)
                .font(.nutriHeadline).foregroundStyle(couleur).monospacedDigit()
            Text(label)
                .font(.nutriCaption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sheet déplacement d'un aliment

struct DeplacerAlimentSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: FoodEntry
    var onDeplace: (() -> Void)? = nil

    @State private var nouvelleDate: Date
    @State private var nouveauRepas: MealType

    init(entry: FoodEntry, onDeplace: (() -> Void)? = nil) {
        self.entry = entry
        self.onDeplace = onDeplace
        _nouvelleDate  = State(initialValue: entry.date)
        _nouveauRepas  = State(initialValue: entry.mealTypeEnum)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // ── Aliment ──────────────────────────────────────────
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        NutriSectionHeader("Aliment", icon: "fork.knife")
                        Label(entry.foodItem?.name ?? "Aliment", systemImage: "fork.knife")
                            .font(.nutriBody)
                        Text("\(entry.quantity.arrondi(0)) g · \(entry.calories.arrondi(0)) kcal")
                            .font(.nutriCaption).foregroundStyle(.secondary)
                    }

                    // ── Nouvelle date ────────────────────────────────────
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        NutriSectionHeader("Nouvelle date", icon: "calendar")
                        NutriDatePicker(title: "", date: $nouvelleDate, style: .calendar)
                    }

                    // ── Repas ────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        NutriSectionHeader("Repas", icon: "takeoutbag.and.cup.and.straw.fill")
                        NutriPicker("Repas", selection: $nouveauRepas,
                                    options: MealType.allCases.map {
                                        NutriPickerOption($0, label: $0.label, icon: $0.icon)
                                    })
                    }
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("Déplacer l'aliment")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    NutriButton("Annuler", style: .secondary, size: .small) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    NutriButton("Déplacer", style: .primary, size: .small) {
                        entry.date     = nouvelleDate
                        entry.mealType = nouveauRepas.rawValue
                        try? modelContext.save()
                        onDeplace?()
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: NutriLayout.sheetCompactWidth,
               minHeight: NutriLayout.sheetStandardHeight)
        #endif
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
