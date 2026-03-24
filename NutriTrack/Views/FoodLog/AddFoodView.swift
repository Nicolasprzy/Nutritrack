import SwiftUI
import SwiftData

struct AddFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mealType: String
    let dateSelectionnee: Date
    var onAjoute: (() -> Void)? = nil

    @State private var service = OpenFoodFactsService()
    @State private var recherche: String = ""
    @State private var resultats: [FoodItem] = []
    @State private var recents: [FoodItem] = []
    @State private var favoris: [FoodItem] = []
    @State private var ongletActif: Onglet = .favoris
    @State private var foodSelectionne: FoodItem? = nil
    @State private var showDetail = false
    @State private var showScanner = false
    @State private var codeScanne: String? = nil

    /// Tâche de recherche courante — annulée à chaque nouvelle frappe
    @State private var searchTask: Task<Void, Never>?
    /// Indique si les résultats affichés sont encore "locaux" (avant réponse API)
    @State private var resultatsLocauxSeulement = false

    enum Onglet: String, CaseIterable {
        case favoris   = "Favoris"
        case recents   = "Récents"
        case recherche = "Recherche"
        case scanner   = "Scanner"

        var icone: String {
            switch self {
            case .favoris:   return "star.fill"
            case .recherche: return "magnifyingglass"
            case .recents:   return "clock.fill"
            case .scanner:   return "barcode.viewfinder"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Onglet", selection: $ongletActif) {
                    ForEach(Onglet.allCases, id: \.self) { onglet in
                        Label(onglet.rawValue, systemImage: onglet.icone)
                            .tag(onglet)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)

                Divider()

                Group {
                    switch ongletActif {
                    case .favoris:   favorisView
                    case .recherche: rechercheView
                    case .recents:   recentsView
                    case .scanner:   scannerView
                    }
                }
            }
            .navigationTitle("Ajouter un aliment")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .sheet(isPresented: $showDetail) {
                if let item = foodSelectionne {
                    FoodDetailView(
                        foodItem: item,
                        mealType: mealType,
                        dateSelectionnee: dateSelectionnee,
                        onAjoute: {
                            favoris = service.alimentsFavoris(context: modelContext)
                            recents = service.derniersAlimentsUtilises(context: modelContext)
                            onAjoute?()
                            dismiss()
                        }
                    )
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 540, idealWidth: 600, maxWidth: 800, minHeight: 560)
        #endif
        .onAppear {
            recents  = service.derniersAlimentsUtilises(context: modelContext)
            favoris  = service.alimentsFavoris(context: modelContext)
        }
    }

    // MARK: - Onglet Recherche

    private var rechercheView: some View {
        VStack(spacing: 0) {

            // Barre de recherche
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Rechercher un aliment…", text: $recherche)
                    #if os(iOS)
                    .submitLabel(.search)
                    #endif
                    .onSubmit {
                        lancerRechercheDebounce(immediate: true)
                    }
                    .onChange(of: recherche) { _, nouveau in
                        lancerRechercheDebounce(immediate: false)
                    }

                if !recherche.isEmpty {
                    Button(action: {
                        recherche = ""
                        resultats = []
                        searchTask?.cancel()
                    }) {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Indicateur : spinner réseau OU coche locale
                if service.isLoading {
                    ProgressView().controlSize(.small)
                } else if resultatsLocauxSeulement && !resultats.isEmpty {
                    Image(systemName: "externaldrive.badge.checkmark")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .help("Résultats locaux — enrichissement réseau en cours")
                }
            }
            .padding(Spacing.sm)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.md))
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)

            // Barre de statut
            if !recherche.isEmpty {
                HStack {
                    if let erreur = service.errorMessage {
                        Label(erreur, systemImage: "wifi.slash")
                            .font(.caption2).foregroundStyle(.orange)
                    } else if !resultats.isEmpty {
                        Text("\(resultats.count) résultat\(resultats.count > 1 ? "s" : "")")
                            .font(.caption2).foregroundStyle(.secondary)
                        if resultatsLocauxSeulement {
                            Text("· recherche en ligne…").font(.caption2).foregroundStyle(.secondary.opacity(0.6))
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, 4)
            }

            // Résultats / état vide
            if resultats.isEmpty && !recherche.isEmpty && !service.isLoading {
                VStack(spacing: Spacing.md) {
                    ContentUnavailableView(
                        "Aucun résultat",
                        systemImage: "fork.knife.circle",
                        description: Text("Essayez un autre terme ou vérifiez l'orthographe.")
                    )
                    // Suggestions
                    VStack(alignment: .leading, spacing: 6) {
                        Text("💡 Astuces :")
                            .font(.nutriCaption).bold()
                        Text("• Utilisez des termes simples : « poulet » plutôt que « filet de poulet grillé »")
                        Text("• Sans accents ça marche aussi : « café » = « cafe »")
                        Text("• Scannez le code-barres du produit pour un résultat exact")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(Spacing.md)
                    .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: Radius.md))
                    .padding(.horizontal, Spacing.md)
                }
                .padding(.top, Spacing.lg)
            } else {
                listeAliments(resultats)
            }
        }
    }

    // MARK: - Onglet Favoris

    private var favorisView: some View {
        Group {
            if favoris.isEmpty {
                ContentUnavailableView(
                    "Aucun favori",
                    systemImage: "star",
                    description: Text("Les aliments que vous consommez sont automatiquement ajoutés ici.")
                )
                .padding(.top, Spacing.xl)
            } else {
                listeAliments(favoris)
            }
        }
    }

    // MARK: - Onglet Récents

    private var recentsView: some View {
        Group {
            if recents.isEmpty {
                ContentUnavailableView(
                    "Aucun aliment récent",
                    systemImage: "clock",
                    description: Text("Les aliments que vous ajoutez apparaîtront ici.")
                )
                .padding(.top, Spacing.xl)
            } else {
                listeAliments(recents)
            }
        }
    }

    // MARK: - Onglet Scanner

    private var scannerView: some View {
        VStack(spacing: Spacing.lg) {
            if service.isLoading {
                VStack(spacing: Spacing.md) {
                    ProgressView()
                    Text("Recherche du produit…")
                        .font(.nutriBody).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Button(action: { showScanner = true }) {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.nutriGreen)
                        Text("Scanner un code-barres").font(.nutriTitle2)
                        Text("Ou saisissez le code manuellement")
                            .font(.nutriCaption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.xl)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showScanner) {
            BarcodeScannerView(
                codeScanne: $codeScanne,
                isPresented: $showScanner
            ) { code in
                Task { await rechercherParCode(code) }
            }
        }
    }

    // MARK: - Liste commune

    private func listeAliments(_ items: [FoodItem]) -> some View {
        List(items) { item in
            Button(action: {
                foodSelectionne = item
                showDetail = true
            }) {
                ligneAliment(item)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(item.name), \(item.calories.arrondi(0)) kcal pour 100g")
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button {
                    item.isFavorite.toggle()
                    if !item.isFavorite {
                        favoris = favoris.filter { $0.persistentModelID != item.persistentModelID }
                    }
                    try? modelContext.save()
                } label: {
                    Label(item.isFavorite ? "Retirer" : "Favori",
                          systemImage: item.isFavorite ? "star.slash" : "star.fill")
                }
                .tint(item.isFavorite ? .gray : .yellow)
            }
        }
        .listStyle(.plain)
    }

    private func ligneAliment(_ item: FoodItem) -> some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(Color.nutriGreen.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: categorieIcone(item))
                    .foregroundStyle(Color.nutriGreen)
            }

            VStack(alignment: .leading, spacing: 2) {
                // Mise en évidence du terme recherché dans le nom
                Text(item.name)
                    .font(.nutriHeadline)
                    .lineLimit(1)
                if !item.brand.isEmpty {
                    Text(item.brand)
                        .font(.nutriCaption).foregroundStyle(.secondary)
                }
                Text("\(item.calories.arrondi(0)) kcal · P:\(item.proteins.arrondi(0))g · G:\(item.carbohydrates.arrondi(0))g · L:\(item.fats.arrondi(0))g")
                    .font(.caption2).foregroundStyle(.secondary)
            }

            Spacer()

            if item.isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption2).foregroundStyle(.yellow)
            }
            Image(systemName: "chevron.right")
                .font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.vertical, Spacing.xs)
    }

    /// Icône contextuelle selon le nom de l'aliment
    private func categorieIcone(_ item: FoodItem) -> String {
        let n = item.name.lowercased()
        if n.contains("poulet") || n.contains("bœuf") || n.contains("porc") ||
           n.contains("viande") || n.contains("steak") || n.contains("saumon") ||
           n.contains("thon") || n.contains("poisson") { return "fork.knife" }
        if n.contains("lait") || n.contains("yaourt") || n.contains("fromage") ||
           n.contains("beurre") || n.contains("crème") { return "cup.and.saucer.fill" }
        if n.contains("pomme") || n.contains("banane") || n.contains("fraise") ||
           n.contains("fruit") || n.contains("orange") { return "apple.logo" }
        if n.contains("riz") || n.contains("pâte") || n.contains("pain") ||
           n.contains("farine") || n.contains("céréale") { return "takeoutbag.and.cup.and.straw.fill" }
        if n.contains("œuf") || n.contains("oeuf") { return "circle.fill" }
        return "leaf.fill"
    }

    // MARK: - Logique de recherche avec debounce

    /// Lance la recherche avec :
    /// 1. Résultats locaux immédiats (0 ms)
    /// 2. Appel API après 350 ms (annulé si nouvelle frappe)
    private func lancerRechercheDebounce(immediate: Bool) {
        let q = recherche.trimmingCharacters(in: .whitespaces)

        // Réinitialiser si champ vide
        guard q.count >= 2 else {
            resultats = []
            resultatsLocauxSeulement = false
            searchTask?.cancel()
            return
        }

        // Annuler la tâche précédente
        searchTask?.cancel()

        searchTask = Task {
            // ── Phase 1 : résultats locaux instantanés ──────────────────
            let locaux = service.rechercherDansCache(query: q, context: modelContext)
            if !Task.isCancelled {
                resultats = locaux
                resultatsLocauxSeulement = true
            }

            // ── Debounce ─────────────────────────────────────────────────
            let delai: UInt64 = immediate ? 0 : 350_000_000  // 350 ms
            if delai > 0 {
                try? await Task.sleep(nanoseconds: delai)
            }
            guard !Task.isCancelled else { return }

            // ── Phase 2 : enrichissement réseau ──────────────────────────
            let complets = await service.rechercher(query: q, context: modelContext)
            if !Task.isCancelled {
                resultats = complets
                resultatsLocauxSeulement = false
            }
        }
    }

    private func rechercherParCode(_ code: String) async {
        if let item = await service.rechercherParCodeBarre(code, context: modelContext) {
            foodSelectionne = item
            showDetail = true
        } else {
            service.errorMessage = "Produit non trouvé pour ce code-barres."
        }
    }
}

#Preview {
    AddFoodView(mealType: "dejeuner", dateSelectionnee: Date())
        .modelContainer(for: [FoodItem.self, FoodEntry.self, UserProfile.self], inMemory: true)
}
