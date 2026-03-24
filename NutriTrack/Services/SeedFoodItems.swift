import SwiftData
import Foundation

// MARK: - Base locale d'aliments courants français (~200 aliments)

struct SeedFoodItems {

    struct AlimentRef {
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
        let barcode: String
    }

    static func run(context: ModelContext) {
        // Vérifier si déjà seedé
        let descriptor = FetchDescriptor<FoodItem>(predicate: #Predicate { $0.source == "Seed" })
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for aliment in aliments {
            let item = FoodItem(
                barcode:       aliment.barcode,
                name:          aliment.name,
                brand:         aliment.brand,
                calories:      aliment.calories,
                proteins:      aliment.proteins,
                carbohydrates: aliment.carbohydrates,
                fats:          aliment.fats,
                fiber:         aliment.fiber,
                sugar:         aliment.sugar,
                sodium:        aliment.sodium,
                servingSize:   aliment.servingSize,
                servingUnit:   aliment.servingUnit,
                source:        "Seed"
            )
            context.insert(item)
        }
        try? context.save()
        print("✅ SeedFoodItems: \(aliments.count) aliments insérés")
    }

    // MARK: - Données (kcal, P, G, L, fibres, sucres, sodium pour 100g)

    static let aliments: [AlimentRef] = [

        // ── CÉRÉALES & FÉCULENTS ──────────────────────────────────────
        .init(name: "Pain de campagne",          brand: "",           calories: 260, proteins: 8.5,  carbohydrates: 50.0, fats: 1.5,  fiber: 3.5, sugar: 2.0,  sodium: 0.50, servingSize: 100, servingUnit: "g",  barcode: "seed_pain_campagne"),
        .init(name: "Pain complet",              brand: "",           calories: 245, proteins: 9.0,  carbohydrates: 44.0, fats: 2.5,  fiber: 6.0, sugar: 3.5,  sodium: 0.48, servingSize: 100, servingUnit: "g",  barcode: "seed_pain_complet"),
        .init(name: "Pain blanc (baguette)",     brand: "",           calories: 270, proteins: 8.0,  carbohydrates: 55.0, fats: 1.2,  fiber: 2.5, sugar: 3.0,  sodium: 0.52, servingSize: 100, servingUnit: "g",  barcode: "seed_baguette"),
        .init(name: "Pain de mie",               brand: "",           calories: 275, proteins: 8.0,  carbohydrates: 50.0, fats: 4.0,  fiber: 2.5, sugar: 5.5,  sodium: 0.58, servingSize: 30,  servingUnit: "g",  barcode: "seed_pain_mie"),
        .init(name: "Riz blanc cuit",            brand: "",           calories: 130, proteins: 2.7,  carbohydrates: 28.0, fats: 0.3,  fiber: 0.4, sugar: 0.0,  sodium: 0.00, servingSize: 100, servingUnit: "g",  barcode: "seed_riz_blanc"),
        .init(name: "Riz complet cuit",          brand: "",           calories: 110, proteins: 2.6,  carbohydrates: 23.0, fats: 0.9,  fiber: 1.8, sugar: 0.0,  sodium: 0.00, servingSize: 100, servingUnit: "g",  barcode: "seed_riz_complet"),
        .init(name: "Pâtes cuites (spaghetti)",  brand: "",           calories: 157, proteins: 5.5,  carbohydrates: 30.0, fats: 1.0,  fiber: 1.8, sugar: 0.6,  sodium: 0.01, servingSize: 100, servingUnit: "g",  barcode: "seed_pates_cuites"),
        .init(name: "Pâtes sèches",              brand: "",           calories: 357, proteins: 13.0, carbohydrates: 70.0, fats: 1.5,  fiber: 2.5, sugar: 3.0,  sodium: 0.01, servingSize: 80,  servingUnit: "g",  barcode: "seed_pates_seches"),
        .init(name: "Quinoa cuit",               brand: "",           calories: 120, proteins: 4.4,  carbohydrates: 21.0, fats: 1.9,  fiber: 2.8, sugar: 0.9,  sodium: 0.01, servingSize: 100, servingUnit: "g",  barcode: "seed_quinoa"),
        .init(name: "Flocons d'avoine",          brand: "",           calories: 367, proteins: 13.5, carbohydrates: 59.0, fats: 7.0,  fiber: 9.5, sugar: 1.0,  sodium: 0.01, servingSize: 40,  servingUnit: "g",  barcode: "seed_avoine"),
        .init(name: "Semoule cuite",             brand: "",           calories: 112, proteins: 3.8,  carbohydrates: 23.0, fats: 0.2,  fiber: 1.5, sugar: 0.5,  sodium: 0.01, servingSize: 100, servingUnit: "g",  barcode: "seed_semoule"),
        .init(name: "Pomme de terre bouillie",   brand: "",           calories: 77,  proteins: 2.0,  carbohydrates: 17.0, fats: 0.1,  fiber: 1.8, sugar: 0.8,  sodium: 0.00, servingSize: 100, servingUnit: "g",  barcode: "seed_pdterre_bouillie"),
        .init(name: "Pomme de terre vapeur",     brand: "",           calories: 80,  proteins: 2.1,  carbohydrates: 17.5, fats: 0.1,  fiber: 2.0, sugar: 0.9,  sodium: 0.00, servingSize: 100, servingUnit: "g",  barcode: "seed_pdterre_vapeur"),
        .init(name: "Frites maison",             brand: "",           calories: 220, proteins: 3.5,  carbohydrates: 28.0, fats: 11.0, fiber: 2.5, sugar: 0.5,  sodium: 0.30, servingSize: 100, servingUnit: "g",  barcode: "seed_frites"),
        .init(name: "Lentilles cuites",          brand: "",           calories: 116, proteins: 9.0,  carbohydrates: 20.0, fats: 0.4,  fiber: 7.9, sugar: 1.8,  sodium: 0.01, servingSize: 100, servingUnit: "g",  barcode: "seed_lentilles"),
        .init(name: "Pois chiches cuits",        brand: "",           calories: 164, proteins: 8.9,  carbohydrates: 27.0, fats: 2.6,  fiber: 8.0, sugar: 4.8,  sodium: 0.24, servingSize: 100, servingUnit: "g",  barcode: "seed_pois_chiches"),
        .init(name: "Haricots rouges cuits",     brand: "",           calories: 127, proteins: 8.7,  carbohydrates: 22.0, fats: 0.5,  fiber: 7.4, sugar: 0.3,  sodium: 0.24, servingSize: 100, servingUnit: "g",  barcode: "seed_haricots_rouges"),
        .init(name: "Maïs doux (boîte)",         brand: "",           calories: 86,  proteins: 3.2,  carbohydrates: 18.0, fats: 1.2,  fiber: 2.0, sugar: 6.0,  sodium: 0.25, servingSize: 100, servingUnit: "g",  barcode: "seed_mais_doux"),
        .init(name: "Biscottes complètes",       brand: "",           calories: 390, proteins: 11.0, carbohydrates: 70.0, fats: 7.0,  fiber: 8.5, sugar: 5.0,  sodium: 0.70, servingSize: 10,  servingUnit: "g",  barcode: "seed_biscottes"),
        .init(name: "Muesli",                    brand: "",           calories: 360, proteins: 9.0,  carbohydrates: 63.0, fats: 7.0,  fiber: 6.5, sugar: 24.0, sodium: 0.10, servingSize: 50,  servingUnit: "g",  barcode: "seed_muesli"),

        // ── VIANDES ──────────────────────────────────────────────────
        .init(name: "Poulet (blanc, grillé)",    brand: "",           calories: 165, proteins: 31.0, carbohydrates: 0.0,  fats: 3.6,  fiber: 0.0, sugar: 0.0,  sodium: 0.07, servingSize: 100, servingUnit: "g",  barcode: "seed_poulet_blanc"),
        .init(name: "Poulet (cuisse, cuit)",     brand: "",           calories: 209, proteins: 26.0, carbohydrates: 0.0,  fats: 11.0, fiber: 0.0, sugar: 0.0,  sodium: 0.09, servingSize: 100, servingUnit: "g",  barcode: "seed_poulet_cuisse"),
        .init(name: "Bœuf haché 5% MG",         brand: "",           calories: 144, proteins: 21.0, carbohydrates: 0.0,  fats: 7.0,  fiber: 0.0, sugar: 0.0,  sodium: 0.08, servingSize: 100, servingUnit: "g",  barcode: "seed_boeuf_hache_5"),
        .init(name: "Bœuf haché 15% MG",        brand: "",           calories: 215, proteins: 17.0, carbohydrates: 0.0,  fats: 17.0, fiber: 0.0, sugar: 0.0,  sodium: 0.08, servingSize: 100, servingUnit: "g",  barcode: "seed_boeuf_hache_15"),
        .init(name: "Steak de bœuf grillé",     brand: "",           calories: 217, proteins: 26.0, carbohydrates: 0.0,  fats: 12.0, fiber: 0.0, sugar: 0.0,  sodium: 0.06, servingSize: 100, servingUnit: "g",  barcode: "seed_steak_boeuf"),
        .init(name: "Côtelette de porc grillée", brand: "",           calories: 231, proteins: 25.0, carbohydrates: 0.0,  fats: 14.0, fiber: 0.0, sugar: 0.0,  sodium: 0.07, servingSize: 100, servingUnit: "g",  barcode: "seed_porc_cotelette"),
        .init(name: "Filet de porc",             brand: "",           calories: 143, proteins: 22.0, carbohydrates: 0.0,  fats: 5.5,  fiber: 0.0, sugar: 0.0,  sodium: 0.07, servingSize: 100, servingUnit: "g",  barcode: "seed_porc_filet"),
        .init(name: "Escalope de dinde",         brand: "",           calories: 120, proteins: 24.0, carbohydrates: 0.0,  fats: 2.0,  fiber: 0.0, sugar: 0.0,  sodium: 0.07, servingSize: 100, servingUnit: "g",  barcode: "seed_dinde_escalope"),
        .init(name: "Jambon blanc (tranches)",   brand: "",           calories: 107, proteins: 16.5, carbohydrates: 1.5,  fats: 4.0,  fiber: 0.0, sugar: 1.0,  sodium: 1.20, servingSize: 45,  servingUnit: "g",  barcode: "seed_jambon_blanc"),
        .init(name: "Jambon de Bayonne",         brand: "",           calories: 225, proteins: 24.0, carbohydrates: 0.0,  fats: 15.0, fiber: 0.0, sugar: 0.0,  sodium: 2.50, servingSize: 30,  servingUnit: "g",  barcode: "seed_jambon_bayonne"),
        .init(name: "Lardons fumés",             brand: "",           calories: 337, proteins: 14.0, carbohydrates: 0.5,  fats: 31.0, fiber: 0.0, sugar: 0.0,  sodium: 1.80, servingSize: 50,  servingUnit: "g",  barcode: "seed_lardons"),
        .init(name: "Saucisse de Francfort",     brand: "",           calories: 290, proteins: 11.0, carbohydrates: 2.0,  fats: 26.0, fiber: 0.0, sugar: 1.0,  sodium: 1.40, servingSize: 50,  servingUnit: "g",  barcode: "seed_saucisse_francfort"),
        .init(name: "Merguez grillée",           brand: "",           calories: 298, proteins: 16.0, carbohydrates: 1.0,  fats: 26.0, fiber: 0.0, sugar: 0.5,  sodium: 1.60, servingSize: 60,  servingUnit: "g",  barcode: "seed_merguez"),
        .init(name: "Agneau (côtelette)",        brand: "",           calories: 294, proteins: 24.0, carbohydrates: 0.0,  fats: 21.0, fiber: 0.0, sugar: 0.0,  sodium: 0.07, servingSize: 100, servingUnit: "g",  barcode: "seed_agneau"),

        // ── POISSONS & FRUITS DE MER ───────────────────────────────
        .init(name: "Saumon grillé",             brand: "",           calories: 208, proteins: 20.0, carbohydrates: 0.0,  fats: 13.0, fiber: 0.0, sugar: 0.0,  sodium: 0.06, servingSize: 100, servingUnit: "g",  barcode: "seed_saumon_grille"),
        .init(name: "Thon au naturel (boîte)",   brand: "",           calories: 103, proteins: 24.0, carbohydrates: 0.0,  fats: 1.0,  fiber: 0.0, sugar: 0.0,  sodium: 0.40, servingSize: 100, servingUnit: "g",  barcode: "seed_thon_naturel"),
        .init(name: "Thon à l'huile (boîte)",    brand: "",           calories: 200, proteins: 22.0, carbohydrates: 0.0,  fats: 13.0, fiber: 0.0, sugar: 0.0,  sodium: 0.40, servingSize: 100, servingUnit: "g",  barcode: "seed_thon_huile"),
        .init(name: "Sardines à l'huile",        brand: "",           calories: 208, proteins: 25.0, carbohydrates: 0.0,  fats: 12.0, fiber: 0.0, sugar: 0.0,  sodium: 0.65, servingSize: 100, servingUnit: "g",  barcode: "seed_sardines"),
        .init(name: "Cabillaud vapeur",          brand: "",           calories: 82,  proteins: 18.0, carbohydrates: 0.0,  fats: 0.7,  fiber: 0.0, sugar: 0.0,  sodium: 0.06, servingSize: 100, servingUnit: "g",  barcode: "seed_cabillaud"),
        .init(name: "Crevettes cuites",          brand: "",           calories: 99,  proteins: 21.0, carbohydrates: 0.0,  fats: 1.1,  fiber: 0.0, sugar: 0.0,  sodium: 1.10, servingSize: 100, servingUnit: "g",  barcode: "seed_crevettes"),
        .init(name: "Moules cuites",             brand: "",           calories: 86,  proteins: 12.0, carbohydrates: 4.0,  fats: 2.0,  fiber: 0.0, sugar: 0.0,  sodium: 0.29, servingSize: 100, servingUnit: "g",  barcode: "seed_moules"),

        // ── ŒUFS ────────────────────────────────────────────────────
        .init(name: "Œuf entier",                brand: "",           calories: 143, proteins: 13.0, carbohydrates: 1.0,  fats: 9.5,  fiber: 0.0, sugar: 0.6,  sodium: 0.14, servingSize: 50,  servingUnit: "g",  barcode: "seed_oeuf"),
        .init(name: "Blanc d'œuf",               brand: "",           calories: 52,  proteins: 11.0, carbohydrates: 0.7,  fats: 0.2,  fiber: 0.0, sugar: 0.7,  sodium: 0.17, servingSize: 33,  servingUnit: "g",  barcode: "seed_blanc_oeuf"),
        .init(name: "Œuf dur",                   brand: "",           calories: 155, proteins: 13.0, carbohydrates: 1.1,  fats: 11.0, fiber: 0.0, sugar: 1.1,  sodium: 0.14, servingSize: 50,  servingUnit: "g",  barcode: "seed_oeuf_dur"),

        // ── PRODUITS LAITIERS ────────────────────────────────────────
        .init(name: "Lait demi-écrémé",          brand: "",           calories: 46,  proteins: 3.2,  carbohydrates: 4.7,  fats: 1.5,  fiber: 0.0, sugar: 4.7,  sodium: 0.05, servingSize: 250, servingUnit: "ml", barcode: "seed_lait_demi"),
        .init(name: "Lait écrémé",               brand: "",           calories: 35,  proteins: 3.4,  carbohydrates: 5.0,  fats: 0.1,  fiber: 0.0, sugar: 5.0,  sodium: 0.05, servingSize: 250, servingUnit: "ml", barcode: "seed_lait_ecreme"),
        .init(name: "Lait entier",               brand: "",           calories: 61,  proteins: 3.2,  carbohydrates: 4.6,  fats: 3.3,  fiber: 0.0, sugar: 4.6,  sodium: 0.04, servingSize: 250, servingUnit: "ml", barcode: "seed_lait_entier"),
        .init(name: "Yaourt nature (0%)",        brand: "",           calories: 47,  proteins: 5.0,  carbohydrates: 7.0,  fats: 0.1,  fiber: 0.0, sugar: 7.0,  sodium: 0.07, servingSize: 125, servingUnit: "g",  barcode: "seed_yaourt_0"),
        .init(name: "Yaourt nature entier",      brand: "",           calories: 61,  proteins: 3.5,  carbohydrates: 4.7,  fats: 3.5,  fiber: 0.0, sugar: 4.7,  sodium: 0.05, servingSize: 125, servingUnit: "g",  barcode: "seed_yaourt_entier"),
        .init(name: "Fromage blanc (0%)",        brand: "",           calories: 45,  proteins: 8.0,  carbohydrates: 4.0,  fats: 0.1,  fiber: 0.0, sugar: 4.0,  sodium: 0.05, servingSize: 100, servingUnit: "g",  barcode: "seed_fb_0"),
        .init(name: "Fromage blanc (3,2%)",      brand: "",           calories: 72,  proteins: 7.0,  carbohydrates: 4.5,  fats: 3.2,  fiber: 0.0, sugar: 4.5,  sodium: 0.05, servingSize: 100, servingUnit: "g",  barcode: "seed_fb_32"),
        .init(name: "Skyr nature",               brand: "",           calories: 63,  proteins: 11.0, carbohydrates: 4.0,  fats: 0.2,  fiber: 0.0, sugar: 4.0,  sodium: 0.05, servingSize: 150, servingUnit: "g",  barcode: "seed_skyr"),
        .init(name: "Crème fraîche épaisse",     brand: "",           calories: 292, proteins: 2.0,  carbohydrates: 2.8,  fats: 30.0, fiber: 0.0, sugar: 2.8,  sodium: 0.05, servingSize: 30,  servingUnit: "g",  barcode: "seed_creme_fraiche"),
        .init(name: "Beurre",                    brand: "",           calories: 717, proteins: 0.5,  carbohydrates: 0.5,  fats: 81.0, fiber: 0.0, sugar: 0.5,  sodium: 0.70, servingSize: 10,  servingUnit: "g",  barcode: "seed_beurre"),
        .init(name: "Emmental râpé",             brand: "",           calories: 380, proteins: 28.0, carbohydrates: 1.5,  fats: 30.0, fiber: 0.0, sugar: 0.5,  sodium: 0.65, servingSize: 30,  servingUnit: "g",  barcode: "seed_emmental"),
        .init(name: "Camembert",                 brand: "",           calories: 300, proteins: 20.0, carbohydrates: 0.5,  fats: 24.0, fiber: 0.0, sugar: 0.5,  sodium: 1.30, servingSize: 30,  servingUnit: "g",  barcode: "seed_camembert"),
        .init(name: "Comté",                     brand: "",           calories: 407, proteins: 28.0, carbohydrates: 0.0,  fats: 32.0, fiber: 0.0, sugar: 0.0,  sodium: 0.60, servingSize: 30,  servingUnit: "g",  barcode: "seed_comte"),
        .init(name: "Mozzarella",                brand: "",           calories: 280, proteins: 18.0, carbohydrates: 2.2,  fats: 22.0, fiber: 0.0, sugar: 0.5,  sodium: 0.60, servingSize: 50,  servingUnit: "g",  barcode: "seed_mozzarella"),

        // ── FRUITS ───────────────────────────────────────────────────
        .init(name: "Pomme",                     brand: "",           calories: 52,  proteins: 0.3,  carbohydrates: 14.0, fats: 0.2,  fiber: 2.4, sugar: 10.0, sodium: 0.00, servingSize: 150, servingUnit: "g",  barcode: "seed_pomme"),
        .init(name: "Banane",                    brand: "",           calories: 89,  proteins: 1.1,  carbohydrates: 23.0, fats: 0.3,  fiber: 2.6, sugar: 12.0, sodium: 0.00, servingSize: 120, servingUnit: "g",  barcode: "seed_banane"),
        .init(name: "Orange",                    brand: "",           calories: 47,  proteins: 0.9,  carbohydrates: 12.0, fats: 0.1,  fiber: 2.4, sugar: 9.5,  sodium: 0.00, servingSize: 150, servingUnit: "g",  barcode: "seed_orange"),
        .init(name: "Fraises",                   brand: "",           calories: 32,  proteins: 0.7,  carbohydrates: 7.7,  fats: 0.3,  fiber: 2.0, sugar: 5.0,  sodium: 0.00, servingSize: 150, servingUnit: "g",  barcode: "seed_fraises"),
        .init(name: "Raisins",                   brand: "",           calories: 69,  proteins: 0.7,  carbohydrates: 18.0, fats: 0.2,  fiber: 0.9, sugar: 16.0, sodium: 0.00, servingSize: 100, servingUnit: "g",  barcode: "seed_raisins"),
        .init(name: "Myrtilles",                 brand: "",           calories: 57,  proteins: 0.7,  carbohydrates: 14.0, fats: 0.3,  fiber: 2.4, sugar: 10.0, sodium: 0.00, servingSize: 100, servingUnit: "g",  barcode: "seed_myrtilles"),
        .init(name: "Mangue",                    brand: "",           calories: 60,  proteins: 0.8,  carbohydrates: 15.0, fats: 0.4,  fiber: 1.6, sugar: 13.7, sodium: 0.00, servingSize: 150, servingUnit: "g",  barcode: "seed_mangue"),
        .init(name: "Ananas",                    brand: "",           calories: 50,  proteins: 0.5,  carbohydrates: 13.0, fats: 0.1,  fiber: 1.4, sugar: 10.0, sodium: 0.00, servingSize: 150, servingUnit: "g",  barcode: "seed_ananas"),
        .init(name: "Kiwi",                      brand: "",           calories: 61,  proteins: 1.1,  carbohydrates: 15.0, fats: 0.5,  fiber: 3.0, sugar: 9.0,  sodium: 0.00, servingSize: 80,  servingUnit: "g",  barcode: "seed_kiwi"),
        .init(name: "Poire",                     brand: "",           calories: 57,  proteins: 0.4,  carbohydrates: 15.0, fats: 0.1,  fiber: 3.1, sugar: 10.0, sodium: 0.00, servingSize: 150, servingUnit: "g",  barcode: "seed_poire"),
        .init(name: "Pêche",                     brand: "",           calories: 39,  proteins: 0.9,  carbohydrates: 9.5,  fats: 0.3,  fiber: 1.5, sugar: 8.4,  sodium: 0.00, servingSize: 150, servingUnit: "g",  barcode: "seed_peche"),
        .init(name: "Pastèque",                  brand: "",           calories: 30,  proteins: 0.6,  carbohydrates: 7.5,  fats: 0.2,  fiber: 0.4, sugar: 6.2,  sodium: 0.00, servingSize: 200, servingUnit: "g",  barcode: "seed_pasteque"),

        // ── LÉGUMES ──────────────────────────────────────────────────
        .init(name: "Tomate",                    brand: "",           calories: 18,  proteins: 0.9,  carbohydrates: 3.9,  fats: 0.2,  fiber: 1.2, sugar: 2.6,  sodium: 0.00, servingSize: 150, servingUnit: "g",  barcode: "seed_tomate"),
        .init(name: "Salade verte",              brand: "",           calories: 15,  proteins: 1.4,  carbohydrates: 2.2,  fats: 0.2,  fiber: 1.3, sugar: 0.8,  sodium: 0.02, servingSize: 50,  servingUnit: "g",  barcode: "seed_salade"),
        .init(name: "Concombre",                 brand: "",           calories: 16,  proteins: 0.6,  carbohydrates: 3.6,  fats: 0.1,  fiber: 0.5, sugar: 1.7,  sodium: 0.00, servingSize: 100, servingUnit: "g",  barcode: "seed_concombre"),
        .init(name: "Carotte",                   brand: "",           calories: 41,  proteins: 0.9,  carbohydrates: 10.0, fats: 0.2,  fiber: 2.8, sugar: 4.7,  sodium: 0.07, servingSize: 100, servingUnit: "g",  barcode: "seed_carotte"),
        .init(name: "Brocoli cuit",              brand: "",           calories: 35,  proteins: 2.4,  carbohydrates: 7.0,  fats: 0.4,  fiber: 2.6, sugar: 1.7,  sodium: 0.04, servingSize: 100, servingUnit: "g",  barcode: "seed_brocoli"),
        .init(name: "Épinards cuits",            brand: "",           calories: 23,  proteins: 2.9,  carbohydrates: 3.6,  fats: 0.4,  fiber: 2.4, sugar: 0.4,  sodium: 0.07, servingSize: 100, servingUnit: "g",  barcode: "seed_epinards"),
        .init(name: "Courgette cuite",           brand: "",           calories: 17,  proteins: 1.2,  carbohydrates: 3.1,  fats: 0.3,  fiber: 1.0, sugar: 2.0,  sodium: 0.00, servingSize: 100, servingUnit: "g",  barcode: "seed_courgette"),
        .init(name: "Poivron rouge",             brand: "",           calories: 31,  proteins: 1.0,  carbohydrates: 7.0,  fats: 0.3,  fiber: 2.1, sugar: 5.0,  sodium: 0.00, servingSize: 100, servingUnit: "g",  barcode: "seed_poivron"),
        .init(name: "Champignons de Paris",      brand: "",           calories: 22,  proteins: 3.1,  carbohydrates: 3.3,  fats: 0.3,  fiber: 1.0, sugar: 2.0,  sodium: 0.01, servingSize: 100, servingUnit: "g",  barcode: "seed_champignons"),
        .init(name: "Aubergine cuite",           brand: "",           calories: 25,  proteins: 0.8,  carbohydrates: 5.7,  fats: 0.2,  fiber: 2.5, sugar: 3.2,  sodium: 0.00, servingSize: 100, servingUnit: "g",  barcode: "seed_aubergine"),
        .init(name: "Haricots verts cuits",      brand: "",           calories: 31,  proteins: 1.8,  carbohydrates: 7.0,  fats: 0.1,  fiber: 3.4, sugar: 3.0,  sodium: 0.00, servingSize: 100, servingUnit: "g",  barcode: "seed_haricots_verts"),
        .init(name: "Petits pois surgelés",      brand: "",           calories: 81,  proteins: 5.4,  carbohydrates: 14.0, fats: 0.4,  fiber: 5.1, sugar: 5.6,  sodium: 0.00, servingSize: 100, servingUnit: "g",  barcode: "seed_petits_pois"),
        .init(name: "Avocat",                    brand: "",           calories: 160, proteins: 2.0,  carbohydrates: 9.0,  fats: 15.0, fiber: 6.7, sugar: 0.7,  sodium: 0.01, servingSize: 100, servingUnit: "g",  barcode: "seed_avocat"),
        .init(name: "Céleri branche",            brand: "",           calories: 16,  proteins: 0.7,  carbohydrates: 3.0,  fats: 0.2,  fiber: 1.6, sugar: 1.8,  sodium: 0.08, servingSize: 100, servingUnit: "g",  barcode: "seed_celeri"),

        // ── MATIÈRES GRASSES & HUILES ─────────────────────────────
        .init(name: "Huile d'olive",             brand: "",           calories: 884, proteins: 0.0,  carbohydrates: 0.0,  fats: 100.0,fiber: 0.0, sugar: 0.0,  sodium: 0.00, servingSize: 10,  servingUnit: "ml", barcode: "seed_huile_olive"),
        .init(name: "Huile de colza",            brand: "",           calories: 884, proteins: 0.0,  carbohydrates: 0.0,  fats: 100.0,fiber: 0.0, sugar: 0.0,  sodium: 0.00, servingSize: 10,  servingUnit: "ml", barcode: "seed_huile_colza"),
        .init(name: "Margarine",                 brand: "",           calories: 542, proteins: 0.2,  carbohydrates: 0.7,  fats: 60.0, fiber: 0.0, sugar: 0.7,  sodium: 0.60, servingSize: 10,  servingUnit: "g",  barcode: "seed_margarine"),

        // ── NOIX & GRAINES ───────────────────────────────────────────
        .init(name: "Amandes",                   brand: "",           calories: 579, proteins: 21.0, carbohydrates: 22.0, fats: 50.0, fiber: 12.5,sugar: 4.9,  sodium: 0.01, servingSize: 30,  servingUnit: "g",  barcode: "seed_amandes"),
        .init(name: "Noix",                      brand: "",           calories: 654, proteins: 15.0, carbohydrates: 14.0, fats: 65.0, fiber: 6.7, sugar: 2.6,  sodium: 0.02, servingSize: 30,  servingUnit: "g",  barcode: "seed_noix"),
        .init(name: "Noisettes",                 brand: "",           calories: 628, proteins: 15.0, carbohydrates: 17.0, fats: 61.0, fiber: 9.7, sugar: 4.3,  sodium: 0.00, servingSize: 30,  servingUnit: "g",  barcode: "seed_noisettes"),
        .init(name: "Graines de chia",           brand: "",           calories: 486, proteins: 17.0, carbohydrates: 42.0, fats: 31.0, fiber: 34.4,sugar: 0.0,  sodium: 0.02, servingSize: 15,  servingUnit: "g",  barcode: "seed_chia"),
        .init(name: "Graines de lin",            brand: "",           calories: 534, proteins: 18.0, carbohydrates: 29.0, fats: 42.0, fiber: 27.3,sugar: 1.6,  sodium: 0.03, servingSize: 10,  servingUnit: "g",  barcode: "seed_lin"),

        // ── BOISSONS ─────────────────────────────────────────────────
        .init(name: "Eau minérale",              brand: "",           calories: 0,   proteins: 0.0,  carbohydrates: 0.0,  fats: 0.0,  fiber: 0.0, sugar: 0.0,  sodium: 0.00, servingSize: 250, servingUnit: "ml", barcode: "seed_eau"),
        .init(name: "Jus d'orange frais",        brand: "",           calories: 45,  proteins: 0.7,  carbohydrates: 10.0, fats: 0.2,  fiber: 0.4, sugar: 9.0,  sodium: 0.00, servingSize: 200, servingUnit: "ml", barcode: "seed_jus_orange"),
        .init(name: "Café (expresso)",           brand: "",           calories: 2,   proteins: 0.1,  carbohydrates: 0.0,  fats: 0.0,  fiber: 0.0, sugar: 0.0,  sodium: 0.00, servingSize: 30,  servingUnit: "ml", barcode: "seed_cafe"),
        .init(name: "Thé sans sucre",            brand: "",           calories: 1,   proteins: 0.0,  carbohydrates: 0.3,  fats: 0.0,  fiber: 0.0, sugar: 0.0,  sodium: 0.00, servingSize: 250, servingUnit: "ml", barcode: "seed_the"),
        .init(name: "Coca-Cola",                 brand: "Coca-Cola",  calories: 42,  proteins: 0.0,  carbohydrates: 10.6, fats: 0.0,  fiber: 0.0, sugar: 10.6, sodium: 0.01, servingSize: 330, servingUnit: "ml", barcode: "seed_coca"),
        .init(name: "Coca-Cola Zero",            brand: "Coca-Cola",  calories: 0,   proteins: 0.0,  carbohydrates: 0.0,  fats: 0.0,  fiber: 0.0, sugar: 0.0,  sodium: 0.01, servingSize: 330, servingUnit: "ml", barcode: "seed_coca_zero"),
        .init(name: "Lait végétal (avoine)",     brand: "",           calories: 47,  proteins: 1.0,  carbohydrates: 7.0,  fats: 1.5,  fiber: 0.8, sugar: 4.0,  sodium: 0.06, servingSize: 250, servingUnit: "ml", barcode: "seed_lait_avoine"),
        .init(name: "Lait végétal (soja)",       brand: "",           calories: 39,  proteins: 3.3,  carbohydrates: 2.8,  fats: 1.8,  fiber: 0.4, sugar: 1.0,  sodium: 0.05, servingSize: 250, servingUnit: "ml", barcode: "seed_lait_soja"),

        // ── PRODUITS SUCRÉS ───────────────────────────────────────────
        .init(name: "Chocolat noir (70%)",       brand: "",           calories: 598, proteins: 7.8,  carbohydrates: 46.0, fats: 42.0, fiber: 10.9,sugar: 28.0, sodium: 0.02, servingSize: 20,  servingUnit: "g",  barcode: "seed_choco_noir"),
        .init(name: "Chocolat au lait",          brand: "",           calories: 535, proteins: 7.0,  carbohydrates: 59.0, fats: 31.0, fiber: 2.0, sugar: 55.0, sodium: 0.10, servingSize: 20,  servingUnit: "g",  barcode: "seed_choco_lait"),
        .init(name: "Miel",                      brand: "",           calories: 304, proteins: 0.3,  carbohydrates: 82.0, fats: 0.0,  fiber: 0.2, sugar: 82.0, sodium: 0.00, servingSize: 20,  servingUnit: "g",  barcode: "seed_miel"),
        .init(name: "Confiture (fraises)",       brand: "",           calories: 250, proteins: 0.4,  carbohydrates: 65.0, fats: 0.1,  fiber: 1.0, sugar: 63.0, sodium: 0.02, servingSize: 20,  servingUnit: "g",  barcode: "seed_confiture"),
        .init(name: "Nutella",                   brand: "Ferrero",    calories: 539, proteins: 6.3,  carbohydrates: 57.5, fats: 30.9, fiber: 3.4, sugar: 56.3, sodium: 0.11, servingSize: 20,  servingUnit: "g",  barcode: "seed_nutella"),

        // ── PLATS PRÉPARÉS COURANTS ──────────────────────────────────
        .init(name: "Soupe de légumes",          brand: "",           calories: 35,  proteins: 1.5,  carbohydrates: 7.0,  fats: 0.5,  fiber: 2.0, sugar: 3.5,  sodium: 0.50, servingSize: 250, servingUnit: "ml", barcode: "seed_soupe_legumes"),
        .init(name: "Pizza Margherita",          brand: "",           calories: 250, proteins: 10.0, carbohydrates: 33.0, fats: 9.0,  fiber: 2.0, sugar: 3.5,  sodium: 0.65, servingSize: 100, servingUnit: "g",  barcode: "seed_pizza_margherita"),
        .init(name: "Quiche Lorraine",           brand: "",           calories: 301, proteins: 8.5,  carbohydrates: 17.0, fats: 22.0, fiber: 0.8, sugar: 2.5,  sodium: 0.55, servingSize: 100, servingUnit: "g",  barcode: "seed_quiche"),
        .init(name: "Taboulé",                   brand: "",           calories: 150, proteins: 3.5,  carbohydrates: 20.0, fats: 6.5,  fiber: 2.5, sugar: 2.0,  sodium: 0.30, servingSize: 100, servingUnit: "g",  barcode: "seed_taboule"),
        .init(name: "Houmous",                   brand: "",           calories: 166, proteins: 7.9,  carbohydrates: 14.0, fats: 9.6,  fiber: 6.0, sugar: 0.5,  sodium: 0.40, servingSize: 50,  servingUnit: "g",  barcode: "seed_houmous"),
    ]
}
