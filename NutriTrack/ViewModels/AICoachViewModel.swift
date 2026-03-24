import Foundation
import SwiftData
import Observation

@Observable
class AICoachViewModel {

    var messages: [ClaudeMessage] = []
    var messageEnCours: String = ""
    var isTyping: Bool = false
    var estInitialise: Bool = false

    let service = ClaudeAIService()
    private var contexteCache: ContexteNutritionnel?

    // MARK: - Chargement de l'historique persisté

    func chargerHistorique(profil: UserProfile) {
        guard !estInitialise else { return }
        estInitialise = true

        let json = profil.aiHistoriqueJSON
        guard !json.isEmpty,
              let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([ClaudeMessage].self, from: data)
        else { return }

        messages = decoded
    }

    private func sauvegarderHistorique(profil: UserProfile, context: ModelContext) {
        guard let data = try? JSONEncoder().encode(messages),
              let json = String(data: data, encoding: .utf8)
        else { return }
        profil.aiHistoriqueJSON = json
        try? context.save()
    }

    // MARK: - Analyse manuelle (déclenchée par l'utilisateur)

    func lancerAnalyse(profil: UserProfile, context: ModelContext) async {
        guard profil.aUneCleAPI else { return }

        contexteCache = construireContexte(profil: profil, context: context)
        isTyping = true

        let analyse = await service.analyseProactive(contexte: contexteCache!, apiKey: profil.claudeAPIKey)
        isTyping = false

        if let texte = analyse {
            messages.append(ClaudeMessage(role: "assistant", content: texte))
            sauvegarderHistorique(profil: profil, context: context)
        }
    }

    // MARK: - Envoi d'un message

    func envoyerMessage(profil: UserProfile, context: ModelContext) async {
        let texte = messageEnCours.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texte.isEmpty, profil.aUneCleAPI else { return }

        messages.append(ClaudeMessage(role: "user", content: texte))
        messageEnCours = ""

        if contexteCache == nil {
            contexteCache = construireContexte(profil: profil, context: context)
        }

        isTyping = true
        let reponse = await service.envoyerMessage(
            messages: messages,
            contexte: contexteCache!,
            apiKey: profil.claudeAPIKey
        )
        isTyping = false

        let contenu = reponse ?? "⚠️ \(service.errorMessage ?? "Erreur inconnue")"
        messages.append(ClaudeMessage(role: "assistant", content: contenu))
        sauvegarderHistorique(profil: profil, context: context)
    }

    func poserQuestion(_ question: String, profil: UserProfile, context: ModelContext) async {
        messageEnCours = question
        await envoyerMessage(profil: profil, context: context)
    }

    // MARK: - Effacer la conversation

    func effacerConversation(profil: UserProfile, context: ModelContext) {
        messages = []
        contexteCache = nil
        profil.aiHistoriqueJSON = ""
        try? context.save()
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
            let cal  = entries.reduce(0.0) { $0 + $1.calories }
            let prot = entries.reduce(0.0) { $0 + $1.proteins }
            let gluc = entries.reduce(0.0) { $0 + $1.carbohydrates }
            let lip  = entries.reduce(0.0) { $0 + $1.fats }
            if cal > 0 {
                resumeJours.append("\(jour.formatLong) : \(cal.arrondi(0)) kcal (P:\(prot.arrondi(0))g G:\(gluc.arrondi(0))g L:\(lip.arrondi(0))g)")
            }
        }

        let metricsDesc = FetchDescriptor<BodyMetric>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let metrics = (try? context.fetch(metricsDesc)) ?? []
        let dernierPoids = metrics.first?.weight ?? 0
        let tendance: String
        if metrics.count >= 2 {
            let diff = metrics[0].weight - metrics[metrics.count - 1].weight
            tendance = diff > 0 ? "Prise de \(diff.arrondi(1)) kg" : "Perte de \(abs(diff).arrondi(1)) kg"
        } else {
            tendance = "Données insuffisantes"
        }

        let objTransfo = NutritionCalculator.objectifsCaloriques(profil: profil)
        let macTransfo = NutritionCalculator.macrosCiblesTransformation(
            calories:   objTransfo.objectifTransformation,
            poidsKg:    profil.poidsActuel,
            ajustement: objTransfo.ajustement,
            approche:   profil.approcheEnum
        )
        return ContexteNutritionnel(
            prenom:            profil.prenom,
            objectifCalorique: objTransfo.objectifTransformation,
            objectifProteines: macTransfo.proteines,
            objectifGlucides:  macTransfo.glucides,
            objectifLipides:   macTransfo.lipides,
            resumeSemaine:     resumeJours.isEmpty ? "Aucun repas enregistré cette semaine." : resumeJours.joined(separator: "\n"),
            tendancePoids:     tendance,
            dernierPoids:      dernierPoids
        )
    }
}
