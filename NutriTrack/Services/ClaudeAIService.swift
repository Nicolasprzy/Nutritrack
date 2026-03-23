import Foundation

// MARK: - Modèles de l'API Claude

struct ClaudeMessage: Identifiable {
    let id = UUID()
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
}
