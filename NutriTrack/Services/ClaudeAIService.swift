import Foundation

// MARK: - Modèles de l'API Claude

struct ClaudeMessage: Identifiable, Codable {
    var id: UUID = UUID()
    var role: String    // "user" ou "assistant"
    var content: String
    var timestamp: Date = Date()

    var isUser: Bool { role == "user" }
}

private struct ClaudeRequest: Encodable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [ClaudeRequestMessage]
}

private struct ClaudeRequestMessage: Encodable {
    let role: String
    let content: String
}

private struct ClaudeResponse: Decodable {
    let content: [ClaudeContent]
    let usage: ClaudeUsage?
}

private struct ClaudeContent: Decodable {
    let type: String
    let text: String?
}

private struct ClaudeUsage: Decodable {
    let input_tokens: Int
    let output_tokens: Int
}

// MARK: - Contexte nutritionnel envoyé à Claude

struct ContexteNutritionnel {
    let prenom: String
    let objectifCalorique: Double
    let objectifProteines: Double
    let objectifGlucides: Double
    let objectifLipides: Double
    let resumeSemaine: String   // résumé textuel des 7 derniers jours
    let tendancePoids: String   // évolution du poids
    let dernierPoids: Double

    var systemPrompt: String {
        """
        Tu es NutriCoach, un coach nutritionnel expert et bienveillant intégré dans l'application NutriTrack. \
        Tu t'exprimes uniquement en français, avec un ton encourageant et professionnel.

        Voici les informations sur l'utilisateur \(prenom.isEmpty ? "" : "(\(prenom))") :

        OBJECTIFS JOURNALIERS :
        - Calories : \(objectifCalorique.arrondi(0)) kcal
        - Protéines : \(objectifProteines.arrondi(0)) g
        - Glucides : \(objectifGlucides.arrondi(0)) g
        - Lipides : \(objectifLipides.arrondi(0)) g

        BILAN DES 7 DERNIERS JOURS :
        \(resumeSemaine)

        ÉVOLUTION DU POIDS : \(tendancePoids)
        DERNIER POIDS ENREGISTRÉ : \(dernierPoids > 0 ? "\(dernierPoids.kg)" : "Non renseigné")

        Tes missions :
        1. Analyser les données nutritionnelles et donner des conseils personnalisés
        2. Proposer des suggestions de repas équilibrés selon les objectifs
        3. Expliquer les concepts nutritionnels de façon simple et accessible
        4. Motiver et encourager sans jamais culpabiliser
        5. Détecter les carences ou excès récurrents et proposer des corrections

        IMPORTANT : Ne fournis jamais de conseils médicaux. Toujours recommander de consulter un professionnel de santé pour des problèmes spécifiques.
        """
    }
}

// MARK: - Service Claude AI

@Observable
class ClaudeAIService {

    var isLoading = false
    var errorMessage: String?

    private let session = URLSession.shared

    // MARK: - Envoi d'un message

    func envoyerMessage(
        messages: [ClaudeMessage],
        contexte: ContexteNutritionnel,
        apiKey: String
    ) async -> String? {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Clé API Claude manquante. Veuillez la saisir dans votre profil."
            return nil
        }

        guard let url = URL(string: APIConstants.claudeAPIEndpoint) else { return nil }

        let requestMessages = messages.map {
            ClaudeRequestMessage(role: $0.role, content: $0.content)
        }

        let request_body = ClaudeRequest(
            model: APIConstants.claudeModel,
            max_tokens: 1024,
            system: contexte.systemPrompt,
            messages: requestMessages
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(APIConstants.claudeVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        do {
            request.httpBody = try JSONEncoder().encode(request_body)
        } catch {
            errorMessage = "Erreur de préparation de la requête."
            return nil
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Réponse invalide du serveur."
                return nil
            }

            guard httpResponse.statusCode == 200 else {
                switch httpResponse.statusCode {
                case 401: errorMessage = "Clé API invalide. Vérifiez votre clé dans le profil."
                case 429: errorMessage = "Limite de requêtes atteinte. Veuillez patienter."
                case 500...: errorMessage = "Erreur serveur Claude. Réessayez dans quelques instants."
                default: errorMessage = "Erreur HTTP \(httpResponse.statusCode)."
                }
                return nil
            }

            let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            let texte = claudeResponse.content
                .filter { $0.type == "text" }
                .compactMap { $0.text }
                .joined(separator: "\n")

            return texte.isEmpty ? nil : texte
        } catch {
            errorMessage = "Erreur réseau : veuillez vérifier votre connexion internet."
            return nil
        }
    }

