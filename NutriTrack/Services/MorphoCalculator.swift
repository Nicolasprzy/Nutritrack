import Foundation
import SwiftUI

// MARK: - Statut d'une zone corporelle

enum StatutZone: Equatable {
    case optimal
    case attention
    case exces
    case insuffisant
    case nonMesure

    var couleur: Color {
        switch self {
        case .optimal:     return Color.nutriGreen
        case .attention:   return .orange
        case .exces:       return .red
        case .insuffisant: return .blue
        case .nonMesure:   return Color.secondary.opacity(0.35)
        }
    }

    var label: String {
        switch self {
        case .optimal:     return "Normal"
        case .attention:   return "Attention"
        case .exces:       return "Excessif"
        case .insuffisant: return "Insuffisant"
        case .nonMesure:   return "Non mesuré"
        }
    }

    var icone: String {
        switch self {
        case .optimal:     return "checkmark.circle.fill"
        case .attention:   return "exclamationmark.triangle.fill"
        case .exces:       return "arrow.up.circle.fill"
        case .insuffisant: return "arrow.down.circle.fill"
        case .nonMesure:   return "questionmark.circle"
        }
    }
}

// MARK: - Zones corporelles

enum ZoneCorporelle: String, CaseIterable, Identifiable {
    case imc         = "IMC"
    case masseGrasse = "Masse grasse"
    case taille      = "Tour de taille"
    case hanches     = "Hanches"
    case poitrine    = "Poitrine"
    case bras        = "Bras"
    case cuisse      = "Cuisse"

    var id: String { rawValue }

    var icone: String {
        switch self {
        case .imc:         return "figure.stand"
        case .masseGrasse: return "drop.fill"
        case .taille:      return "arrow.left.and.right"
        case .hanches:     return "oval"
        case .poitrine:    return "lungs.fill"
        case .bras:        return "dumbbell.fill"
        case .cuisse:      return "figure.walk"
        }
    }
}

// MARK: - Résultat d'analyse d'une zone

struct AnalyseZone: Identifiable {
    let id = UUID()
    let zone: ZoneCorporelle
    let statut: StatutZone
    let valeurAffichee: String
    let conseil: String
}

// MARK: - Analyse morphologique complète

struct AnalyseMorpho {
    let zones: [AnalyseZone]

    func statut(pour zone: ZoneCorporelle) -> StatutZone {
        zones.first(where: { $0.zone == zone })?.statut ?? .nonMesure
    }

    /// Score de 0 à 100 basé sur les zones mesurées
    var scoreGlobal: Int {
        let mesures = zones.filter { $0.statut != .nonMesure }
        guard !mesures.isEmpty else { return 0 }
        let points = mesures.reduce(0) { acc, z in
            switch z.statut {
            case .optimal:              return acc + 2
            case .attention:            return acc + 1
            case .exces, .insuffisant:  return acc
            case .nonMesure:            return acc
            }
        }
        return Int((Double(points) / Double(mesures.count * 2)) * 100)
    }

    var labelScore: String {
        switch scoreGlobal {
        case 80...: return "Excellent"
        case 60..<80: return "Bien"
        case 40..<60: return "Moyen"
        default: return "À améliorer"
        }
    }

    var couleurScore: Color {
        switch scoreGlobal {
        case 80...: return Color.nutriGreen
        case 60..<80: return .orange
        default: return .red
        }
    }
}

// MARK: - Calculateur

struct MorphoCalculator {

    // MARK: - Analyse complète

