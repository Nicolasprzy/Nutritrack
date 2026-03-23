import Foundation
import SwiftData
import Observation

@Observable
class AICoachViewModel {

    var messages: [ClaudeMessage] = []
    var messageEnCours: String = ""
    var isTyping: Bool = false
    var hasLoadedContext = false

    let service = ClaudeAIService()

    private var contexteCache: ContexteNutritionnel?

    // MARK: - Initialisation avec contexte

    func initialiser(profil: UserProfile, context: ModelContext) async {
        guard !hasLoadedContext else { return }
        guard profil.aUneCleAPI else { return }

        hasLoadedContext = true
        let contexte = construireContexte(profil: profil, context: context)
        contexteCache = contexte

        isTyping = true

        let analyse = await service.analyseProactive(contexte: contexte, apiKey: profil.claudeAPIKey)
        isTyping = false

        if let texte = analyse {
            let msg = ClaudeMessage(role: "assistant", content: texte)
            messages.append(msg)
        } else if let erreur = service.errorMessage {
            let msg = ClaudeMessage(role: "assistant", content: "⚠️ \(erreur)")
            messages.append(msg)
        }
    }

    // MARK: - Envoi d'un message

    func envoyerMessage(profil: UserProfile, context: ModelContext) async {
        let texte = messageEnCours.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texte.isEmpty else { return }
        guard profil.aUneCleAPI else { return }

        let msgUser = ClaudeMessage(role: "user", content: texte)
        messages.append(msgUser)
        messageEnCours = ""

        if contexteCache == nil {
            contexteCache = construireContexte(profil: profil, context: context)
        }

        isTyping = true

        let reponse = await service.envoyerMessage(
            messages: messages.filter { $0.role == "user" || $0.role == "assistant" },
            contexte: contexteCache!,
            apiKey: profil.claudeAPIKey
        )

        isTyping = false

        if let texteReponse = reponse {
            let msgAssistant = ClaudeMessage(role: "assistant", content: texteReponse)
            messages.append(msgAssistant)
        } else if let erreur = service.errorMessage {
            let msgErreur = ClaudeMessage(role: "assistant", content: "⚠️ \(erreur)")
            messages.append(msgErreur)
        }
    }

    // MARK: - Questions suggérées

    let questionsSuggerees = [
        "Analyse ma semaine",
        "Optimise mes macros",
        "Idées repas demain",
        "Suis-je en déficit ?",
        "Comment augmenter mes protéines ?",
        "Que manger avant l'entraînement ?"
    ]

    func poserQuestion(_ question: String, profil: UserProfile, context: ModelContext) async {
        messageEnCours = question
        await envoyerMessage(profil: profil, context: context)
    }

    // MARK: - Contexte nutritionnel

    private func construireContexte(profil: UserProfile, context: ModelContext) -> ContexteNutritionnel {
        var resumeJours: [String] = []
        for i in 0..<7 {
            guard let jour = Calendar.current.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let debut = jour.debutDeJour
            let fin   = jour.finDeJour
            let descriptor = FetchDescriptor<FoodEntry>(
                predicate: #Predicate<FoodEntry> { $0.date >= debut && $0.date <= fin }
            )
            let entries = (try? context.fetch(descriptor)) ?? []
            let cal  = entries.reduce(0) { $0 + $1.calories }
            let prot = entries.reduce(0) { $0 + $1.proteins }
            let gluc = entries.reduce(0) { $0 + $1.carbohydrates }
            let lip  = entries.reduce(0) { $0 + $1.fats }

            if cal > 0 {
                resumeJours.append(
                    "\(jour.formatLong) : \(cal.arrondi(0)) kcal (P:\(prot.arrondi(0))g G:\(gluc.arrondi(0))g L:\(lip.arrondi(0))g)"
                )
            }
        }

        let metricsDesc = FetchDescriptor<BodyMetric>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let metrics = (try? context.fetch(metricsDesc)) ?? []
        let dernierPoids = metrics.first?.weight ?? 0
        let tendance: String
        if metrics.count >= 2 {
            let diff = metrics[0].weight - metrics[metrics.count - 1].weight
            tendance = diff > 0 ? "Prise de \(diff.arrondi(1)) kg sur la période" : "Perte de \(abs(diff).arrondi(1)) kg sur la période"
        } else {
            tendance = "Données insuffisantes"
        }

        return ContexteNutritionnel(
            prenom:            profil.prenom,
            objectifCalorique: profil.objectifCalorique,
            objectifProteines: profil.objectifProteines,
            objectifGlucides:  profil.objectifGlucides,
            objectifLipides:   profil.objectifLipides,
            resumeSemaine:     resumeJours.isEmpty ? "Aucun repas enregistré cette semaine." : resumeJours.joined(separator: "\n"),
            tendancePoids:     tendance,
            dernierPoids:      dernierPoids
        )
    }

    func effacerConversation() {
        messages = []
        hasLoadedContext = false
        contexteCache = nil
    }
}