    // MARK: - Analyse proactive (ouverture du coach)

    func analyseProactive(contexte: ContexteNutritionnel, apiKey: String) async -> String? {
        let messageOuverture = ClaudeMessage(
            role: "user",
            content: "Bonjour ! Peux-tu analyser mon alimentation de la semaine et me donner tes conseils personnalisés ?"
        )
        return await envoyerMessage(messages: [messageOuverture], contexte: contexte, apiKey: apiKey)
    }

    // MARK: - Génération plan de repas

    func genererPlanRepas(contexte: ContexteNutritionnel, apiKey: String) async -> String? {
        let demande = ClaudeMessage(
            role: "user",
            content: """
            Génère-moi un plan de repas équilibré pour 7 jours (lundi à dimanche). \
            Pour chaque jour, propose : petit-déjeuner, déjeuner, dîner et une collation. \
            Respecte mes objectifs caloriques (\(contexte.objectifCalorique.arrondi(0)) kcal/jour) \
            et mes macros. Format : tableau Jour / Repas / Plat principal / Calories estimées.
            """
        )
        return await envoyerMessage(messages: [demande], contexte: contexte, apiKey: apiKey)
    }

    // MARK: - Conseil du jour (court)

    func conseilDuJour(contexte: ContexteNutritionnel, apiKey: String) async -> String? {
        let demande = ClaudeMessage(
            role: "user",
            content: "Donne-moi un conseil nutritionnel court et actionnable pour aujourd'hui, en 2-3 phrases maximum."
        )
        return await envoyerMessage(messages: [demande], contexte: contexte, apiKey: apiKey)
    }

    // MARK: - Génération du plan complet (v2)

    func genererPlanComplet(profil: UserProfile, apiKey: String) async -> PlanCompletResponse? {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Clé API Claude manquante."
            return nil
        }
        guard let url = URL(string: APIConstants.claudeAPIEndpoint) else { return nil }

        // ── Calculs nutritionnels ancrés via NutritionCalculator (source unique de vérité) ──

        let objectifsCalc = NutritionCalculator.objectifsCaloriques(profil: profil)
        let macrosCalc    = NutritionCalculator.macrosCiblesTransformation(
            calories:   objectifsCalc.objectifTransformation,
            poidsKg:    profil.poidsActuel,
            ajustement: objectifsCalc.ajustement
        )

        let tdee           = objectifsCalc.tdee
        let bmr            = NutritionCalculator.bmr(
            poids: profil.poidsActuel, taille: profil.taille,
            age: profil.age, sexe: profil.sexe
        )
        let seuilMin       = profil.sexe == "homme" ? 1_500.0 : 1_200.0
        let adjustKcal     = objectifsCalc.ajustement
        let caloriesCibles = objectifsCalc.objectifTransformation
        let semaines       = objectifsCalc.semainesRestantes
        let kgEstimes      = objectifsCalc.kgEstimes

        let typeTransfo: String
        switch objectifsCalc.typeTransformation {
        case "déficit":  typeTransfo = "perte de masse grasse (silhouette plus mince/fine)"
        case "surplus":  typeTransfo = "prise de poids / remise en forme (aller vers un poids santé)"
        default:         typeTransfo = "recomposition corporelle / maintien"
        }

        let proteinesG = macrosCalc.proteines
        let glucidesG  = macrosCalc.glucides
        let lipidesG   = macrosCalc.lipides

