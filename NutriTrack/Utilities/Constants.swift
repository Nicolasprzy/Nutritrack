import SwiftUI

// MARK: - Palette Lumina (Her × Apple Vision Pro)
// Fonds crème chauds, accents corail, texte brun chaud

extension ShapeStyle where Self == Color {
    // Accent principal Lumina — corail chaud
    static var luminaEmber: Color    { Color(red: 0.910, green: 0.353, blue: 0.247) }
    static var luminaEmberHot: Color { Color(red: 1.000, green: 0.478, blue: 0.333) }

    // Compatibilité : redirige nutriGreen vers le vert fonctionnel nutrition
    static var nutriGreen: Color     { Color(red: 0.267, green: 0.690, blue: 0.361) }
    static var nutriGreenDark: Color { Color(red: 0.157, green: 0.549, blue: 0.267) }
    static var proteineColor: Color  { Color(red: 0.298, green: 0.584, blue: 0.996) }
    static var glucideColor: Color   { Color(red: 0.996, green: 0.753, blue: 0.200) }
    static var lipideColor: Color    { Color(red: 0.996, green: 0.349, blue: 0.349) }
}

extension Color {
    // ── Lumina core palette ──────────────────────────────────────────────────
    /// Fond principal — crème chaud (#f4ede4)
    static let luminaBgDeep    = Color(red: 0.957, green: 0.929, blue: 0.894)
    /// Fond légèrement plus clair (#f6efe7)
    static let luminaBgVoid    = Color(red: 0.965, green: 0.937, blue: 0.906)
    /// Encre principale — brun sombre (#2a1f17)
    static let luminaInkPrimary   = Color(red: 0.165, green: 0.122, blue: 0.090)
    /// Encre secondaire (#5c4a3d)
    static let luminaInkSecondary = Color(red: 0.361, green: 0.290, blue: 0.239)
    /// Encre atténuée (#8a7869)
    static let luminaInkMuted     = Color(red: 0.541, green: 0.471, blue: 0.412)
    /// Encre dim (#b8a697)
    static let luminaInkDim       = Color(red: 0.722, green: 0.651, blue: 0.592)
    /// Encre très légère — séparateurs (#e8ddd0)
    static let luminaInkFaint     = Color(red: 0.910, green: 0.867, blue: 0.816)

    // Accents corail
    static let luminaEmber     = Color(red: 0.910, green: 0.353, blue: 0.247)  // #e85a3f
    static let luminaEmberHot  = Color(red: 1.000, green: 0.478, blue: 0.333)  // #ff7a55
    static let luminaEmberSoft = Color(red: 0.788, green: 0.290, blue: 0.188)  // #c94a30
    static let luminaBlood     = Color(red: 0.722, green: 0.282, blue: 0.353)  // #b8485a

    // ── Compatibilité ancienne palette ──────────────────────────────────────
    static let nutriGreen     = Color(red: 0.267, green: 0.690, blue: 0.361)
    static let nutriGreenDark = Color(red: 0.157, green: 0.549, blue: 0.267)
    static let proteineColor  = Color(red: 0.298, green: 0.584, blue: 0.996)
    static let glucideColor   = Color(red: 0.996, green: 0.753, blue: 0.200)
    static let lipideColor    = Color(red: 0.996, green: 0.349, blue: 0.349)
    static let alerteOrange   = Color(red: 1.0, green: 0.6, blue: 0.0)

    // ── Fond adaptatif — crème chaud Lumina ─────────────────────────────────
    static var fondPrincipal: Color { .luminaBgDeep }
}

// MARK: - Typographie Lumina

extension Font {
    // ── Display serif (imite Fraunces via New York / system serif) ───────────
    /// Grand titre cinématographique — italique serif fin
    static func luminaDisplay(_ size: CGFloat, weight: Font.Weight = .thin) -> Font {
        Font.system(size: size, weight: weight, design: .serif).italic()
    }
    /// Monospace UI — étiquettes, données chiffrées (imite JetBrains Mono)
    static func luminaMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .monospaced)
    }
    /// Eyebrow tracké majuscule
    static let luminaEyebrow = Font.system(size: 11, weight: .regular, design: .monospaced)
    /// Étiquette carte
    static let luminaCardLabel = Font.system(size: 10, weight: .regular, design: .monospaced)

    // ── Compatibilité ────────────────────────────────────────────────────────
    static let nutriLargeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let nutriTitle      = Font.system(.title,      design: .rounded, weight: .semibold)
    static let nutriTitle2     = Font.system(.title2,     design: .rounded, weight: .semibold)
    static let nutriHeadline   = Font.system(.headline,   design: .rounded)
    static let nutriBody       = Font.system(.body,       design: .rounded)
    static let nutriCaption    = Font.system(.caption,    design: .rounded)
}

