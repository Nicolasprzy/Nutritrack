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
    @State private var ongletActif: Onglet = .recherche
    @State private var foodSelectionne: FoodItem? = nil
    @State private var showDetail = false
    @State private var showScanner = false
    @State private var codeScanne: String? = nil

    enum Onglet: String, CaseIterable {
        case recherche = "Recherche"
        case recents   = "Récents"
        case scanner   = "Scanner"

        var icone: String {
            switch self {
            case .recherche: return "magnifyingglass"
            case .recents:   return "clock.fill"
            case .scanner:   return "barcode.viewfinder"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Sélecteur d'onglet
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
                    case .recherche:
                        rechercheView
                    case .recents:
                        recentsView
                    case .scanner:
                        scannerView
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
            recents = service.derniersAlimentsUtilises(context: modelContext)
        }
    }

    // MARK: - Onglet Recherche

    private var rechercheView: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Rechercher un aliment…", text: $recherche)
                    #if os(iOS)
                    .submitLabel(.search)
                    #endif
                    .onSubmit {
                        Task { await lancerRecherche() }
                    }

                if !recherche.isEmpty {
                    Button(action: {
                        recherche = ""
                        resultats = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                if service.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(Spacing.sm)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radius.md))
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
            .onChange(of: recherche) { _, nouveau in
                if nouveau.count >= 3 {
                    Task { await lancerRecherche() }
                }
            }

            if let erreur = service.errorMessage {
                Text(erreur)
                    .font(.nutriCaption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, Spacing.md)
            }

            if resultats.isEmpty && !recherche.isEmpty && !service.isLoading {
                ContentUnavailableView(
                    "Aucun résultat",
                    systemImage: "fork.knife.circle",
                    description: Text("Essayez un autre terme de recherche.")
                )
                .padding(.top, Spacing.xl)
            } else {
                listeAliments(resultats)
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
                        .font(.nutriBody)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Button(action: { showScanner = true }) {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.nutriGreen)
                        Text("Scanner un code-barres")
                            .font(.nutriTitle2)
                        Text("Ou saisissez le code manuellement")
                            .font(.nutriCaption)
                            .foregroundStyle(.secondary)
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
        }
        .listStyle(.plain)
    }

    private func ligneAliment(_ item: FoodItem) -> some View {
        HStack(spacing: Spacing.sm) {
            // Icône nutrition
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(Color.nutriGreen.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "leaf.fill")
                    .foregroundStyle(Color.nutriGreen)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.nutriHeadline)
                    .lineLimit(1)
                if !item.brand.isEmpty {
                    Text(item.brand)
                        .font(.nutriCaption)
                        .foregroundStyle(.secondary)
                }
                Text("\(item.calories.arrondi(0)) kcal · P:\(item.proteins.arrondi(0))g · G:\(item.carbohydrates.arrondi(0))g · L:\(item.fats.arrondi(0))g")
                    .font(.nutriCaption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Actions réseau

    private func lancerRecherche() async {
        let results = await service.rechercher(query: recherche, context: modelContext)
        resultats = results
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