        let silhouetteActuelleLabel = SilhouetteObjectif(rawValue: profil.silhouetteActuelle)?
            .label(sexe: profil.sexeEnum) ?? "Non définie"
        let silhouetteCibleLabel = SilhouetteObjectif(rawValue: profil.silhouetteObjectif)?
            .label(sexe: profil.sexeEnum) ?? "Non définie"

        // ── Planning d'entraînement calculé selon la fréquence ───────────────────────
        let tousDLesJours = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
        let freq = min(profil.frequenceEntrainementJours, 6)

        // Distribue les séances le plus uniformément possible sur la semaine
        let joursActifsIndices: [Int] = {
            switch freq {
            case 1: return [0]
            case 2: return [0, 3]
            case 3: return [0, 2, 4]
            case 4: return [0, 1, 3, 4]
            case 5: return [0, 1, 2, 4, 5]
            case 6: return [0, 1, 2, 3, 4, 5]
            default: return []
            }
        }()

        let planningJours = tousDLesJours.enumerated().map { idx, jour -> String in
            joursActifsIndices.contains(idx) ? "\(jour): Entraînement" : "\(jour): Repos"
        }.joined(separator: "\n        ")

        // Paramètres selon niveau
        let paramsNiveau: String
        switch profil.niveauSportEnum {
        case .debutant:
            paramsNiveau = "2-3 séries × 12-15 répétitions — repos 75-90s entre séries"
        case .intermediaire:
            paramsNiveau = "3-4 séries × 8-12 répétitions — repos 60-75s entre séries"
        case .avance:
            paramsNiveau = "4-5 séries × 6-10 répétitions — repos 45-60s entre séries"
        }

        // Exercices autorisés selon équipement
        let exercicesEquipement: String
        switch profil.equipementEnum {
        case .poidsCorps:
            exercicesEquipement = "Pompes (variations), Tractions, Dips, Squat bulgare, Fentes, Gainage, Planche, Burpees, Mountain climbers, Relevés de jambes"
        case .halteres:
            exercicesEquipement = "Développé haltères, Rowing haltères, Curl biceps, Extension triceps, Squat goblet, Fentes haltères, Soulevé de terre haltères, Élévations latérales, Shoulder press haltères"
        case .salle:
            exercicesEquipement = "Développé couché, Squat barre, Soulevé de terre, Tractions lestées, Rowing barre, Presse à cuisses, Leg curl, Leg extension, Tirage poulie, Dips lestés, Machine guidée, Cable"
        case .exterieur:
            exercicesEquipement = "Course, Sprint, Marche rapide, Pompes, Tractions (barre fixe), Dips (banc), Squat, Fentes, Jump squat, Gainage, Hill sprints"
        case .mix:
            exercicesEquipement = "Exercices poids du corps + haltères + machines salle selon disponibilité — varier les modalités"
        }

        // Types de séances adaptés aux sports appréciés
        let sportsLabel = profil.sportsAprecies.isEmpty ? "Non spécifié" : profil.sportsAprecies.joined(separator: ", ")

        // ── Répartition des repas proportionnelle aux calories cibles ──────────────────
        let calPJ  = Int((caloriesCibles * 0.22).rounded())   // 22% petit-déjeuner
        let calDej = Int((caloriesCibles * 0.35).rounded())   // 35% déjeuner
        let calDin = Int((caloriesCibles * 0.30).rounded())   // 30% dîner
        let calCol = Int(caloriesCibles) - calPJ - calDej - calDin  // solde → collation

        // ── Prompt ──────────────────────────────────────────────────────────────────────

        let systemPrompt = """
        Tu es NutriCoach Expert, coach de transformation physique et nutritionniste certifié.
        Tu t'exprimes uniquement en français avec un ton professionnel et bienveillant.
        Tu réponds TOUJOURS avec du JSON valide et rien d'autre — sans introduction ni commentaire.
        Ne fournis jamais de conseils médicaux. Recommande de consulter un professionnel de santé si besoin.
        """

