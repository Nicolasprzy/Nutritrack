import Foundation
import SwiftData

// MARK: - Modèles de décodage Open Food Facts

private struct OFFSearchResponse: Decodable {
    let products: [OFFProduct]
}

private struct OFFProductResponse: Decodable {
    let product: OFFProduct?
    let status: Int
}

private struct OFFProduct: Decodable {
    let product_name: String?
    let brands: String?
    let code: String?
    let nutriments: OFFNutriments?
    let serving_size: String?
    let image_url: String?
    let image_front_url: String?

    var imageURLResolu: String {
        image_front_url ?? image_url ?? ""
    }
}

private struct OFFNutriments: Decodable {
    let energy_kcal_100g: Double?
    let proteins_100g: Double?
    let carbohydrates_100g: Double?
    let fat_100g: Double?
    let fiber_100g: Double?
    let sugars_100g: Double?
    let sodium_100g: Double?

    enum CodingKeys: String, CodingKey {
        case energy_kcal_100g    = "energy-kcal_100g"
        case proteins_100g       = "proteins_100g"
        case carbohydrates_100g  = "carbohydrates_100g"
        case fat_100g            = "fat_100g"
        case fiber_100g          = "fiber_100g"
        case sugars_100g         = "sugars_100g"
        case sodium_100g         = "sodium_100g"
    }
}

// MARK: - Service

@Observable
class OpenFoodFactsService {

    var isLoading = false
    var errorMessage: String?

    private let session = URLSession.shared
    private let cacheTTL: TimeInterval = 7 * 24 * 3600  // 7 jours

    // MARK: - Normalisation (accents, casse)

    /// Normalise une chaîne pour la comparaison : minuscules + sans accents
    func normaliser(_ s: String) -> String {
        s.lowercased()
         .folding(options: .diacriticInsensitive, locale: .current)
    }

    // MARK: - Recherche locale avec scoring

    /// Recherche instantanée dans le cache local avec scoring de pertinence.
    /// Accessible depuis la vue pour un affichage immédiat (0 ms).
    func rechercherDansCache(query: String, context: ModelContext) -> [FoodItem] {
        let q = normaliser(query.trimmingCharacters(in: .whitespaces))
        guard !q.isEmpty else { return [] }

        // Tokens individuels (ex: "poulet cuit" → ["poulet", "cuit"])
        let tokens = q.split(separator: " ").map(String.init).filter { $0.count >= 2 }

        let descriptor = FetchDescriptor<FoodItem>()
        guard let tous = try? context.fetch(descriptor) else { return [] }

        // Score de pertinence pour chaque aliment
        let notes = tous.compactMap { item -> (FoodItem, Int)? in
            let score = pertinence(item: item, query: q, tokens: tokens)
            return score > 0 ? (item, score) : nil
        }

        // Tri : score décroissant, puis Seed en priorité, puis alpha
        return notes
            .sorted { a, b in
                if a.1 != b.1 { return a.1 > b.1 }
                let pA = a.0.source == "Seed"
                let pB = b.0.source == "Seed"
                if pA != pB { return pA }
                return a.0.name < b.0.name
            }
            .map(\.0)
    }

    /// Score de pertinence : plus c'est haut, plus c'est en tête de liste
    private func pertinence(item: FoodItem, query: String, tokens: [String]) -> Int {
        let nom   = normaliser(item.name)
        let brand = normaliser(item.brand)

        // Correspondance exacte
        if nom == query                          { return 100 }
        // Commence exactement par la requête
        if nom.hasPrefix(query)                  { return 80 }
        // Contient la requête complète
        if nom.contains(query)                   { return 60 }
        // La marque contient la requête complète
        if brand.contains(query)                 { return 45 }

        // Matching par tokens : tous les mots trouvés
        if !tokens.isEmpty {
            let matchesNom   = tokens.filter { nom.contains($0) }.count
            let matchesBrand = tokens.filter { brand.contains($0) }.count
            let totalMatches = matchesNom + matchesBrand

            if matchesNom == tokens.count        { return 40 }   // tous les tokens dans le nom
            if totalMatches == tokens.count      { return 35 }   // tous les tokens (nom+marque)
            if totalMatches > 0                  { return 10 + totalMatches * 5 } // partiel
        }
        return 0
    }

    // MARK: - Recherche réseau (avec résultats locaux en fallback)

