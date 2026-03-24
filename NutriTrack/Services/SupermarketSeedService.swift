import SwiftData
import Foundation

/// Récupère les produits populaires de Lidl, Carrefour et Auchan
/// via Open Food Facts et les insère en cache SwiftData au premier lancement.
struct SupermarketSeedService {

    private let stores = ["Lidl", "Carrefour", "Auchan"]
    private let pageSize = 50

    // MARK: - Point d'entrée

    @MainActor
    func fetchAndSeed(context: ModelContext) async {
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate { $0.source == "OpenFoodFacts-FR" }
        )
        let existants = (try? context.fetchCount(descriptor)) ?? 0
        guard existants < 50 else {
            print("✅ SupermarketSeed: déjà seedé (\(existants) produits)")
            return
        }

        print("🔄 SupermarketSeed: récupération des produits français...")
        var total = 0

        for store in stores {
            let produits = await fetchStore(store)
            for p in produits {
                let barcode = p.barcode
                let dup = FetchDescriptor<FoodItem>(
                    predicate: #Predicate { $0.barcode == barcode }
                )
                if (try? context.fetchCount(dup)) ?? 0 > 0 { continue }

                let item = FoodItem(
                    barcode:       p.barcode,
                    name:          p.name,
                    brand:         p.brand,
                    calories:      p.calories,
                    proteins:      p.proteins,
                    carbohydrates: p.carbohydrates,
                    fats:          p.fats,
                    fiber:         p.fiber,
                    sugar:         p.sugar,
                    sodium:        p.sodium,
                    servingSize:   p.servingSize,
                    servingUnit:   p.servingUnit,
                    imageURL:      p.imageURL,
                    source:        "OpenFoodFacts-FR"
                )
                context.insert(item)
                total += 1
            }
            try? context.save()
            print("  ✅ \(store): \(produits.count) produits")
            // Pause pour ne pas saturer l'API
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        print("✅ SupermarketSeed terminé: \(total) produits insérés")
    }

    // MARK: - Fetch Open Food Facts par magasin

    private func fetchStore(_ store: String) async -> [ProduitParse] {
        let storeName = store.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? store
        let urlStr = "https://fr.openfoodfacts.org/cgi/search.pl" +
            "?tagtype_0=stores&tag_contains_0=contains&tag_0=\(storeName)" +
            "&tagtype_1=countries&tag_contains_1=contains&tag_1=fr" +
            "&json=1&page_size=\(pageSize)&page=1" +
            "&fields=code,product_name,brands,nutriments,serving_size,image_url,stores"

        guard let url = URL(string: urlStr) else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return parseResponse(data: data)
        } catch {
            print("⚠️ Erreur fetch \(store): \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Parsing

    private struct ProduitParse {
        let barcode: String
        let name: String
        let brand: String
        let calories: Double
        let proteins: Double
        let carbohydrates: Double
        let fats: Double
        let fiber: Double
        let sugar: Double
        let sodium: Double
        let servingSize: Double
        let servingUnit: String
        let imageURL: String
    }

    private func parseResponse(data: Data) -> [ProduitParse] {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let products = json["products"] as? [[String: Any]]
        else { return [] }

        return products.compactMap { parseProduct($0) }
    }

    private func parseProduct(_ p: [String: Any]) -> ProduitParse? {
        guard
            let code = p["code"] as? String, !code.isEmpty,
            let name = p["product_name"] as? String, !name.isEmpty
        else { return nil }

        let nutriments = p["nutriments"] as? [String: Any] ?? [:]

        let calories = nutriments["energy-kcal_100g"] as? Double
            ?? (nutriments["energy_100g"] as? Double).map { $0 / 4.184 }
            ?? 0

        guard calories > 0 else { return nil }

        let sodium = (nutriments["sodium_100g"] as? Double ?? 0)
        let brand = p["brands"] as? String ?? ""
        let brandPropre = brand.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? brand

        let servingStr = p["serving_size"] as? String ?? "100 g"
        let (servingSize, servingUnit) = parseServing(servingStr)

        return ProduitParse(
            barcode:        code,
            name:           name.trimmingCharacters(in: .whitespaces),
            brand:          brandPropre,
            calories:       calories,
            proteins:       nutriments["proteins_100g"] as? Double ?? 0,
            carbohydrates:  nutriments["carbohydrates_100g"] as? Double ?? 0,
            fats:           nutriments["fat_100g"] as? Double ?? 0,
            fiber:          nutriments["fiber_100g"] as? Double ?? 0,
            sugar:          nutriments["sugars_100g"] as? Double ?? 0,
            sodium:         sodium,
            servingSize:    servingSize,
            servingUnit:    servingUnit,
            imageURL:       p["image_url"] as? String ?? ""
        )
    }

    private func parseServing(_ str: String) -> (Double, String) {
        let cleaned = str.lowercased().trimmingCharacters(in: .whitespaces)
        let parts = cleaned.components(separatedBy: CharacterSet(charactersIn: " \t"))
        if let first = parts.first, let val = Double(first.replacingOccurrences(of: ",", with: ".")) {
            let unit = parts.dropFirst().first ?? "g"
            return (val, unit.contains("ml") ? "ml" : "g")
        }
        return (100, "g")
    }
}