    static func analyser(
        taille: Double,          // cm
        sexe: String,
        poids: Double,           // kg
        waist: Double,           // cm (0 = non mesuré)
        hips: Double,            // cm
        chest: Double,           // cm
        arm: Double,             // cm
        thigh: Double,           // cm
        masseGrasse: Double,     // % (0 = non mesuré)
        bmi: Double
    ) -> AnalyseMorpho {

        let h = taille
        let estHomme = sexe.lowercased() == "homme"
        var zones: [AnalyseZone] = []

        // ── IMC ────────────────────────────────────────────────────────
        zones.append(analyserIMC(bmi: bmi))

        // ── Masse grasse ───────────────────────────────────────────────
        if masseGrasse > 0 {
            zones.append(analyserMasseGrasse(mg: masseGrasse, estHomme: estHomme))
        } else {
            zones.append(AnalyseZone(zone: .masseGrasse, statut: .nonMesure,
                                     valeurAffichee: "—", conseil: "Non renseigné"))
        }

        // ── Tour de taille (WHtR) ──────────────────────────────────────
        if waist > 0, h > 0 {
            zones.append(analyserTaille(waist: waist, height: h))
        } else {
            zones.append(AnalyseZone(zone: .taille, statut: .nonMesure,
                                     valeurAffichee: "—", conseil: "Non mesuré"))
        }

        // ── Hanches ────────────────────────────────────────────────────
        if hips > 0, waist > 0 {
            zones.append(analyserHanchesWHR(hips: hips, waist: waist, estHomme: estHomme))
        } else if hips > 0, h > 0 {
            zones.append(analyserHanchesRatio(hips: hips, height: h, estHomme: estHomme))
        } else {
            zones.append(AnalyseZone(zone: .hanches, statut: .nonMesure,
                                     valeurAffichee: "—", conseil: "Non mesuré"))
        }

        // ── Poitrine ───────────────────────────────────────────────────
        if chest > 0, h > 0 {
            zones.append(analyserPoitrine(chest: chest, height: h, estHomme: estHomme))
        } else {
            zones.append(AnalyseZone(zone: .poitrine, statut: .nonMesure,
                                     valeurAffichee: "—", conseil: "Non mesuré"))
        }

        // ── Bras ───────────────────────────────────────────────────────
        if arm > 0, h > 0 {
            zones.append(analyserBras(arm: arm, height: h, estHomme: estHomme))
        } else {
            zones.append(AnalyseZone(zone: .bras, statut: .nonMesure,
                                     valeurAffichee: "—", conseil: "Non mesuré"))
        }

        // ── Cuisse ────────────────────────────────────────────────────
        if thigh > 0, h > 0 {
            zones.append(analyserCuisse(thigh: thigh, height: h, estHomme: estHomme))
        } else {
            zones.append(AnalyseZone(zone: .cuisse, statut: .nonMesure,
                                     valeurAffichee: "—", conseil: "Non mesuré"))
        }

        return AnalyseMorpho(zones: zones)
    }

    // MARK: - IMC

    private static func analyserIMC(bmi: Double) -> AnalyseZone {
        guard bmi > 0 else {
            return AnalyseZone(zone: .imc, statut: .nonMesure,
                               valeurAffichee: "—", conseil: "Non calculé")
        }
        let (statut, conseil): (StatutZone, String)
        switch bmi {
        case ..<16:
            (statut, conseil) = (.insuffisant, "IMC très bas — dénutrition possible")
        case 16..<18.5:
            (statut, conseil) = (.insuffisant, "IMC faible — insuffisance pondérale")
        case 18.5..<25:
            (statut, conseil) = (.optimal, "IMC normal — poids santé ✓")
        case 25..<30:
            (statut, conseil) = (.attention, "IMC élevé — surpoids modéré")
        default:
            (statut, conseil) = (.exces, "IMC très élevé — risque santé accru")
        }
        return AnalyseZone(zone: .imc, statut: statut,
                           valeurAffichee: String(format: "%.1f", bmi), conseil: conseil)
    }

    // MARK: - Masse grasse

    private static func analyserMasseGrasse(mg: Double, estHomme: Bool) -> AnalyseZone {
        let (statut, conseil): (StatutZone, String)
        if estHomme {
            switch mg {
            case ..<6:    (statut, conseil) = (.insuffisant, "Taux très bas — risque hormonal")
            case 6..<20:  (statut, conseil) = (.optimal,     "Taux dans la plage saine ✓")
            case 20..<25: (statut, conseil) = (.attention,   "Taux légèrement élevé")
            default:      (statut, conseil) = (.exces,       "Taux excessif — adiposité")
            }
        } else {
            switch mg {
            case ..<14:   (statut, conseil) = (.insuffisant, "Taux très bas — risque hormonal")
            case 14..<28: (statut, conseil) = (.optimal,     "Taux dans la plage saine ✓")
            case 28..<33: (statut, conseil) = (.attention,   "Taux légèrement élevé")
            default:      (statut, conseil) = (.exces,       "Taux excessif — adiposité")
            }
        }
        return AnalyseZone(zone: .masseGrasse, statut: statut,
                           valeurAffichee: String(format: "%.1f%%", mg), conseil: conseil)
    }

    // MARK: - Tour de taille (WHtR)

    private static func analyserTaille(waist: Double, height: Double) -> AnalyseZone {
        let whtr = waist / height
        let (statut, conseil): (StatutZone, String)
        switch whtr {
        case ..<0.40:
            (statut, conseil) = (.insuffisant, String(format: "WHtR %.2f — taille très fine", whtr))
        case 0.40..<0.50:
            (statut, conseil) = (.optimal,     String(format: "WHtR %.2f — proportion idéale ✓", whtr))
        case 0.50..<0.55:
            (statut, conseil) = (.attention,   String(format: "WHtR %.2f — légèrement élevé", whtr))
        default:
            (statut, conseil) = (.exces,       String(format: "WHtR %.2f — risque métabolique", whtr))
        }
        return AnalyseZone(zone: .taille, statut: statut,
                           valeurAffichee: String(format: "%.0f cm", waist), conseil: conseil)
    }

    // MARK: - Hanches (WHR ou ratio/taille)