        let userMessage = """
        Crée un plan de transformation complet et détaillé pour cet utilisateur.

        PROFIL :
        - Prénom : \(profil.prenom)
        - Âge : \(profil.age) ans | Sexe : \(profil.sexeEnum.label)
        - Taille : \(profil.taille.arrondi(0)) cm | Poids actuel : \(profil.poidsActuel.arrondi(1)) kg\(profil.masseGraisseuse > 0 ? " | Masse graisseuse : \(profil.masseGraisseuse.arrondi(1)) %" : "")
        - Silhouette actuelle : \(silhouetteActuelleLabel) → Objectif : \(silhouetteCibleLabel)
        - Délai : \(semaines) semaines

        SPORT :
        - Niveau : \(profil.niveauSportEnum.label)
        - Équipement disponible : \(profil.equipementEnum.label)
        - Séances souhaitées : \(freq)/semaine, \(profil.dureeSeanceMinutes) min chacune
        - Sports pratiqués / appréciés : \(sportsLabel)

        NUTRITION :
        - Régime : \(profil.regimeEnum.label)
        - Allergies : \(profil.allergies.isEmpty ? "Aucune" : profil.allergies.joined(separator: ", "))
        - Repas par jour : \(profil.nbRepasJour)
        - Aliments appréciés : \(profil.alimentsAimes.isEmpty ? "Non spécifié" : profil.alimentsAimes)
        - Aliments à éviter : \(profil.alimentsDetestes.isEmpty ? "Non spécifié" : profil.alimentsDetestes)

        HABITUDES DE VIE :
        - Sommeil : qualité \(profil.qualiteSommeil)/5, durée \(profil.dureeSommeilHeures.arrondi(1))h
        - Stress : \(profil.niveauStress)/5 | Type de journée : \(profil.niveauActiviteEnum.label)
        - Alcool : \(profil.alcoolEnum.label) | Tabac : \(profil.tabac ? "Oui" : "Non")
        - Hydratation habituelle : \(profil.hydratationHabituelleLitres.arrondi(1)) L/j

        ══════════ CONTRAINTES NUTRITIONNELLES CALCULÉES — OBLIGATOIRES ══════════
        Type de transformation  : \(typeTransfo)
        TDEE (dépense totale)   : \(Int(tdee)) kcal/j
        BMR (métabolisme base)  : \(Int(bmr)) kcal/j
        Transformation visée    : ~\(kgEstimes.arrondi(1)) kg en \(semaines) semaines
        Ajustement calorique    : \(adjustKcal >= 0 ? "+" : "")\(Int(adjustKcal)) kcal/j (\(typeTransfo))

        ▶▶ CALORIES JOURNALIÈRES : \(Int(caloriesCibles)) kcal  ← VALEUR EXACTE, NE PAS MODIFIER
        ▶▶ PROTÉINES : \(Int(proteinesG)) g  (\(adjustKcal < 0 ? "2,0 g/kg — préservation musculaire" : "1,8 g/kg"))
        ▶▶ LIPIDES   : \(Int(lipidesG)) g  (~\(Int((lipidesG * 9.0 / caloriesCibles * 100).rounded()))% des kcal)
        ▶▶ GLUCIDES  : \(Int(glucidesG)) g  (solde énergétique)
        ▶▶ Seuil sécurité       : \(Int(seuilMin)) kcal/j minimum absolu
        Vérification : \(Int(proteinesG))×4 + \(Int(glucidesG))×4 + \(Int(lipidesG))×9 = ~\(Int(proteinesG * 4 + glucidesG * 4 + lipidesG * 9)) kcal

        RÉPARTITION DES REPAS (proportionnelle, OBLIGATOIRE) :
        ▶▶ Petit-déjeuner : \(calPJ) kcal
        ▶▶ Déjeuner       : \(calDej) kcal
        ▶▶ Dîner          : \(calDin) kcal
        ▶▶ Collation      : \(calCol) kcal
        ▶▶ Total vérifié  : \(calPJ + calDej + calDin + calCol) kcal
        ═════════════════════════════════════════════════════════════════════════

        ══════════ PROGRAMME D'ENTRAÎNEMENT — CONTRAINTES OBLIGATOIRES ══════════
        Niveau sportif    : \(profil.niveauSportEnum.label)
        Équipement        : \(profil.equipementEnum.label)
        Durée séance      : \(profil.dureeSeanceMinutes) minutes

        ▶▶ PARAMÈTRES SÉRIES/REPS/REPOS pour ce niveau :
           \(paramsNiveau)

        ▶▶ EXERCICES AUTORISÉS (équipement : \(profil.equipementEnum.label)) :
           \(exercicesEquipement)
           → N'utilise QUE ces exercices ou des variantes compatibles avec cet équipement.

        ▶▶ RÉPARTITION DES 7 JOURS (\(freq) séances actives, \(7 - freq) jours de repos) :
           \(planningJours)

        ▶▶ TYPES DE SÉANCES à alterner selon les jours actifs :\(sportsLabel == "Non spécifié" ? "" : "\n           ⚠️ SPORTS OBLIGATOIRES : l'utilisateur pratique/apprécie — \(sportsLabel)\n              → Au moins 1 séance par semaine DOIT être basée sur ces sports (séance dédiée, cardio ou échauffement actif).\n              → Nommer explicitement ces sports dans le typeSeance et les exercices des jours concernés.")
           - Orientation : \(adjustKcal < 0 ? "Cardio + Force léger (déficit calorique actif)" : adjustKcal > 0 ? "Force lourde + Volume (prise de masse)" : "Force + Cardio équilibrés (maintien)")
           - Inclure au moins 1 séance mobilité/étirements si freq ≥ 4
        ═════════════════════════════════════════════════════════════════════════

        Réponds UNIQUEMENT avec ce JSON, sans aucun texte avant ou après :

        {
          "critique": "analyse personnalisée du profil (3-5 phrases)",
          "niveauFaisabilite": "realiste",
          "alternativeSuggeree": "",
          "recommandationsVie": "3-4 recommandations sur sommeil, stress, hydratation, récupération",
          "planNutrition": {
            "caloriesJournalieres": \(Int(caloriesCibles)),
            "proteinesG": \(Int(proteinesG)),
            "glucidesG": \(Int(glucidesG)),
            "lipidesG": \(Int(lipidesG)),
            "recommandations": ["conseil nutrition 1", "conseil nutrition 2", "conseil nutrition 3"],
            "repasTypes": [
              {"id": "pj", "nom": "Petit-déjeuner", "caloriesCibles": \(calPJ), "suggestions": ["Option A", "Option B"]},
              {"id": "dej", "nom": "Déjeuner", "caloriesCibles": \(calDej), "suggestions": ["Option A", "Option B"]},
              {"id": "din", "nom": "Dîner", "caloriesCibles": \(calDin), "suggestions": ["Option A", "Option B"]},
              {"id": "col", "nom": "Collation", "caloriesCibles": \(calCol), "suggestions": ["Option A", "Option B"]}
            ]
          },
          "planEntrainement": {
            "semaineType": [
              {"id": "j1", "jourLabel": "Lundi", "typeSeance": "Force", "exercices": [
                {"id": "e1", "nom": "Nom exercice", "series": 3, "repetitions": "10-12", "reposSecondes": 60, "musclesCibles": ["Muscle principal"], "notes": null}
              ], "dureeMinutes": 60, "seanceFaite": false, "dateFaite": null}
            ],
            "recommandations": ["conseil entraînement 1", "conseil entraînement 2"],
            "noteGenerale": "note globale sur le programme"
          }
        }

        CONTRAINTES IMPÉRATIVES :
        - niveauFaisabilite = exactement "realiste", "ambitieux" ou "dangereux"
        - caloriesJournalieres, proteinesG, glucidesG, lipidesG = exactement les valeurs indiquées ci-dessus
        - Les caloriesCibles de chaque repasType = exactement les valeurs indiquées ci-dessus (PJ/Dej/Din/Col)
        - semaineType = exactement 7 jours (Lundi→Dimanche) dans cet ordre
        - Les jours actifs sont exactement : \(joursActifsIndices.map { tousDLesJours[$0] }.joined(separator: ", "))
        - Les jours de repos : typeSeance = "Repos", exercices = [], dureeMinutes = 0
        - Chaque séance ACTIVE : 4-6 exercices UNIQUEMENT compatibles avec "\(profil.equipementEnum.label)"
        - Séries, répétitions et temps de repos : \(paramsNiveau)
        - dureeMinutes de chaque séance active = \(profil.dureeSeanceMinutes)
        - Les ids des jours = "j1" à "j7", ids des exercices = "e1", "e2"... (uniques par jour)
        """