// MARK: - Espacement

enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 16
    static let lg: CGFloat  = 24
    static let xl: CGFloat  = 32
    static let xxl: CGFloat = 48
}

// MARK: - Coins arrondis

enum Radius {
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 12
    static let lg: CGFloat  = 16
    static let xl: CGFloat  = 24
}

// MARK: - Types de repas

enum MealType: String, CaseIterable {
    case petitDejeuner = "petit_dejeuner"
    case dejeuner      = "dejeuner"
    case diner         = "diner"
    case collation     = "collation"

    var label: String {
        switch self {
        case .petitDejeuner: return "Petit-déjeuner"
        case .dejeuner:      return "Déjeuner"
        case .diner:         return "Dîner"
        case .collation:     return "Collation"
        }
    }

    var icon: String {
        switch self {
        case .petitDejeuner: return "sunrise.fill"
        case .dejeuner:      return "sun.max.fill"
        case .diner:         return "moon.fill"
        case .collation:     return "fork.knife"
        }
    }

    var couleur: Color {
        switch self {
        case .petitDejeuner: return .orange
        case .dejeuner:      return .yellow
        case .diner:         return .indigo
        case .collation:     return .teal
        }
    }
}

// MARK: - Niveaux d'activité

enum NiveauActivite: String, CaseIterable {
    case sedentaire  = "sedentaire"
    case leger       = "leger"
    case modere      = "modere"
    case actif       = "actif"
    case tres_actif  = "tres_actif"

    var label: String {
        switch self {
        case .sedentaire: return "Sédentaire"
        case .leger:      return "Légèrement actif"
        case .modere:     return "Modérément actif"
        case .actif:      return "Actif"
        case .tres_actif: return "Très actif"
        }
    }

    var facteur: Double {
        switch self {
        case .sedentaire: return 1.2
        case .leger:      return 1.375
        case .modere:     return 1.55
        case .actif:      return 1.725
        case .tres_actif: return 1.9
        }
    }
}

// MARK: - Sexe

enum Sexe: String, CaseIterable {
    case homme = "homme"
    case femme = "femme"

    var label: String {
        switch self {
        case .homme: return "Homme"
        case .femme: return "Femme"
        }
    }
}

// MARK: - Navigation

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard  = "dashboard"
    case journal    = "journal"
    case corps      = "corps"
    case photos     = "photos"
    case activite   = "activite"
    case profil     = "profil"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dashboard: return "Tableau de bord"
        case .journal:   return "Nutrition"
        case .corps:     return "Corps & Forme"
        case .photos:    return "Photos"
        case .activite:  return "Entraînement"
        case .profil:    return "Profil"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .journal:   return "fork.knife"
        case .corps:     return "figure.arms.open"
        case .photos:    return "photo.stack.fill"
        case .activite:  return "dumbbell.fill"
        case .profil:    return "person.circle.fill"
        }
    }

    var couleur: Color {
        switch self {
        case .dashboard: return .nutriGreen
        case .journal:   return .orange
        case .corps:     return .blue
        case .photos:    return .purple
        case .activite:  return .red
        case .profil:    return .gray
        }
    }
}

// MARK: - Silhouette objectif (v2)

enum SilhouetteObjectif: String, CaseIterable, Codable {
    case tresMince  = "tres_mince"  // émacié, très peu de masse graisseuse
    case mince      = "mince"       // mince, masse graisseuse faible
    case tonique    = "tonique"     // tonique / athlétique
    case normal     = "normal"      // poids santé
    case surpoids   = "surpoids"    // surpoids (IMC 25-30)
    case obese      = "obese"       // obèse (IMC > 30)

    func label(sexe: Sexe) -> String {
        switch self {
        case .tresMince: return "Très mince"
        case .mince:     return "Mince"
        case .tonique:   return sexe == .femme ? "Tonique"  : "Athlétique"
        case .normal:    return "Normal(e)"
        case .surpoids:  return "Surpoids"
        case .obese:     return "Obèse"
        }
    }