    private static func analyserHanchesWHR(hips: Double, waist: Double, estHomme: Bool) -> AnalyseZone {
        let whr = waist / hips
        let (statut, conseil): (StatutZone, String)
        if estHomme {
            switch whr {
            case ..<0.85:
                (statut, conseil) = (.optimal,   String(format: "WHR %.2f — silhouette saine ✓", whr))
            case 0.85..<0.95:
                (statut, conseil) = (.attention, String(format: "WHR %.2f — légèrement élevé", whr))
            default:
                (statut, conseil) = (.exces,     String(format: "WHR %.2f — risque cardiovasculaire", whr))
            }
        } else {
            switch whr {
            case ..<0.80:
                (statut, conseil) = (.optimal,   String(format: "WHR %.2f — silhouette saine ✓", whr))
            case 0.80..<0.86:
                (statut, conseil) = (.attention, String(format: "WHR %.2f — légèrement élevé", whr))
            default:
                (statut, conseil) = (.exces,     String(format: "WHR %.2f — risque cardiovasculaire", whr))
            }
        }
        return AnalyseZone(zone: .hanches, statut: statut,
                           valeurAffichee: String(format: "%.0f cm", hips), conseil: conseil)
    }

    private static func analyserHanchesRatio(hips: Double, height: Double, estHomme: Bool) -> AnalyseZone {
        let ratio = hips / height
        let (lo, hi): (Double, Double) = estHomme ? (0.52, 0.62) : (0.54, 0.68)
        let statut: StatutZone
        let conseil: String
        if ratio < lo - 0.03 {
            statut = .insuffisant; conseil = "Hanches étroites"
        } else if ratio < lo {
            statut = .attention;   conseil = "Hanches légèrement étroites"
        } else if ratio < hi {
            statut = .optimal;     conseil = "Hanches proportionnées ✓"
        } else if ratio < hi + 0.06 {
            statut = .attention;   conseil = "Hanches légèrement larges"
        } else {
            statut = .exces;       conseil = "Hanches très larges"
        }
        return AnalyseZone(zone: .hanches, statut: statut,
                           valeurAffichee: String(format: "%.0f cm", hips), conseil: conseil)
    }

    // MARK: - Poitrine

    private static func analyserPoitrine(chest: Double, height: Double, estHomme: Bool) -> AnalyseZone {
        let ratio = chest / height
        let (lo, hi): (Double, Double) = estHomme ? (0.50, 0.60) : (0.46, 0.58)
        let statut: StatutZone
        let conseil: String
        if ratio < lo - 0.04 {
            statut = .insuffisant; conseil = "Poitrine étroite pour la taille"
        } else if ratio < lo {
            statut = .attention;   conseil = "Poitrine légèrement étroite"
        } else if ratio < hi {
            statut = .optimal;     conseil = "Poitrine bien proportionnée ✓"
        } else if ratio < hi + 0.06 {
            statut = .attention;   conseil = "Poitrine légèrement forte"
        } else {
            statut = .exces;       conseil = "Poitrine très forte"
        }
        return AnalyseZone(zone: .poitrine, statut: statut,
                           valeurAffichee: String(format: "%.0f cm", chest), conseil: conseil)
    }

    // MARK: - Bras

    private static func analyserBras(arm: Double, height: Double, estHomme: Bool) -> AnalyseZone {
        let ratio = arm / height
        let (lo, hi): (Double, Double) = estHomme ? (0.17, 0.22) : (0.15, 0.20)
        let statut: StatutZone
        let conseil: String
        if ratio < lo - 0.02 {
            statut = .insuffisant; conseil = "Bras très fins — manque de muscle"
        } else if ratio < lo {
            statut = .attention;   conseil = "Bras légèrement fins"
        } else if ratio < hi {
            statut = .optimal;     conseil = "Bras bien proportionnés ✓"
        } else if ratio < hi + 0.03 {
            statut = .attention;   conseil = "Bras légèrement épais"
        } else {
            statut = .exces;       conseil = "Bras très épais"
        }
        return AnalyseZone(zone: .bras, statut: statut,
                           valeurAffichee: String(format: "%.0f cm", arm), conseil: conseil)
    }

    // MARK: - Cuisse

    private static func analyserCuisse(thigh: Double, height: Double, estHomme: Bool) -> AnalyseZone {
        let ratio = thigh / height
        let (lo, hi): (Double, Double) = estHomme ? (0.28, 0.35) : (0.30, 0.40)
        let statut: StatutZone
        let conseil: String
        if ratio < lo - 0.03 {
            statut = .insuffisant; conseil = "Cuisses fines — manque de masse"
        } else if ratio < lo {
            statut = .attention;   conseil = "Cuisses légèrement fines"
        } else if ratio < hi {
            statut = .optimal;     conseil = "Cuisses bien proportionnées ✓"
        } else if ratio < hi + 0.05 {
            statut = .attention;   conseil = "Cuisses légèrement fortes"
        } else {
            statut = .exces;       conseil = "Cuisses très fortes"
        }
        return AnalyseZone(zone: .cuisse, statut: statut,
                           valeurAffichee: String(format: "%.0f cm", thigh), conseil: conseil)
    }
}