        // ── Variables capturées pour post-validation ──────────────────────────────────
        let anchorCalories  = caloriesCibles
        let anchorProteines = proteinesG
        let anchorGlucides  = glucidesG
        let anchorLipides   = lipidesG

        let requestBody = ClaudeRequest(
            model: APIConstants.claudeModel,
            max_tokens: 4096,
            system: systemPrompt,
            messages: [ClaudeRequestMessage(role: "user", content: userMessage)]
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(APIConstants.claudeVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        do { request.httpBody = try JSONEncoder().encode(requestBody) } catch { return nil }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                if let http = response as? HTTPURLResponse {
                    switch http.statusCode {
                    case 401: errorMessage = "Clé API invalide."
                    case 429: errorMessage = "Limite de requêtes atteinte."
                    default:  errorMessage = "Erreur HTTP \(http.statusCode)."
                    }
                }
                return nil
            }

            let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            let texte = claudeResponse.content
                .filter { $0.type == "text" }
                .compactMap { $0.text }
                .joined()

            guard var plan = extraireEtDecoder(PlanCompletResponse.self, depuis: texte) else {
                return nil
            }

            // ── Post-validation : si Claude a dévié de plus de 10%, on réancre ──────
            let deviance = abs(plan.planNutrition.caloriesJournalieres - anchorCalories) / anchorCalories
            if deviance > 0.10 {
                plan.planNutrition.caloriesJournalieres = anchorCalories
                plan.planNutrition.proteinesG           = anchorProteines
                plan.planNutrition.glucidesG            = anchorGlucides
                plan.planNutrition.lipidesG             = anchorLipides

                // Redistribuer les calories des repas proportionnellement
                let totalRepas = plan.planNutrition.repasTypes.reduce(0.0) { $0 + $1.caloriesCibles }
                if totalRepas > 0 {
                    plan.planNutrition.repasTypes = plan.planNutrition.repasTypes.map { repas in
                        var r = repas
                        r.caloriesCibles = (repas.caloriesCibles / totalRepas * anchorCalories).rounded()
                        return r
                    }
                }
            }

            return plan
        } catch {
            errorMessage = "Erreur réseau."
            return nil
        }
    }

    // MARK: - Extraction JSON depuis texte Claude

    private func extraireEtDecoder<T: Decodable>(_ type: T.Type, depuis texte: String) -> T? {
        // 1. Texte brut
        if let data = texte.data(using: .utf8), let r = try? JSONDecoder().decode(type, from: data) { return r }

        // 2. Enlever les blocs markdown ```json ... ```
        let nettoye = texte
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = nettoye.data(using: .utf8), let r = try? JSONDecoder().decode(type, from: data) { return r }

        // 3. Trouver le premier { et décoder depuis là
        if let start = nettoye.firstIndex(of: "{"),
           let data = String(nettoye[start...]).data(using: .utf8),
           let r = try? JSONDecoder().decode(type, from: data) { return r }

        errorMessage = "Impossible d'analyser la réponse du plan."
        return nil
    }
}

// MARK: - Réponse plan complet (Codable)

struct PlanCompletResponse: Codable {
    var critique: String
    var niveauFaisabilite: String
    var alternativeSuggeree: String
    var recommandationsVie: String
    var planNutrition: PlanNutritionnel
    var planEntrainement: PlanEntrainement
}