    /// Fourchette de masse graisseuse représentée (indicatif)
    func rangeMasseGraisseuse(sexe: Sexe) -> String {
        switch (self, sexe) {
        case (.tresMince, .femme): return "< 15 %"
        case (.tresMince, _):     return "< 8 %"
        case (.mince, .femme):    return "15–20 %"
        case (.mince, _):         return "8–13 %"
        case (.tonique, .femme):  return "18–22 %"
        case (.tonique, _):       return "10–15 %"
        case (.normal, .femme):   return "22–28 %"
        case (.normal, _):        return "15–20 %"
        case (.surpoids, .femme): return "30–38 %"
        case (.surpoids, _):      return "22–28 %"
        case (.obese, .femme):    return "> 38 %"
        case (.obese, _):         return "> 28 %"
        }
    }

    /// Index 0 = plus mince/maigre, 5 = plus de masse graisseuse
    var index: Int {
        switch self {
        case .tresMince: return 0
        case .mince:     return 1
        case .tonique:   return 2
        case .normal:    return 3
        case .surpoids:  return 4
        case .obese:     return 5
        }
    }
}

// MARK: - Approche de transformation

enum ApprocheTransformation: String, CaseIterable {
    case douce         = "douce"
    case normale       = "normale"
    case agressive     = "agressive"
    case tresAgressive = "tres_agressive"

    var label: String {
        switch self {
        case .douce:         return "Douce"
        case .normale:       return "Normale"
        case .agressive:     return "Agressive"
        case .tresAgressive: return "Très agressive"
        }
    }

    var emoji: String {
        switch self {
        case .douce:         return "🌱"
        case .normale:       return "⚡️"
        case .agressive:     return "🔥"
        case .tresAgressive: return "💥"
        }
    }

    var descriptionCourte: String {
        switch self {
        case .douce:         return "−250 kcal/j · ~0,25 kg/sem."
        case .normale:       return "−500 kcal/j · ~0,5 kg/sem."
        case .agressive:     return "−750 kcal/j · ~0,75 kg/sem."
        case .tresAgressive: return "−1 000 kcal/j · ~1 kg/sem."
        }
    }

    var descriptionLongue: String {
        switch self {
        case .douce:
            return "Idéale pour débuter ou ancrer des habitudes durables sans frustration ni fatigue."
        case .normale:
            return "L'équilibre optimal entre confort quotidien et résultats progressifs et constants."
        case .agressive:
            return "Pour ceux qui veulent accélérer. Nécessite de la discipline et un bon niveau sportif."
        case .tresAgressive:
            return "Résultats rapides, mais exigeants. Suivi strict indispensable — à éviter si débutant."
        }
    }

    var icone: String {
        switch self {
        case .douce:         return "leaf.fill"
        case .normale:       return "bolt.fill"
        case .agressive:     return "flame.fill"
        case .tresAgressive: return "exclamationmark.triangle.fill"
        }
    }

    var couleur: Color {
        switch self {
        case .douce:         return Color.nutriGreen
        case .normale:       return .blue
        case .agressive:     return .orange
        case .tresAgressive: return .red
        }
    }

    /// Déficit calorique journalier maximum appliqué (perte de masse)
    var deficitMaxKcal: Double {
        switch self {
        case .douce:         return 250
        case .normale:       return 500
        case .agressive:     return 750
        case .tresAgressive: return 1000
        }
    }

    /// Surplus calorique journalier maximum appliqué (prise de masse).
    /// Limité à 500 kcal max : au-delà, les calories supplémentaires vont au tissu adipeux,
    /// pas au muscle (meta-analyse PMC10620361 + PMC6680710).
    var surplusMaxKcal: Double {
        switch self {
        case .douce:         return 150
        case .normale:       return 300
        case .agressive:     return 450
        case .tresAgressive: return 500
        }
    }

    /// Protéines recommandées en g/kg de poids total (phase déficit).
    /// Sources : ISSN Position Stand (PMC5477153), Helms et al. 2014 (IJSNEM).
    /// • Douce   : 1.6–2.0 g/kg → 1.8
    /// • Normale : 2.0–2.3 g/kg → 2.0
    /// • Agressive : minimum ISSN 2.3 g/kg → 2.3
    /// • Très agressive : jusqu'à 3.1 g/kg FFM → 2.5 (raisonnable pour poids total)
    var proteinesGParKg: Double {
        switch self {
        case .douce:         return 1.8
        case .normale:       return 2.0
        case .agressive:     return 2.3
        case .tresAgressive: return 2.5
        }
    }

    /// Part des glucides dans la ration (phase déficit)
    var glucidesPourcentage: Double {
        switch self {
        case .douce:         return 0.38
        case .normale:       return 0.33
        case .agressive:     return 0.28
        case .tresAgressive: return 0.22
        }
    }

    /// Perte hebdomadaire estimée en kg (déficit)
    var perteSemaineKg: Double { deficitMaxKcal * 7 / 7_700 }