    func rechercher(query: String, context: ModelContext) async -> [FoodItem] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }

        // Résultats locaux déjà affichés par la vue — on les ré-inclut pour fusion finale
        let caches = rechercherDansCache(query: q, context: context)

        // URL sans restriction de pays (cc=fr) pour plus de résultats
        // lc=fr conservé : étiquettes en français quand disponibles
        let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
        let urlString = "\(APIConstants.openFoodFactsSearch)?search_terms=\(encoded)&json=1&page_size=30&lc=fr&fields=product_name,brands,code,nutriments,serving_size,image_front_url,image_url&action=process&sort_by=unique_scans_n"

        guard let url = URL(string: urlString) else { return caches }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Vérification d'annulation avant l'appel réseau
            try Task.checkCancellation()

            let (data, _) = try await session.data(from: url)

            try Task.checkCancellation()

            let response = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
            let apiItems = response.products.compactMap { convertirEnFoodItem($0) }

            for item in apiItems { mettreEnCache(item: item, context: context) }

            // Fusion : cache d'abord (déjà scoré), puis items API non encore en cache
            var vus = Set(caches.map { $0.barcode })
            var resultats = caches
            for item in apiItems {
                if !item.barcode.isEmpty && !vus.contains(item.barcode) {
                    resultats.append(item)
                    vus.insert(item.barcode)
                } else if item.barcode.isEmpty {
                    // Item sans barcode : dédup par nom normalisé
                    let nomNorm = normaliser(item.name)
                    if !resultats.contains(where: { normaliser($0.name) == nomNorm }) {
                        resultats.append(item)
                    }
                }
            }
            return resultats
        } catch is CancellationError {
            return caches  // tâche annulée proprement
        } catch {
            errorMessage = "Réseau indisponible — résultats locaux uniquement."
            return caches
        }
    }

    // MARK: - Recherche par code-barres

    func rechercherParCodeBarre(_ barcode: String, context: ModelContext) async -> FoodItem? {
        if let cached = rechercherParCodeBarreDansCache(barcode: barcode, context: context) {
            return cached
        }

        let urlString = "\(APIConstants.openFoodFactsProduct)/\(barcode).json"
        guard let url = URL(string: urlString) else { return nil }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(OFFProductResponse.self, from: data)

            guard response.status == 1, let product = response.product else {
                errorMessage = "Produit introuvable pour ce code-barres."
                return nil
            }

            let item = convertirEnFoodItem(product)
            if let item { mettreEnCache(item: item, context: context) }
            return item
        } catch {
            errorMessage = "Erreur réseau : veuillez vérifier votre connexion."
            return nil
        }
    }

    // MARK: - Cache SwiftData

    private func rechercherParCodeBarreDansCache(barcode: String, context: ModelContext) -> FoodItem? {
        let limite = Date().addingTimeInterval(-cacheTTL)
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate<FoodItem> {
                $0.barcode == barcode && $0.lastUpdated > limite
            }
        )
        return try? context.fetch(descriptor).first
    }

    private func mettreEnCache(item: FoodItem, context: ModelContext) {
        if !item.barcode.isEmpty {
            let barcode = item.barcode
            let descriptor = FetchDescriptor<FoodItem>(
                predicate: #Predicate<FoodItem> { $0.barcode == barcode }
            )
            if let existant = try? context.fetch(descriptor).first {
                existant.calories       = item.calories
                existant.proteins       = item.proteins
                existant.carbohydrates  = item.carbohydrates
                existant.fats           = item.fats
                existant.fiber          = item.fiber
                existant.sugar          = item.sugar
                existant.sodium         = item.sodium
                existant.lastUpdated    = Date()
                try? context.save()
                return
            }
        }
        context.insert(item)
        try? context.save()
    }

    // MARK: - Conversion OFFProduct → FoodItem

    private func convertirEnFoodItem(_ product: OFFProduct) -> FoodItem? {
        guard let name = product.product_name, !name.isEmpty else { return nil }
        guard let nutriments = product.nutriments else { return nil }
        guard (nutriments.energy_kcal_100g ?? 0) > 0 else { return nil } // ignorer produits sans calories

        return FoodItem(
            barcode:        product.code ?? "",
            name:           name,
            brand:          product.brands ?? "",
            calories:       nutriments.energy_kcal_100g ?? 0,
            proteins:       nutriments.proteins_100g ?? 0,
            carbohydrates:  nutriments.carbohydrates_100g ?? 0,
            fats:           nutriments.fat_100g ?? 0,
            fiber:          nutriments.fiber_100g ?? 0,
            sugar:          nutriments.sugars_100g ?? 0,
            sodium:         nutriments.sodium_100g ?? 0,
            imageURL:       product.imageURLResolu
        )
    }

    // MARK: - Récents

    func derniersAlimentsUtilises(context: ModelContext, limite: Int = 20) -> [FoodItem] {
        var descriptor = FetchDescriptor<FoodItem>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        descriptor.fetchLimit = limite
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Retourne les aliments marqués favoris, triés par date de dernière consommation.
    func alimentsFavoris(context: ModelContext) -> [FoodItem] {
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate<FoodItem> { $0.isFavorite == true },
            sortBy: [SortDescriptor(\.dateLastConsumed, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
