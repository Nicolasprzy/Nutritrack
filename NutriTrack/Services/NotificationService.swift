import Foundation
import UserNotifications

// MARK: - NotificationService

@MainActor
struct NotificationService {

    static let shared = NotificationService()

    private let idReevaluation  = "nutritrack.reevaluation"
    private let idRappelRepas   = "nutritrack.repas"
    private let idRappelPoids   = "nutritrack.poids"

    // MARK: - Permission

    @discardableResult
    func demanderAutorisation() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    var estAutorise: Bool {
        get async {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            return settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Réévaluation du plan

    /// Planifie une notification de réévaluation à J+joursCount à 9h00
    func planifierReevaluation(dans joursCount: Int, prenom: String) {
        annulerReevaluation()
        guard joursCount > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Votre plan mérite une mise à jour 🔄"
        content.body  = "Bonjour \(prenom.isEmpty ? "" : prenom + " !") Vos progrès ont évolué — il est temps de réévaluer votre programme NutriTrack."
        content.sound = .default
        content.categoryIdentifier = "REEVALUATION"

        guard let dateNotif = Calendar.current.date(byAdding: .day, value: joursCount, to: Date()) else { return }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: dateNotif)
        comps.hour = 9
        comps.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: idReevaluation, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func annulerReevaluation() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [idReevaluation])
    }

    // MARK: - Rappel pesée hebdomadaire (optionnel)

    /// Rappel chaque semaine le lundi à 8h00
    func planifierRappelPesee(actif: Bool, prenom: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [idRappelPoids])
        guard actif else { return }

        let content = UNMutableNotificationContent()
        content.title = "Jour de pesée 📊"
        content.body  = "N'oubliez pas d'enregistrer votre poids dans Corps & Forme pour suivre vos progrès."
        content.sound = .default

        var comps = DateComponents()
        comps.weekday = 2   // Lundi
        comps.hour    = 8
        comps.minute  = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: idRappelPoids, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    // MARK: - Rappel repas midi (optionnel)

    func planifierRappelRepas(actif: Bool, heure: Int = 12) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [idRappelRepas])
        guard actif else { return }

        let content = UNMutableNotificationContent()
        content.title = "Avez-vous enregistré votre repas ? 🍽️"
        content.body  = "Pensez à noter votre déjeuner dans NutriTrack."
        content.sound = .default

        var comps = DateComponents()
        comps.hour   = heure
        comps.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: idRappelRepas, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    // MARK: - Annulation globale

    func annulerTout() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