    /// Gain hebdomadaire estimé en kg (surplus)
    var gainSemaineKg: Double { surplusMaxKcal * 7 / 5_000 }

    /// Fréquence d'entraînement recommandée pour cette approche
    var seancesConseillees: String {
        switch self {
        case .douce:         return "2–3 séances/sem."
        case .normale:       return "3–4 séances/sem."
        case .agressive:     return "4–5 séances/sem."
        case .tresAgressive: return "5–6 séances/sem."
        }
    }

    /// Niveau d'intensité d'entraînement recommandé
    var intensiteEntrainement: String {
        switch self {
        case .douce:         return "Légère à modérée"
        case .normale:       return "Modérée"
        case .agressive:     return "Modérée à intense"
        case .tresAgressive: return "Très intense"
        }
    }
}

// MARK: - Niveau sport

enum NiveauSport: String, CaseIterable, Codable {
    case debutant      = "debutant"
    case intermediaire = "intermediaire"
    case avance        = "avance"

    var label: String {
        switch self {
        case .debutant:      return "Débutant"
        case .intermediaire: return "Intermédiaire"
        case .avance:        return "Avancé"
        }
    }

    var icon: String {
        switch self {
        case .debutant:      return "1.circle.fill"
        case .intermediaire: return "2.circle.fill"
        case .avance:        return "3.circle.fill"
        }
    }
}

// MARK: - Équipement sport

enum EquipementSport: String, CaseIterable, Codable {
    case poidsCorps = "poids_corps"
    case halteres   = "halteres"
    case salle      = "salle"
    case exterieur  = "exterieur"
    case mix        = "mix"

    var label: String {
        switch self {
        case .poidsCorps: return "Poids du corps"
        case .halteres:   return "Haltères à domicile"
        case .salle:      return "Salle de sport complète"
        case .exterieur:  return "Extérieur"
        case .mix:        return "Mix / Varié"
        }
    }

    var icon: String {
        switch self {
        case .poidsCorps: return "figure.gymnastics"
        case .halteres:   return "dumbbell.fill"
        case .salle:      return "building.2.fill"
        case .exterieur:  return "leaf.fill"
        case .mix:        return "shuffle"
        }
    }
}

// MARK: - Régime alimentaire

enum RegimeAlimentaire: String, CaseIterable, Codable {
    case omnivore   = "omnivore"
    case vegetarien = "vegetarien"
    case vegan      = "vegan"
    case sansGluten = "sans_gluten"
    case autre      = "autre"

    var label: String {
        switch self {
        case .omnivore:   return "Omnivore"
        case .vegetarien: return "Végétarien"
        case .vegan:      return "Vegan"
        case .sansGluten: return "Sans gluten"
        case .autre:      return "Autre"
        }
    }

    var icon: String {
        switch self {
        case .omnivore:   return "fork.knife"
        case .vegetarien: return "leaf.fill"
        case .vegan:      return "tortoise.fill"
        case .sansGluten: return "xmark.circle"
        case .autre:      return "ellipsis.circle"
        }
    }
}

// MARK: - Habitude alcool

enum AlcoolHabitude: String, CaseIterable, Codable {
    case jamais      = "jamais"
    case occasionnel = "occasionnel"
    case regulier    = "regulier"

    var label: String {
        switch self {
        case .jamais:      return "Jamais"
        case .occasionnel: return "Occasionnel"
        case .regulier:    return "Régulier"
        }
    }
}

// MARK: - Niveau de faisabilité du plan

enum NiveauFaisabilite: String, Codable {
    case realiste  = "realiste"
    case ambitieux = "ambitieux"
    case dangereux = "dangereux"

    var label: String {
        switch self {
        case .realiste:  return "Objectif réaliste"
        case .ambitieux: return "Objectif ambitieux"
        case .dangereux: return "Objectif dangereux"
        }
    }

    var icon: String {
        switch self {
        case .realiste:  return "checkmark.circle.fill"
        case .ambitieux: return "exclamationmark.triangle.fill"
        case .dangereux: return "xmark.octagon.fill"
        }
    }

    var couleur: Color {
        switch self {
        case .realiste:  return .nutriGreen
        case .ambitieux: return .alerteOrange
        case .dangereux: return .red
        }
    }
}

// MARK: - API

enum APIConstants {
    static let openFoodFactsSearch  = "https://world.openfoodfacts.org/cgi/search.pl"
    static let openFoodFactsProduct = "https://world.openfoodfacts.org/api/v0/product"
}
