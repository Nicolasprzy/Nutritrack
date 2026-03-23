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

    // MARK: - Recherche par texte

    func rechercher(query: String, context: ModelContext) async -> [FoodItem] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        // 1. Chercher d'abord dans le cache SwiftData
        let caches = rechercherDansCache(query: query, context: context)
        if !caches.isEmpty {
            return caches
        }

        // 2. Appel réseau
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(APIConstants.openFoodFactsSearch)?search_terms=\(encoded)&json=1&page_size=20&lc=fr&fields=product_name,brands,code,nutriments,serving_size,image_front_url,image_url"

        guard let url = URL(string: urlString) else { return [] }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
            let items = response.products.compactMap { convertirEnFoodItem($0) }

            // Sauvegarder dans le cache
            for item in items {
                mettreEnCache(item: item, context: context)
            }

            return items
        } catch {
            errorMessage = "Erreur lors de la recherche : \(error.localizedDescription)"
            return []
        }
    }

    // MARK: - Recherche par code-barres

    func rechercherParCodeBarre(_ barcode: String, context: ModelContext) async -> FoodItem? {
        // Vérifier le cache d'abord
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
            if let item = item {
                mettreEnCache(item: item, context: context)
            }
            return item
        } catch {
            errorMessage = "Erreur réseau : veuillez vérifier votre connexion."
            return nil
        }
    }

    // MARK: - Cache SwiftData

    private func rechercherDansCache(query: String, context: ModelContext) -> [FoodItem] {
        let termeRecherche = query.lowercased()
        let limite = Date().addingTimeInterval(-cacheTTL)

        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate<FoodItem> {
                $0.lastUpdated > limite
            }
        )

        guard let tous = try? context.fetch(descriptor) else { return [] }
        return tous.filter {
            $0.name.lowercased().contains(termeRecherche) ||
            $0.brand.lowercased().contains(termeRecherche)
        }
    }

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
        // Vérifier si l'aliment existe déjà (par code-barres ou nom+marque)
        if !item.barcode.isEmpty {
            let barcode = item.barcode
            let descriptor = FetchDescriptor<FoodItem>(
                predicate: #Predicate<FoodItem> { $0.barcode == barcode }
            )
            if let existant = try? context.fetch(descriptor).first {
                // Mettre à jour
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

    // MARK: - Conversion

    private func convertirEnFoodItem(_ product: OFFProduct) -> FoodItem? {
        guard let name = product.product_name, !name.isEmpty else { return nil }
        guard let nutriments = product.nutriments else { return nil }

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

    // MARK: - Récents (derniers aliments utilisés)

    func derniersAlimentsUtilises(context: ModelContext, limite: Int = 20) -> [FoodItem] {
        var descriptor = FetchDescriptor<FoodItem>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        descriptor.fetchLimit = limite
        return (try? context.fetch(descriptor)) ?? []
    }
}
